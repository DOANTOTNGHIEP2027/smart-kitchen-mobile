import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Trạng thái quyền thông báo của app (fcm-notification-flow.md §4).
enum NotificationPermissionStatus {
  notDetermined,
  granted,

  /// Android 13+: OS còn cho hỏi lại; Android < 13: người dùng đã tắt.
  denied,

  /// Chỉ bật lại được trong Cài đặt hệ thống.
  permanentlyDenied,
  unsupported,
}

NotificationPermissionStatus mapAuthorizationStatus(AuthorizationStatus status) =>
    switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        NotificationPermissionStatus.granted,
      AuthorizationStatus.denied => NotificationPermissionStatus.denied,
      AuthorizationStatus.deniedPermanently =>
        NotificationPermissionStatus.permanentlyDenied,
      AuthorizationStatus.notDetermined =>
        NotificationPermissionStatus.notDetermined,
    };

/// Cổng tới FCM — tách khỏi `FirebaseMessaging.instance` để store test được
/// và gom xử lý web/thiếu Firebase về một chỗ (decision N6).
abstract interface class PushGateway {
  /// `false` trên web hoặc khi Firebase chưa init → store `unsupported`.
  bool get isSupported;
  Future<NotificationPermissionStatus> currentPermission();
  Future<NotificationPermissionStatus> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Future<void> deleteToken();
}

class FirebasePushGateway implements PushGateway {
  FirebasePushGateway({required bool firebaseAvailable})
      : _available = firebaseAvailable && !kIsWeb;

  final bool _available;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  bool get isSupported => _available;

  @override
  Future<NotificationPermissionStatus> currentPermission() async {
    if (!_available) return NotificationPermissionStatus.unsupported;
    final settings = await _messaging.getNotificationSettings();
    return mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_available) return NotificationPermissionStatus.unsupported;
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<String?> getToken() async =>
      _available ? _messaging.getToken() : null;

  @override
  Stream<String> get onTokenRefresh =>
      _available ? _messaging.onTokenRefresh : const Stream<String>.empty();

  @override
  Future<void> deleteToken() async {
    if (_available) await _messaging.deleteToken();
  }
}
