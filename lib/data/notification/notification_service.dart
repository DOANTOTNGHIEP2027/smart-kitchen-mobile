import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'device_api.dart';

/// Top-level handler cho background FCM message (phải là top-level function).
///
/// Chạy trong isolate riêng — không thể truy cập GetX hay state của app.
/// Chỉ log để debug; không làm gì thêm vì không có context.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'FCM background message: ${message.messageId} type=${message.data['type']}',
    name: 'FCM',
  );
  // Notification hiển thị tự động bởi FCM SDK khi app ở background/terminated.
  // Xử lý deep-link và action (MARK_USED/DISCARD) sẽ thuộc FE-4/FE-5.
}

/// Service quản lý Firebase Cloud Messaging + local notification (FE-3 #48).
///
/// Trách nhiệm:
/// - Xin quyền notification khi lần đầu dùng.
/// - Đăng ký FCM token với backend qua [DeviceApi].
/// - Lắng nghe `onTokenRefresh` để re-register khi token đổi.
/// - Hiển thị local notification khi app ở foreground (FCM SDK không tự hiện).
/// - Expose [onMessage] stream để app xử lý deep-link từ notification tap.
///
/// **Không tự khởi tạo FirebaseApp** — bootstrap đã làm rồi. Nếu Firebase
/// chưa cấu hình (dev không có `google-services.json`), service degrade graceful
/// (không crash, chỉ log warning và không đăng ký token).
class NotificationService {
  NotificationService({
    required DeviceApi deviceApi,
    required bool Function() isAuthenticated,
  })  : _deviceApi = deviceApi,
        _isAuthenticated = isAuthenticated;

  final DeviceApi _deviceApi;
  final bool Function() _isAuthenticated;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  String? _pendingToken;

  final _messageController = StreamController<RemoteMessage>.broadcast();

  /// Stream phát khi user tap notification (foreground hoặc từ background).
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  // ── Android notification channel cho foreground notifications ─────────────
  static const _channel = AndroidNotificationChannel(
    'smart_kitchen_default',
    'Smart Kitchen',
    description: 'Thông báo từ Smart Kitchen',
    importance: Importance.high,
  );

  /// Khởi tạo service — gọi một lần trong `bootstrap()` sau khi Firebase init.
  ///
  /// `tryInit = true` vì Firebase có thể chưa cấu hình (dev mode).
  Future<void> init({bool tryInit = true}) async {
    try {
      await _initLocalNotifications();
      await _requestPermission();
      await _setupFcm();
    } catch (e) {
      developer.log(
        'NotificationService: init thất bại (Firebase chưa cấu hình?) — $e',
        name: 'FCM',
      );
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _messageController.close();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Tạo channel Android (cần để hiển thị notification trên Android 8+)
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    developer.log(
      'FCM permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );
  }

  Future<void> _setupFcm() async {
    // Background handler phải được đăng ký trước khi app đầy đủ sẵn sàng
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Lần đầu lấy token và đăng ký
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerTokenIfAuthenticated(token);
    }

    // Khi token refresh (thường mỗi tháng hoặc khi app cài lại)
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerTokenIfAuthenticated,
    );

    // Foreground: FCM SDK không tự hiện notification khi app đang mở — cần
    // dùng flutter_local_notifications để hiện thủ công.
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);

    // Notification tap khi app từ background → opened
    FirebaseMessaging.onMessageOpenedApp.listen(_messageController.add);

    // Notification đã mở app từ terminated state
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _messageController.add(initial);
    }
  }

  Future<void> onAuthChanged() async {
    if (!_isAuthenticated()) return;
    final token = _pendingToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _registerTokenIfAuthenticated(token);
  }

  Future<void> _registerTokenIfAuthenticated(String token) async {
    _pendingToken = token;
    if (!_isAuthenticated()) {
      developer.log(
        'FCM: bỏ qua đăng ký token vì chưa authenticated',
        name: 'FCM',
      );
      return;
    }

    await _registerTokenSilently(token);
    _pendingToken = null;
  }

  Future<void> _registerTokenSilently(String token) async {
    try {
      await _deviceApi.registerDevice(fcmToken: token);
      developer.log('FCM token đã đăng ký với backend', name: 'FCM');
    } catch (e) {
      // Lỗi mạng hoặc auth — bỏ qua, sẽ thử lại lần sau khi token refresh.
      developer.log(
        'FCM: đăng ký token thất bại (sẽ thử lại khi token refresh): $e',
        name: 'FCM',
      );
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    // Phát vào stream để app xử lý nếu cần (ví dụ refresh data)
    _messageController.add(message);

    // Hiện local notification khi foreground
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['type'],
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    // Deep-link xử lý sẽ được implement trong FE-4 (inventory) / FE-5 (shopping)
    // khi có màn hình đích thật.
    developer.log(
      'Local notification tapped: payload=${response.payload}',
      name: 'FCM',
    );
  }
}
