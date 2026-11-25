import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cờ "đã hỏi quyền thông báo" — gắn với THIẾT BỊ, giữ qua logout
/// (fcm-notification-flow.md §6, decision N7).
abstract interface class NotificationPrefs {
  Future<bool> hasAskedPermission();
  Future<void> markPermissionAsked();
}

class SecureNotificationPrefs implements NotificationPrefs {
  SecureNotificationPrefs({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _askedKey = 'notification_permission_asked';
  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasAskedPermission() async {
    try {
      return await _storage.read(key: _askedKey) == 'true';
    } catch (_) {
      // Storage hỏng → coi như chưa hỏi; tệ nhất là hỏi thêm một lần.
      return false;
    }
  }

  @override
  Future<void> markPermissionAsked() async {
    try {
      await _storage.write(key: _askedKey, value: 'true');
    } catch (_) {
      // Bỏ qua: store vẫn giữ cờ trong bộ nhớ cho phiên này.
    }
  }
}
