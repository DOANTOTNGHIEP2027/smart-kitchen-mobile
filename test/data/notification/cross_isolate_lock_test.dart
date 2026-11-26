import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/interceptors/error_mapping_interceptor.dart';
import 'package:smart_kitchen_mobile/data/notification/bg_files.dart';
import 'package:smart_kitchen_mobile/data/notification/cross_isolate_lock.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';

import '../../helpers/fake_http_adapter.dart';
import 'quick_action_test_support.dart';

/// FileLeaseLock + RefreshGate (inventory-management.md §20.3 Amendment #134
/// A5, A7, A10; Guard 19, 27).
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sk_lock_');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  File lockFile() =>
      File('${dir.path}${Platform.pathSeparator}${FileLeaseLock.fileName}');

  FileLeaseLock newLock({int Function()? currentPid}) => FileLeaseLock(
        directory: () async => dir,
        currentPid: currentPid,
        pollInterval: const Duration(milliseconds: 10),
      );

  void writeLease({required int pidValue, required DateTime at}) {
    lockFile().writeAsStringSync(jsonEncode(<String, Object>{
      'owner': 'someone-else',
      'pid': pidValue,
      'at': at.millisecondsSinceEpoch,
    }));
  }

  group('FileLeaseLock', () {
    test('2 tryAcquire đồng thời cùng isolate ⇒ đúng 1 bên thắng', () async {
      final a = newLock();
      final b = newLock();
      final results = await Future.wait(<Future<LockLease?>>[
        a.tryAcquire(wait: const Duration(milliseconds: 50)),
        b.tryAcquire(wait: const Duration(milliseconds: 50)),
      ]);
      expect(results.whereType<LockLease>(), hasLength(1));
      await results.whereType<LockLease>().single.release();
      expect(lockFile().existsSync(), isFalse);
    });

    test('2 isolate thật ⇒ không bao giờ cùng giữ (đếm vùng găng)', () async {
      final path = dir.path;
      final counter = File('$path${Platform.pathSeparator}counter');
      counter.writeAsStringSync('0');
      Future<void> worker() => Isolate.run(() async {
            final lock = FileLeaseLock(
              directory: () async => Directory(path),
              pollInterval: const Duration(milliseconds: 2),
            );
            final file = File('$path${Platform.pathSeparator}counter');
            for (var i = 0; i < 15; i++) {
              final lease =
                  await lock.tryAcquire(wait: const Duration(seconds: 10));
              if (lease == null) throw StateError('lock timeout');
              final value = int.parse(await file.readAsString());
              await Future<void>.delayed(const Duration(milliseconds: 1));
              await file.writeAsString('${value + 1}', flush: true);
              await lease.release();
            }
          });
      await Future.wait(<Future<void>>[worker(), worker()]);
      // Mất bước tăng nào ⇒ đã có lúc 2 isolate cùng ở trong vùng găng.
      expect(counter.readAsStringSync(), '30');
    });

    test('lease quá TTL (cùng pid) ⇒ bị steal', () async {
      writeLease(
        pidValue: 111,
        at: DateTime.now().subtract(const Duration(seconds: 20)),
      );
      final lease =
          await newLock(currentPid: () => 111).tryAcquire(wait: Duration.zero);
      expect(lease, isNotNull);
    });

    test('lease at=now nhưng pid KHÁC ⇒ thắng ngay, không chờ TTL (V2-2)',
        () async {
      writeLease(pidValue: 222, at: DateTime.now());
      final watch = Stopwatch()..start();
      final lease = await newLock(currentPid: () => 111)
          .tryAcquire(wait: const Duration(seconds: 5));
      expect(lease, isNotNull);
      expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('lease cùng pid chưa quá TTL ⇒ chờ hết wait rồi null', () async {
      writeLease(pidValue: 111, at: DateTime.now());
      final watch = Stopwatch()..start();
      final lease = await newLock(currentPid: () => 111)
          .tryAcquire(wait: const Duration(milliseconds: 150));
      expect(lease, isNull);
      expect(watch.elapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 150)));
    });

    test('file hỏng: còn mới ⇒ không steal; cũ quá TTL ⇒ steal', () async {
      lockFile().writeAsStringSync('');
      expect(await newLock().tryAcquire(wait: Duration.zero), isNull);
      lockFile().setLastModifiedSync(
          DateTime.now().subtract(const Duration(seconds: 30)));
      expect(await newLock().tryAcquire(wait: Duration.zero), isNotNull);
    });

    test('release KHÔNG xoá lease của owner khác (sau khi bị steal)', () async {
      final lease = await newLock().tryAcquire(wait: Duration.zero);
      writeLease(pidValue: pid, at: DateTime.now()); // owner khác đã steal
      await lease!.release();
      expect(lockFile().existsSync(), isTrue);
    });

    test(
        'release khi bên chờ đang mở file để đọc (Windows: sharing violation) '
        '⇒ thử lại và vẫn nhả (H1)', () async {
      final lease = await newLock().tryAcquire(wait: Duration.zero);
      // Giả bên đang chờ `_isOrphan → readAsString()` giữ handle đúng lúc nhả.
      final reader = lockFile().openSync();
      final closed = Future<void>.delayed(
        const Duration(milliseconds: 30),
        reader.closeSync,
      );
      await lease!.release();
      await closed;
      expect(lockFile().existsSync(), isFalse,
          reason: 'lease còn trên đĩa ⇒ bên chờ phải đợi hết TTL 12 s');
    });

    test('deleteIfOwned: delete() lỗi 2 lần ⇒ thử lại, xoá được (H1)',
        () async {
      lockFile().writeAsStringSync('mine');
      final flaky = _FlakyDeleteFile(lockFile(), failures: 2);

      final ok = await deleteIfOwned(flaky, (raw) => raw == 'mine',
          backoff: const Duration(milliseconds: 1));

      expect(ok, isTrue);
      expect(flaky.deleteCalls, 3);
      expect(lockFile().existsSync(), isFalse);
    });

    test(
        'deleteIfOwned: delete() lỗi mãi ⇒ dừng sau đúng attempts, trả false, '
        'không ném (đã log)', () async {
      lockFile().writeAsStringSync('mine');
      final flaky = _FlakyDeleteFile(lockFile(), failures: 1000);

      final ok = await deleteIfOwned(flaky, (raw) => raw == 'mine',
          attempts: 4, backoff: const Duration(milliseconds: 1));

      expect(ok, isFalse);
      expect(flaky.deleteCalls, 4);
      expect(lockFile().existsSync(), isTrue);
    });

    test('deleteIfOwned: không phải của mình / đã biến mất ⇒ không xoá',
        () async {
      lockFile().writeAsStringSync('other');
      final flaky = _FlakyDeleteFile(lockFile(), failures: 0);
      expect(await deleteIfOwned(flaky, (raw) => raw == 'mine'), isTrue);
      expect(flaky.deleteCalls, 0);
      expect(lockFile().existsSync(), isTrue);

      lockFile().deleteSync();
      expect(await deleteIfOwned(flaky, (raw) => raw == 'mine'), isTrue);
      expect(flaky.deleteCalls, 0);
    });

    test('nhả rồi bên đang chờ giành được', () async {
      final a = newLock();
      final first = await a.tryAcquire(wait: Duration.zero);
      final waiting = newLock().tryAcquire(wait: const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await first!.release();
      expect(await waiting, isNotNull);
    });

    test('không resolve được thư mục ⇒ fallback khoá trong isolate', () async {
      final lock = FileLeaseLock(
        directory: () async => throw const FileSystemException('no dir'),
      );
      final first = await lock.tryAcquire(wait: Duration.zero);
      expect(first, isNotNull);
      expect(await lock.tryAcquire(wait: Duration.zero), isNull);
      await first!.release();
      expect(await lock.tryAcquire(wait: Duration.zero), isNotNull);
    });

    test(
        'thư mục lỗi TẠM THỜI ⇒ lượt sau thử lại và dùng lease file (fallback '
        'không dính vĩnh viễn — L2)', () async {
      var calls = 0;
      final lock = FileLeaseLock(
        directory: () async {
          if (calls++ == 0) throw const FileSystemException('tạm lỗi');
          return dir;
        },
        pollInterval: const Duration(milliseconds: 10),
      );

      final fallbackLease = await lock.tryAcquire(wait: Duration.zero);
      expect(fallbackLease, isNotNull);
      expect(lockFile().existsSync(), isFalse);
      // Đang giữ lease fallback ⇒ cùng instance vẫn loại trừ trong isolate.
      expect(await lock.tryAcquire(wait: Duration.zero), isNull);
      await fallbackLease!.release();

      final fileLease = await lock.tryAcquire(wait: Duration.zero);
      expect(fileLease, isNotNull);
      expect(lockFile().existsSync(), isTrue,
          reason: 'đã quay lại loại trừ liên isolate bằng file');
      await fileLease!.release();
      expect(lockFile().existsSync(), isFalse);
    });
  });

  group('guard in-flight qa_<itemId>.inflight (A7)', () {
    BgFiles files({int Function()? currentPid}) =>
        BgFiles(baseDirectory: () async => dir, currentPid: currentPid);

    test('cùng pid đang giữ ⇒ null; nhả xong ⇒ lấy lại được', () async {
      final f = files();
      final guard = await f.tryAcquireInFlight(itemId: 'i1', action: 'DISCARD');
      expect(guard, isNotNull);
      expect(await f.tryAcquireInFlight(itemId: 'i1', action: 'MARK_USED'),
          isNull);
      expect(await f.tryAcquireInFlight(itemId: 'i2', action: 'MARK_USED'),
          isNotNull);
      await guard!.release();
      expect(await f.tryAcquireInFlight(itemId: 'i1', action: 'MARK_USED'),
          isNotNull);
    });

    test('release khi file đang bị mở để đọc ⇒ thử lại, vẫn xoá (H1)',
        () async {
      final guard = await files()
          .tryAcquireInFlight(itemId: 'i1', action: 'DISCARD');
      final guardFile =
          File('${dir.path}${Platform.pathSeparator}notification_bg'
              '${Platform.pathSeparator}qa_i1.inflight');
      final reader = guardFile.openSync();
      final closed = Future<void>.delayed(
        const Duration(milliseconds: 30),
        reader.closeSync,
      );
      await guard!.release();
      await closed;
      expect(guardFile.existsSync(), isFalse);
    });

    test('pid khác (process cũ đã chết) ⇒ steal ngay', () async {
      final old = await files(currentPid: () => 222)
          .tryAcquireInFlight(itemId: 'i1', action: 'DISCARD');
      expect(old, isNotNull);
      expect(
        await files(currentPid: () => 111)
            .tryAcquireInFlight(itemId: 'i1', action: 'DISCARD'),
        isNotNull,
      );
    });
  });

  group('RefreshGate', () {
    Dio dioWith(FakeHttpAdapter adapter) =>
        Dio(BaseOptions(baseUrl: 'https://test.local'))
          ..httpClientAdapter = adapter
          ..interceptors.add(ErrorMappingInterceptor());

    ResponseBody refreshOk(String rt) => jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            'accessToken': 'access-$rt',
            'refreshToken': rt,
            'expiresIn': 900,
          }),
        );

    test('đọc RT SAU khi giữ khoá, ghi TRƯỚC khi nhả', () async {
      final log = <String>[];
      final storage = ScriptedTokenStorage(refreshToken: 'r1', log: log);
      final gate = RefreshGate(lock: RecordingLock(log), tokenStorage: storage);
      final dio = dioWith(FakeHttpAdapter((_) async {
        log.add('post');
        return refreshOk('r2');
      }));

      final result = await gate.run(
        wait: const Duration(seconds: 1),
        budget: const Duration(seconds: 1),
        refresh: (rt, o, c) =>
            AuthRefreshUseCase(dio).call(rt, options: o, cancelToken: c),
      );

      expect(result.outcome, RefreshOutcome.refreshed);
      expect(
          log, <String>['acquire', 'read', 'post', 'read', 'save', 'release']);
      expect(storage.refreshToken, 'r2');
    });

    test(
        'budget: request treo vô hạn ⇒ failed sau đúng budget, khoá đã nhả, '
        'cancelToken tới đúng request', () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1');
      final lock = newLock();
      final gate = RefreshGate(lock: lock, tokenStorage: storage);
      CancelToken? passed;
      final adapter = FakeHttpAdapter((_) => Completer<ResponseBody>().future);
      final dio = dioWith(adapter);
      final watch = Stopwatch()..start();

      final result = await gate.run(
        wait: Duration.zero,
        budget: const Duration(milliseconds: 200),
        refresh: (rt, o, c) {
          passed = c;
          return AuthRefreshUseCase(dio).call(rt, options: o, cancelToken: c);
        },
      );

      expect(result.outcome, RefreshOutcome.failed);
      expect(watch.elapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 200)));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(adapter.requests.single.cancelToken, same(passed));
      expect(passed!.isCancelled, isTrue);
      expect(lockFile().existsSync(), isFalse, reason: 'lease đã nhả');
      expect(storage.saveCalls, 0);
    });

    test('đọc storage quá budget ⇒ failed, 0 request', () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1')
        ..readDelay = const Duration(milliseconds: 150);
      final adapter = FakeHttpAdapter((_) async => refreshOk('r2'));
      final gate = RefreshGate(lock: InProcessLock(), tokenStorage: storage);

      final result = await gate.run(
        wait: Duration.zero,
        budget: const Duration(milliseconds: 50),
        refresh: (rt, o, c) => AuthRefreshUseCase(dioWith(adapter))
            .call(rt, options: o, cancelToken: c),
      );

      expect(result.outcome, RefreshOutcome.failed);
      expect(adapter.requests, isEmpty);
    });

    test('401 ERR_AUTH_005 ⇒ rejected; mạng ⇒ failed; không có RT ⇒ rejected',
        () async {
      Future<RefreshGateResult> runWith(
        ScriptedTokenStorage storage,
        FakeHttpAdapter adapter,
      ) =>
          RefreshGate(lock: InProcessLock(), tokenStorage: storage).run(
            wait: Duration.zero,
            budget: const Duration(seconds: 1),
            refresh: (rt, o, c) => AuthRefreshUseCase(dioWith(adapter))
                .call(rt, options: o, cancelToken: c),
          );

      final revoked = await runWith(
        ScriptedTokenStorage(refreshToken: 'r1'),
        FakeHttpAdapter((_) async =>
            jsonResponse(401, notificationFixture('refresh_401_auth005.json'))),
      );
      expect(revoked.outcome, RefreshOutcome.rejected);

      final offline = await runWith(
        ScriptedTokenStorage(refreshToken: 'r1'),
        FakeHttpAdapter((options) async => throw DioException.connectionError(
            requestOptions: options, reason: 'offline')),
      );
      expect(offline.outcome, RefreshOutcome.failed);

      final none = await runWith(
        ScriptedTokenStorage(),
        FakeHttpAdapter((_) async => refreshOk('r2')),
      );
      expect(none.outcome, RefreshOutcome.rejected);
      expect(none.noRefreshToken, isTrue);
    });

    test('RT đổi thành null (logout) trong lúc refresh ⇒ KHÔNG ghi, rejected',
        () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1');
      final gate = RefreshGate(lock: InProcessLock(), tokenStorage: storage);
      final dio = dioWith(FakeHttpAdapter((_) async {
        storage.refreshToken = null; // TokenStorage.clear() chen giữa
        return refreshOk('r2');
      }));

      final result = await gate.run(
        wait: Duration.zero,
        budget: const Duration(seconds: 1),
        refresh: (rt, o, c) =>
            AuthRefreshUseCase(dio).call(rt, options: o, cancelToken: c),
      );

      expect(result.outcome, RefreshOutcome.rejected);
      expect(storage.saveCalls, 0);
      expect(storage.refreshToken, isNull);
    });

    test('hết chờ khoá ⇒ lockTimeout, không đọc storage', () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1');
      final result =
          await RefreshGate(lock: TimeoutLock(), tokenStorage: storage).run(
        wait: Duration.zero,
        budget: const Duration(seconds: 1),
        refresh: (_, __, ___) => throw StateError('không được gọi'),
      );
      expect(result.outcome, RefreshOutcome.lockTimeout);
      expect(storage.log, isEmpty);
    });
  });
}

/// `File` thật, nhưng `delete()` ném [FileSystemException] [failures] lần
/// đầu (giả sharing violation của Windows trên mọi nền tảng).
class _FlakyDeleteFile implements File {
  _FlakyDeleteFile(this._real, {required this.failures});

  final File _real;
  int failures;
  int deleteCalls = 0;

  @override
  String get path => _real.path;

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _real.readAsString(encoding: encoding);

  @override
  Future<bool> exists() => _real.exists();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    deleteCalls++;
    if (failures > 0) {
      failures--;
      throw FileSystemException('sharing violation (giả)', path);
    }
    return _real.delete(recursive: recursive);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
