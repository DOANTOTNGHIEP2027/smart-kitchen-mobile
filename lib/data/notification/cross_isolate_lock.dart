import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../domain/auth/auth_refresh_usecase.dart';
import '../auth/token_storage.dart';
import '../network/api_exception.dart';

/// Khoá refresh token dùng chung giữa UI isolate và isolate nền của
/// notification (inventory-management.md §20.3 Amendment #134 A5).
abstract interface class CrossIsolateLock {
  /// `null` = hết thời gian chờ (KHÔNG phải lỗi auth).
  Future<LockLease?> tryAcquire({required Duration wait});
}

abstract interface class LockLease {
  Future<void> release();
}

/// Khoá trong cùng isolate — dùng khi không có file system (web) và làm mặc
/// định cho store/interceptor dựng trong test. Production truyền
/// [FileLeaseLock] từ `bootstrap()`.
class InProcessLock implements CrossIsolateLock {
  Completer<void>? _held;

  @override
  Future<LockLease?> tryAcquire({required Duration wait}) async {
    final watch = Stopwatch()..start();
    while (true) {
      final held = _held;
      if (held == null) break;
      final remaining = wait - watch.elapsed;
      if (remaining <= Duration.zero) return null;
      try {
        await held.future.timeout(remaining);
      } on TimeoutException {
        return null;
      }
    }
    final mine = Completer<void>();
    _held = mine;
    return _CallbackLease(() async {
      if (identical(_held, mine)) {
        _held = null;
        mine.complete();
      }
    });
  }
}

class _CallbackLease implements LockLease {
  _CallbackLease(this._onRelease);

  final Future<void> Function() _onRelease;
  bool _released = false;

  @override
  Future<void> release() async {
    if (_released) return;
    _released = true;
    await _onRelease();
  }
}

/// Tạo [file] nguyên tử bằng `create(exclusive: true)`; nếu file đã có và là
/// MỒ CÔI thì xoá rồi thử tạo **đúng 1 lần** (A5.1, A7).
///
/// Mồ côi khi: parse được và `pid` khác [currentPid] (process cũ đã chết —
/// mọi bên tranh khoá cùng 1 process, V2-2) **hoặc** `at` quá [ttl]; không
/// parse được và `lastModified` quá [ttl].
Future<bool> createExclusiveOrSteal(
  File file, {
  required String Function() content,
  required Duration ttl,
  required int Function() currentPid,
  required DateTime Function() now,
}) async {
  if (await _tryCreate(file, content())) return true;
  if (!await _isOrphan(file, ttl: ttl, currentPid: currentPid, now: now)) {
    return false;
  }
  try {
    await file.delete();
  } on FileSystemException {
    // Bên khác vừa xoá/steal — thử tạo bên dưới quyết định ai thắng.
  }
  return _tryCreate(file, content());
}

Future<bool> _tryCreate(File file, String content) async {
  try {
    await file.create(exclusive: true);
  } on FileSystemException {
    return false;
  }
  try {
    await file.writeAsString(content, flush: true);
  } catch (_) {
    // Không ghi được nội dung thì nhả ngay để không để lại khoá rỗng.
    await _deleteQuietly(file);
    rethrow;
  }
  return true;
}

Future<bool> _isOrphan(
  File file, {
  required Duration ttl,
  required int Function() currentPid,
  required DateTime Function() now,
}) async {
  final String raw;
  try {
    raw = await file.readAsString();
  } on FileSystemException {
    return false; // vừa biến mất — vòng sau tạo lại
  }
  try {
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final ownerPid = (json['pid'] as num).toInt();
    final at = (json['at'] as num).toInt();
    if (ownerPid != currentPid()) return true;
    return now().millisecondsSinceEpoch - at > ttl.inMilliseconds;
  } catch (_) {
    // Đang ghi dở (vừa create, chưa write) hoặc hỏng: chỉ coi là mồ côi khi
    // đã cũ quá TTL.
    try {
      final modified = await file.lastModified();
      return now().difference(modified) > ttl;
    } on FileSystemException {
      return false;
    }
  }
}

