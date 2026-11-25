import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/data/notification/cross_isolate_lock.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/utils/api_error_l10n.dart';
import 'package:smart_kitchen_mobile/utils/dio_exception_x.dart';

import '../../helpers/fake_http_adapter.dart';
import '../notification/quick_action_test_support.dart';

/// CẢ 3 đường refresh của main isolate đi qua `RefreshGate` (inventory-
/// management.md §20.3 Amendment #134 A5.4, Q-E1/E8; Guard 19; V2-6).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const protectedPath = '/api/v1/protected';
  const refreshPath = '/api/v1/auth/refresh';

  tearDown(Get.reset);

  /// Server giả với rotation single-use: mỗi RT chỉ dùng được 1 lần.
  FakeHttpAdapter singleUseServer(
    Set<String> valid, {
    Duration refreshDelay = Duration.zero,
  }) {
    var next = 2;
    return FakeHttpAdapter((options) async {
      if (options.path == refreshPath) {
        await Future<void>.delayed(refreshDelay);
        final rt = (options.data as Map)['refreshToken'] as String;
        if (!valid.remove(rt)) {
          return jsonResponse(
              401, errorEnvelope('ERR_AUTH_005', 'Refresh token revoked'));
        }
        final fresh = 'r${next++}';
        valid.add(fresh);
        return jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            'accessToken': fakeJwt(<String, dynamic>{'sub': 'u1', 'rt': fresh}),
            'refreshToken': fresh,
            'expiresIn': 900,
          }),
        );
      }
      final auth = options.headers['Authorization'] as String?;
      if (auth == 'Bearer access-old') {
        return jsonResponse(401, errorEnvelope('ERR_AUTH_001', 'expired'));
      }
      return jsonResponse(200, successEnvelope(<String, dynamic>{'ok': true}));
    });
  }

  DioClient client(
    ScriptedTokenStorage storage,
    FakeHttpAdapter adapter,
    RefreshGate gate,
  ) {
    final built = DioClient.build(
      tokenStorage: storage,
      dio: Dio(BaseOptions(baseUrl: 'https://test.local')),
      refreshGate: gate,
    );
    built.dio.httpClientAdapter = adapter;
    return built;
  }

  group('TokenRefreshInterceptor', () {
    test(
        'isolate khác giữ khoá và xoay RT ⇒ main chờ, đọc RT MỚI, refresh OK, '
        'không logout (thay test Guard 19 cũ)', () async {
      final dir = await Directory.systemTemp.createTemp('sk_gate_');
      addTearDown(() => dir.delete(recursive: true));
      FileLeaseLock lock() => FileLeaseLock(
            directory: () async => dir,
            pollInterval: const Duration(milliseconds: 10),
          );
      // Secure storage là 1 kho chung giữa các isolate cùng process.
      final storage = ScriptedTokenStorage(refreshToken: 'r1')
        ..accessToken = 'access-old';
      final valid = <String>{'r1'};
      final adapter = singleUseServer(valid,
          refreshDelay: const Duration(milliseconds: 200));
      final mainClient = client(
          storage, adapter, RefreshGate(lock: lock(), tokenStorage: storage));

      // "Isolate nền" giành khoá trước và refresh chậm.
      final bgDio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter;
      final bgGate = RefreshGate(lock: lock(), tokenStorage: storage);
      final bg = bgGate.run(
        wait: const Duration(seconds: 1),
        budget: const Duration(seconds: 3),
        refresh: (rt, o, c) =>
            AuthRefreshUseCase(bgDio).call(rt, options: o, cancelToken: c),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      storage.accessToken = 'access-old'; // RAM của main vẫn là token cũ

      final response = await mainClient.dio.get<dynamic>(protectedPath);

      expect((await bg).outcome, RefreshOutcome.refreshed);
      expect(response.statusCode, 200);
      expect(storage.cleared, isFalse);
      expect(storage.refreshToken, 'r3');
      expect(adapter.countPath(refreshPath), 2);
    });

    test(
        'lockTimeout ⇒ KHÔNG clear, KHÔNG logout, lỗi là NetworkException '
        '(copy networkError, không sessionExpired) — V2-6', () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1')
        ..accessToken = 'access-old';
      final session = SessionStore(
        storage,
        AuthRefreshUseCase(Dio()),
        refreshGate: RefreshGate(lock: InProcessLock(), tokenStorage: storage),
      );
      await session.replaceTokens(
        accessToken: fakeJwt(<String, dynamic>{'household_id': 'h1'}),
        refreshToken: 'r1',
      );
      storage.accessToken = 'access-old';
      Get.put<SessionStore>(session);
      final adapter = singleUseServer(<String>{'r1'});
      final lock = TimeoutLock();
      final dio = client(
              storage, adapter, RefreshGate(lock: lock, tokenStorage: storage))
          .dio;

      final error = await dio.get<dynamic>(protectedPath).then<DioException?>(
          (_) => null,
          onError: (Object e) => e as DioException);

      expect(lock.attempts, 1);
      expect(error!.apiException, isA<NetworkException>());
      expect(error.apiException, isNot(isA<AuthExpiredException>()));
      final l10n = lookupAppLocalizations(const Locale('vi'));
      expect(apiErrorMessage(l10n, error.apiException), l10n.networkError);
      expect(storage.cleared, isFalse);
      expect(storage.refreshToken, 'r1');
      expect(session.status, AuthStatus.authenticated);
      expect(adapter.countPath(refreshPath), 0);
    });

    test(
        'logout chen giữa lúc refresh (RT trong storage → null) ⇒ rejected: '
        'KHÔNG ghi token, clear + login như cũ (review L5)', () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1')
        ..accessToken = 'access-old';
      final session = SessionStore(
        storage,
        AuthRefreshUseCase(Dio()),
        refreshGate: RefreshGate(lock: InProcessLock(), tokenStorage: storage),
      );
      await session.replaceTokens(
        accessToken: fakeJwt(<String, dynamic>{'household_id': 'h1'}),
        refreshToken: 'r1',
      );
      storage
        ..accessToken = 'access-old'
        ..saveCalls = 0;
      Get.put<SessionStore>(session);
      // Không có GetMaterialApp: cho `Get.offAllNamed(login)` chạy không ném.
      Get.testMode = true;
      addTearDown(() => Get.testMode = false);
      final server = singleUseServer(<String>{'r1'});
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == refreshPath) {
          storage.refreshToken = null; // TokenStorage.clear() của logout
        }
        return server.handler(options);
      });
      final dio = client(storage, adapter,
              RefreshGate(lock: InProcessLock(), tokenStorage: storage))
          .dio;

      final error = await dio.get<dynamic>(protectedPath).then<DioException?>(
          (_) => null,
          onError: (Object e) => e as DioException);

      expect(adapter.countPath(refreshPath), 1);
      expect(storage.saveCalls, 0, reason: 'không làm phiên sống lại');
      expect(storage.refreshToken, isNull);
      expect(storage.cleared, isTrue);
      expect(error!.apiException, isA<AuthExpiredException>(),);
      expect(session.status, AuthStatus.unauthenticated);
    });

    test('đọc RT sau khi giữ khoá, ghi trước khi nhả', () async {
      final log = <String>[];
      final storage = ScriptedTokenStorage(refreshToken: 'r1', log: log)
        ..accessToken = 'access-old';
      final adapter = singleUseServer(<String>{'r1'});
      final dio = client(
        storage,
        adapter,
        RefreshGate(lock: RecordingLock(log), tokenStorage: storage),
      ).dio;

      final response = await dio.get<dynamic>(protectedPath);

      expect(response.statusCode, 200);
      expect(log, <String>['acquire', 'read', 'read', 'save', 'release']);
      expect(
          adapter.requests
              .where((r) => r.path == refreshPath)
              .single
              .cancelToken,
          isNotNull,
          reason: 'ngân sách tổng 8 s qua CancelToken');
    });
  });

  group('SessionStore', () {
    ResponseBody ok() => jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            'accessToken':
                fakeJwt(<String, dynamic>{'sub': 'u1', 'household_id': 'h1'}),
            'refreshToken': 'r2',
            'expiresIn': 900,
          }),
        );

    SessionStore store(
      ScriptedTokenStorage storage,
      CrossIsolateLock lock,
      FakeHttpAdapter adapter,
    ) =>
        SessionStore(
          storage,
          AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))
            ..httpClientAdapter = adapter),
          refreshGate: RefreshGate(lock: lock, tokenStorage: storage),
        );

    test('bootstrap() đọc RT SAU khoá, ghi TRƯỚC khi nhả', () async {
      final log = <String>[];
      final storage = ScriptedTokenStorage(refreshToken: 'r1', log: log);
      final adapter = FakeHttpAdapter((_) async => ok());
      final s = store(storage, RecordingLock(log), adapter);

      await s.bootstrap();

      expect(s.status, AuthStatus.authenticated);
      expect(s.householdId, 'h1');
      expect(log, <String>['acquire', 'read', 'read', 'save', 'release']);
      expect(adapter.requests.single.cancelToken, isNotNull);
    });

    test('bootstrap() lockTimeout ⇒ unauthenticated, token CÒN (F3)', () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1');
      final adapter = FakeHttpAdapter((_) async => ok());
      final s = store(storage, TimeoutLock(), adapter);

      await s.bootstrap();

      expect(s.status, AuthStatus.unauthenticated);
      expect(storage.cleared, isFalse);
      expect(storage.refreshToken, 'r1');
      expect(adapter.requests, isEmpty);
    });

    test('bootstrap() rejected ⇒ xoá token như catch-all cũ', () async {
      final storage = ScriptedTokenStorage(refreshToken: 'r1');
      final s = store(
        storage,
        InProcessLock(),
        FakeHttpAdapter((_) async =>
            jsonResponse(401, errorEnvelope('ERR_AUTH_005', 'revoked'))),
      );

      await s.bootstrap();

      expect(s.status, AuthStatus.unauthenticated);
      expect(storage.cleared, isTrue);
    });

    test(
        'refreshSession() đọc RT SAU khoá; lockTimeout ⇒ ném, refreshClaims nuốt',
        () async {
      final log = <String>[];
      final storage = ScriptedTokenStorage(refreshToken: 'r1', log: log);
      final s = store(
          storage, RecordingLock(log), FakeHttpAdapter((_) async => ok()));

      await s.refreshSession();
      expect(log, <String>['acquire', 'read', 'read', 'save', 'release']);
      expect(s.householdId, 'h1');

      final blocked =
          store(storage, TimeoutLock(), FakeHttpAdapter((_) async => ok()));
      await expectLater(blocked.refreshSession(), throwsA(isA<StateError>()));
      await blocked.refreshClaims();
      expect(storage.cleared, isFalse);
    });
  });
}
