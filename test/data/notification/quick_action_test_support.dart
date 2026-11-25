import 'dart:convert';
import 'dart:io';

import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/notification/cross_isolate_lock.dart';
import 'package:smart_kitchen_mobile/data/notification/quick_action_background.dart';

/// Fixture JSON camelCase đúng OAS `notification-quick-actions.yaml`
/// (inventory-management.md §20.3 Amendment #134 A10).
Map<String, dynamic> notificationFixture(String name) =>
    Map<String, dynamic>.from(jsonDecode(
      File('test/fixtures/notification/$name').readAsStringSync(),
    ) as Map);

/// Presenter giả: ghi lại mọi lần dựng/cập nhật notification.
class FakeQuickActionPresenter implements QuickActionNotificationPresenter {
  final List<QuickActionNotification> shown = <QuickActionNotification>[];
  void Function(QuickActionNotification notification)? onShow;

  @override
  Future<void> show(QuickActionNotification notification) async {
    onShow?.call(notification);
    shown.add(notification);
  }
}

/// Khoá luôn hết thời gian chờ (giả lập bên khác giữ quá lâu).
class TimeoutLock implements CrossIsolateLock {
  int attempts = 0;

  @override
  Future<LockLease?> tryAcquire({required Duration wait}) async {
    attempts++;
    return null;
  }
}

/// Khoá ghi lại thứ tự acquire/release vào [log] dùng chung với storage.
class RecordingLock implements CrossIsolateLock {
  RecordingLock(this.log);

  final List<String> log;
  final InProcessLock _inner = InProcessLock();

  @override
  Future<LockLease?> tryAcquire({required Duration wait}) async {
    final lease = await _inner.tryAcquire(wait: wait);
    if (lease == null) return null;
    log.add('acquire');
    return _RecordingLease(lease, log);
  }
}

class _RecordingLease implements LockLease {
  _RecordingLease(this._inner, this._log);

  final LockLease _inner;
  final List<String> _log;

  @override
  Future<void> release() async {
    _log.add('release');
    await _inner.release();
  }
}

/// Secure storage giả dùng chung giữa "các isolate" trong test; ghi lại thứ
/// tự đọc/ghi và cho phép chèn lỗi / độ trễ.
class ScriptedTokenStorage implements TokenStorage {
  ScriptedTokenStorage({this.refreshToken, List<String>? log})
      : log = log ?? <String>[];

  @override
  String? accessToken;
  String? refreshToken;
  final List<String> log;
  Object? readError;
  Duration readDelay = Duration.zero;
  int saveCalls = 0;
  bool cleared = false;

  @override
  Future<String?> readRefreshToken() async {
    log.add('read');
    if (readDelay > Duration.zero) await Future<void>.delayed(readDelay);
    final error = readError;
    if (error != null) throw error;
    return refreshToken;
  }

  @override
  Future<void> saveTokens(String access, String refresh) async {
    log.add('save');
    saveCalls++;
    accessToken = access;
    refreshToken = refresh;
  }

  @override
  Future<void> clear() async {
    log.add('clear');
    cleared = true;
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<Map<String, dynamic>?> readUser() async => null;

  @override
  Future<void> saveUser(Map<String, dynamic> json) async {}
}