/// Xoá [file] nếu nội dung vẫn là của mình ([owns]); trả `true` khi file đã
/// không còn là của mình trên đĩa (đã xoá / bị steal / biến mất).
///
/// `delete()` lỗi thì THỬ LẠI [attempts] lần, backoff tăng dần từ [backoff]:
/// trên Windows xoá file đang bị bên chờ mở để đọc (`_isOrphan`) ném sharing
/// violation; trước đây lỗi này bị nuốt nên lease nằm lại tới hết TTL 12 s
/// > chờ 6 s của main ⇒ `lockTimeout` (review #134 H1). Hết lượt ⇒ `developer.log` và trả
/// `false`, không ném (caller nhả trong `finally`). Dùng chung cho lease
/// khoá refresh và guard in-flight (`InFlightGuard`).
Future<bool> deleteIfOwned(
  File file,
  bool Function(String raw) owns, {
  int attempts = 5,
  Duration backoff = const Duration(milliseconds: 20),
}) async {
  Object? lastError;
  for (var attempt = 1;; attempt++) {
    try {
      final String raw;
      try {
        raw = await file.readAsString();
      } on FileSystemException {
        if (!await file.exists()) return true; // đã bị xoá/steal
        rethrow;
      }
      bool mine;
      try {
        mine = owns(raw);
      } catch (_) {
        mine = false; // hỏng / đang ghi dở bởi bên khác ⇒ không phải của mình
      }
      if (!mine) return true;
      await file.delete();
      return true;
    } on FileSystemException catch (error) {
      lastError = error;
    }
    if (attempt >= attempts) break;
    await Future<void>.delayed(backoff * attempt);
  }
  developer.log(
    'Lease release failed after $attempts attempts: ${file.path} '
    '($lastError) — sẽ bị coi là mồ côi khi quá TTL',
    name: 'auth',
  );
  return false;
}

Future<void> _deleteQuietly(File file) async {
  try {
    await file.delete();
  } on FileSystemException {
    // đã không còn
  }
}

String _randomOwnerId() {
  final random = Random.secure();
  return List<String>.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Lease file `<appSupport>/notification_bg/auth_refresh.lock` (A5.1).
///
/// `RandomAccessFile.lock()` khoá theo process nên 2 isolate cùng process đều
/// "giữ" được; secure storage không có compare-and-set ⇒ dùng
/// `create(exclusive: true)` + owner + pid + TTL.
class FileLeaseLock implements CrossIsolateLock {
  FileLeaseLock({
    required Future<Directory> Function() directory,
    this.ttl = defaultTtl,
    this.pollInterval = const Duration(milliseconds: 100),
    int Function()? currentPid,
    DateTime Function()? now,
    String Function()? ownerId,
  })  : _directory = directory,
        _currentPid = currentPid ?? (() => pid),
        _now = now ?? DateTime.now,
        _ownerId = ownerId ?? _randomOwnerId;

  static const String fileName = 'auth_refresh.lock';

  /// TTL 12 s > giữ khoá tối đa 10 s của MỌI bên (budget 8 s + biên storage
  /// 2 s — A5.3). Ai tăng budget phải tăng TTL theo.
  ///
  /// TTL so `at` (giờ hệ thống — `DateTime.now`) chứ không phải đồng hồ đơn
  /// điệu: 2 isolate không có chung `Stopwatch`. Người dùng chỉnh giờ / NTP
  /// nhảy tới > 12 s đúng lúc có người giữ khoá ⇒ lease sống bị steal, 2 bên
  /// cùng gửi 1 RT, 1 bên `rejected` ⇒ main logout. Rất hiếm, chấp nhận
  /// (review #134 L3, OD-46).
  ///
  /// Hot restart (chỉ debug) đúng lúc đang refresh để lại lease CÙNG pid ⇒
  /// lần `bootstrap()` sau chờ `mainWait` rồi `lockTimeout` (token còn, về
  /// login) cho tới khi lease quá TTL. KHÔNG steal theo "owner không có
  /// trong registry của isolate này": isolate nền quick-action cùng pid có
  /// registry riêng, steal như vậy sẽ cướp lease ĐANG SỐNG ⇒ dùng RT 2 lần ⇒
  /// logout thật (review #134 L4, OD-46).
  static const Duration defaultTtl = Duration(seconds: 12);

  final Future<Directory> Function() _directory;
  final Duration ttl;
  final Duration pollInterval;
  final int Function() _currentPid;
  final DateTime Function() _now;
  final String Function() _ownerId;

  /// Luôn giữ TRƯỚC lease file: loại trừ trong isolate kể cả khi lượt này
  /// phải rơi về fallback (không có thư mục) còn lượt khác dùng được file.
  final InProcessLock _local = InProcessLock();

  @override
  Future<LockLease?> tryAcquire({required Duration wait}) async {
    final watch = Stopwatch()..start();
    final local = await _local.tryAcquire(wait: wait);
    if (local == null) return null;
    try {
      final Directory dir;
      try {
        dir = await _directory();
      } catch (error) {
        // Không có file system (plugin lỗi tạm): CHỈ lượt này single-flight
        // trong isolate, không chặn được isolate khác. Lượt sau thử lại thư
        // mục — không dính fallback vĩnh viễn (review #134 L2). Web không vào
        // đây: bootstrap() truyền thẳng InProcessLock.
        developer.log('Refresh lock fallback in-process: $error', name: 'auth');
        return local;
      }
      final file = await _acquireFile(dir, wait - watch.elapsed);
      if (file == null) {
        await local.release();
        return null;
      }
      return _CallbackLease(() async {
        try {
          await file.release();
        } finally {
          await local.release();
        }
      });
    } catch (_) {
      await local.release();
      rethrow;
    }
  }

  Future<LockLease?> _acquireFile(Directory dir, Duration wait) async {
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    final owner = _ownerId();
    final watch = Stopwatch()..start();
    while (true) {
      final created = await createExclusiveOrSteal(
        file,
        content: () => jsonEncode(<String, Object>{
          'owner': owner,
          'pid': _currentPid(),
          'at': _now().millisecondsSinceEpoch,
        }),
        ttl: ttl,
        currentPid: _currentPid,
        now: _now,
      );
      if (created) return _FileLease(file, owner);
      final remaining = wait - watch.elapsed;
      if (remaining <= Duration.zero) return null;
      await Future<void>.delayed(
        remaining < pollInterval ? remaining : pollInterval,
      );
    }
  }
}

class _FileLease implements LockLease {
  _FileLease(this._file, this._owner);

  final File _file;
  final String _owner;
  bool _released = false;

  /// CHỈ xoá khi owner trong file vẫn là của mình — không xoá lease của bên
  /// khác sau khi mình bị steal.
  @override
  Future<void> release() async {
    if (_released) return;
    _released = true;
    await deleteIfOwned(
      _file,
      (raw) => (jsonDecode(raw) as Map)['owner'] == _owner,
    );
  }
}

enum RefreshOutcome { refreshed, rejected, failed, lockTimeout }

class RefreshGateResult {
  const RefreshGateResult(
    this.outcome, {
    this.tokens,
    this.error,
    this.noRefreshToken = false,
  });

  final RefreshOutcome outcome;

  /// Cặp token mới — chỉ có khi [outcome] là `refreshed` (đã ghi xuống
  /// storage TRƯỚC khi nhả khoá).
  final AuthRefreshResult? tokens;

  /// Lỗi gốc của lần refresh (để phân loại mạng / lỗi khác).
  final Object? error;

  /// Storage không có refresh token (chưa từng đăng nhập / đã logout).
  final bool noRefreshToken;
}

typedef RefreshCall = Future<AuthRefreshResult> Function(
  String refreshToken,
  Options options,
  CancelToken cancelToken,
);

/// Vùng găng refresh dùng chung cho isolate nền VÀ cả 3 đường refresh của main
/// isolate (A5.2, A5.4, Guard 19).
///
/// 1. Đọc refresh token SAU khi giữ khoá (không bao giờ trước).
/// 2. Đúng 1 ngân sách TỔNG ([budget]) cắt bằng `CancelToken` + `Timer`.
/// 3. Ghi có điều kiện: RT trong storage đã đổi/null ⇒ không ghi, `rejected`.
/// 4. Ghi cặp mới TRƯỚC khi nhả khoá.
class RefreshGate {
  RefreshGate({
    required CrossIsolateLock lock,
    required TokenStorage tokenStorage,
  })  : _lock = lock,
        _tokenStorage = tokenStorage;

  /// Main isolate: chờ khoá 6 s > isolate nền giữ tối đa 5 s (A5.3).
  static const Duration mainWait = Duration(seconds: 6);

  /// Main isolate: ngân sách tổng 8 s (không dùng timeout 10 s / 20 s của
  /// `DioClient` — vượt TTL).
  static const Duration mainBudget = Duration(seconds: 8);

  final CrossIsolateLock _lock;
  final TokenStorage _tokenStorage;

  Future<RefreshGateResult> run({
    required Duration wait,
    required Duration budget,
    required RefreshCall refresh,
  }) async {
    final LockLease? lease;
    try {
      lease = await _lock.tryAcquire(wait: wait);
    } catch (error) {
      developer.log('Refresh lock error: $error', name: 'auth');
      return RefreshGateResult(RefreshOutcome.lockTimeout, error: error);
    }
    if (lease == null) {
      return const RefreshGateResult(RefreshOutcome.lockTimeout);
    }
    final cancelToken = CancelToken();
    // Huỷ ở client KHÔNG huỷ được việc BE đã xử lý: BE đã xoay RT1→RT2 mà
    // response về sau budget (nền chỉ còn ≤ 3 s, mạng di động chậm) ⇒ storage
    // vẫn giữ RT1 đã bị thu hồi ⇒ lần refresh kế tiếp `ERR_AUTH_005` ⇒ logout.
    // Chờ BE trả lời có cửa sổ ân hạn cho RT vừa xoay không (review #134 M2,
    // OD-46); chưa đổi budget.
    final timer = Timer(budget, () => cancelToken.cancel('refresh budget'));
    try {
      return await _critical(budget, cancelToken, refresh);
    } finally {
      timer.cancel();
      try {
        await lease.release();
      } catch (error) {
        developer.log('Refresh lock release error: $error', name: 'auth');
      }
    }
  }

  Future<RefreshGateResult> _critical(
    Duration budget,
    CancelToken cancelToken,
    RefreshCall refresh,
  ) async {
    final String? refreshToken;
    try {
      refreshToken = await _tokenStorage.readRefreshToken();
    } catch (error) {
      return RefreshGateResult(RefreshOutcome.rejected, error: error);
    }
    if (refreshToken == null) {
      return const RefreshGateResult(
        RefreshOutcome.rejected,
        noRefreshToken: true,
      );
    }
    // Đọc storage đã ăn hết budget ⇒ không gửi request.
    if (cancelToken.isCancelled) {
      return const RefreshGateResult(RefreshOutcome.failed);
    }
    final AuthRefreshResult result;
    try {
      result = await refresh(
        refreshToken,
        Options(
          connectTimeout: budget,
          sendTimeout: budget,
          receiveTimeout: budget,
        ),
        cancelToken,
      );
    } catch (error) {
      return RefreshGateResult(
        isRefreshRejection(error)
            ? RefreshOutcome.rejected
            : RefreshOutcome.failed,
        error: error,
      );
    }
    try {
      final current = await _tokenStorage.readRefreshToken();
      // Đăng xuất trong lúc đang refresh ⇒ không làm "phiên sống lại".
      if (current != refreshToken) {
        return const RefreshGateResult(RefreshOutcome.rejected);
      }
      await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
    } catch (error) {
      return RefreshGateResult(RefreshOutcome.failed, error: error);
    }
    return RefreshGateResult(RefreshOutcome.refreshed, tokens: result);
  }
}

/// 401 / `ERR_AUTH_005` của `/auth/refresh` = refresh token bị thu hồi / hết
/// hạn. Mọi lỗi khác (mạng, timeout, cancel, 5xx, parse) là `failed`.
bool isRefreshRejection(Object error) {
  final mapped = error is DioException ? error.error : error;
  if (mapped is AuthExpiredException) return true;
  if (mapped is ApiException && mapped.code == 'ERR_AUTH_005') return true;
  return error is DioException && error.response?.statusCode == 401;
}
