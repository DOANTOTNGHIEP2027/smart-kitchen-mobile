import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_exception.dart';
import 'app_notification.dart';
import 'fcm_action_payload.dart';
import 'notification_routing.dart';
import 'quick_action_api.dart';
import 'quick_action_background.dart';
import '../../l10n/app_localizations.dart';

const String inventoryExpiryCategory = 'SK_INVENTORY_EXPIRY_V1';

/// Event SnackBar cho UI. Điều hướng KHÔNG đi qua đây nữa mà qua
/// `NotificationStore.pendingTarget` (fcm-notification-flow.md §14.1, N9).
enum NotificationUiEventType {
  inventoryUpdated,
  inventoryAlreadyUsed,
  inventoryAlreadyDiscarded,
  inventoryAlreadyProcessed,
  inventoryGone,
  inventoryReadonly,
  noNetwork,
  actionFailed,
}

class NotificationUiEvent {
  const NotificationUiEvent(this.type);

  final NotificationUiEventType type;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  final payload = FcmActionPayload.tryParse(message.data);
  if (payload == null || !payload.renderLocally) return;
  await _showInventoryNotification(
    payload,
    notificationId: _notificationId(message),
    messageId: message.messageId,
  );
}

/// Channel của cảnh báo kho — dùng chung UI isolate và isolate nền.
const AndroidNotificationChannel inventoryAlertChannel =
    AndroidNotificationChannel(
  'smart_kitchen_inventory_alerts',
  'Inventory alerts',
  description: 'Expiry and low-stock inventory alerts',
  importance: Importance.high,
);

/// `MARK_USED`/`DISCARD` chạy ở isolate nền (không mở app); `COOK_TODAY` là
/// deep-link nên mở app (Guard 25, A9).
bool isBackgroundQuickAction(String actionId) =>
    actionId == 'MARK_USED' || actionId == 'DISCARD';

/// Builder dùng chung cho mọi lần dựng/cập nhật cảnh báo hết hạn (Guard 24,
/// A6): cùng channel, cùng luật `showsUserInterface`.
NotificationDetails inventoryNotificationDetails(
  List<FcmNotificationAction> actions, {
  int? timeoutAfter,
  bool onlyAlertOnce = false,
  String? bigText,
}) =>
    NotificationDetails(
      android: AndroidNotificationDetails(
        inventoryAlertChannel.id,
        inventoryAlertChannel.name,
        channelDescription: inventoryAlertChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        onlyAlertOnce: onlyAlertOnce,
        timeoutAfter: timeoutAfter,
        styleInformation:
            bigText == null ? null : BigTextStyleInformation(bigText),
        actions: actions
            .map((action) => AndroidNotificationAction(
                  action.id,
                  action.label,
                  showsUserInterface: !isBackgroundQuickAction(action.id),
                  cancelNotification: false,
                ))
            .toList(growable: false),
      ),
    );

/// Khởi tạo plugin CHỈ trong isolate nền (FCM background / quick-action).
/// Mọi `initialize` đều truyền cùng callback nền top-level (Guard 25).
Future<void> initInventoryNotificationsInBackground(
  FlutterLocalNotificationsPlugin plugin,
) async {
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveBackgroundNotificationResponse: quickActionBackgroundEntry,
  );
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(inventoryAlertChannel);
}

/// [plugin] != null: UI isolate, plugin đã `initialize` ở `init()` — KHÔNG
/// init lại (FLN singleton, init lần 2 ghi đè handler tap — Guard 26).
/// [plugin] == null: isolate nền FCM, tự khởi tạo kèm callback nền.
Future<void> _showInventoryNotification(
  FcmActionPayload payload, {
  required int notificationId,
  String? messageId,
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final target = plugin ?? FlutterLocalNotificationsPlugin();
  if (plugin == null) await initInventoryNotificationsInBackground(target);
  await target.show(
    id: notificationId,
    title: payload.title,
    body: payload.body,
    notificationDetails: inventoryNotificationDetails(payload.actions),
    payload: encodeNotificationInteraction(
      payload.data,
      notificationId,
      messageId: messageId,
      title: payload.title,
      body: payload.body,
    ),
  );
}

/// Adapter phía platform cho thông báo (fcm-notification-flow.md §3):
/// local notification, listener FCM, quick-action. Quyền + token do
/// `NotificationStore` giữ (qua `PushGateway`).
class NotificationService {
  NotificationService({
    required QuickActionApi quickActionApi,
    required Future<void> Function() onInventoryChanged,
    required void Function(NotificationTarget target) onNavigate,
    void Function(Map<String, dynamic> data)? onNavigationData,
    bool firebaseAvailable = true,
  })  : _quickActionApi = quickActionApi,
        _onInventoryChanged = onInventoryChanged,
        _onNavigate = onNavigate,
        _onNavigationData = onNavigationData,
        _firebaseAvailable = firebaseAvailable;

  final QuickActionApi _quickActionApi;
  final Future<void> Function() _onInventoryChanged;
  final void Function(NotificationTarget target) _onNavigate;

  /// Nhận `data` của push ngay TRƯỚC `_onNavigate` (popup vote cần
  /// planId/targetDate). Tách riêng để `onNavigate` giữ một tham số.
  final void Function(Map<String, dynamic> data)? _onNavigationData;
  final bool _firebaseAvailable;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _uiEventController = StreamController<NotificationUiEvent>.broadcast();
  final List<NotificationUiEvent> _pendingUiEvents = <NotificationUiEvent>[];

  /// Thông báo nhận trước khi store gắn sink (cold start) — §14.1.
  final List<AppNotification> _pendingNotifications = <AppNotification>[];
  void Function(AppNotification)? _sink;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _uiAttached = false;

  Stream<NotificationUiEvent> get uiEvents => _uiEventController.stream;

  /// Gắn nơi nhận thông báo (NotificationStore.addNotification). Gọi TRƯỚC
  /// [init]; thông báo đến sớm hơn được buffer rồi đẩy hết khi gắn.
  void attachSink(void Function(AppNotification) sink) {
    _sink = sink;
    for (final item in _pendingNotifications) {
      sink(item);
    }
    _pendingNotifications.clear();
  }

  void _record(AppNotification notification) {
    final sink = _sink;
    if (sink == null) {
      _pendingNotifications.add(notification);
    } else {
      sink(notification);
    }
  }

  static const _channel = AndroidNotificationChannel(
    'smart_kitchen_default',
    'Smart Kitchen',
    description: 'Smart Kitchen notifications',
    importance: Importance.high,
  );

  List<NotificationUiEvent> attachUi() {
    _uiAttached = true;
    final events = List<NotificationUiEvent>.from(_pendingUiEvents);
    _pendingUiEvents.clear();
    return events;
  }

  /// KHÔNG xin quyền ở đây nữa (Guard 1) — `NotificationStore` xin khi người
  /// dùng bấm "Bật thông báo". Web: bỏ qua hoàn toàn (§9).
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await _initLocalNotifications();
    } catch (error) {
      developer.log('Local notifications init failed: $error', name: 'FCM');
    }
    if (!_firebaseAvailable) return;
    try {
      await _setupFcm();
    } catch (error) {
      developer.log('NotificationService FCM init failed: $error',
          name: 'FCM');
    }
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _uiEventController.close();
  }

  Future<void> _initLocalNotifications() async {
    final platformLocale = PlatformDispatcher.instance.locale;
    final l10n = lookupAppLocalizations(
      platformLocale.languageCode == 'vi'
          ? const Locale('vi')
          : const Locale('en'),
    );
    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            inventoryExpiryCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'COOK_TODAY',
                l10n.notificationActionCookToday,
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
              // Giữ `.foreground` cho tới khi có iOS: bỏ nó thì action chạy
              // ở engine nền, cần onDidReceiveBackgroundNotificationResponse
              // + Dio/token trong isolate nền — chưa có nên nút bị nuốt
              // (review #48 M2, OD-41, Q2).
              DarwinNotificationAction.plain(
                'MARK_USED',
                l10n.notificationActionMarkUsed,
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
              DarwinNotificationAction.plain(
                'DISCARD',
                l10n.notificationActionDiscard,
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
        ],
      ),
    );
    // Android: MARK_USED/DISCARD (showsUserInterface: false) đi callback nền
    // top-level — Guard 25, A9. Nhánh `_applyQuickAction` bên dưới chỉ còn
    // cho iOS (`.foreground`, E1).
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: quickActionBackgroundEntry,
    );
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.createNotificationChannel(inventoryAlertChannel);

    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      unawaited(_handleNotificationResponse(response));
    }
  }

  Future<void> _setupFcm() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _foregroundSub = FirebaseMessaging.onMessage.listen(handleForegroundMessage);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(handleOpenedMessage);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) handleOpenedMessage(initial);
  }

  /// Foreground: ghi vào danh sách (chưa đọc) + hiện local notification.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    _record(_fromRemote(message));
    final payload = FcmActionPayload.tryParse(message.data);
    if (payload?.renderLocally == true) {
      await _showInventoryNotification(
        payload!,
        notificationId: _notificationId(message),
        messageId: message.messageId,
        plugin: _localNotifications,
      );
      return;
    }
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: _notificationId(message),
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
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: inventoryExpiryCategory,
        ),
      ),
      payload: encodeNotificationInteraction(
        message.data,
        _notificationId(message),
        messageId: message.messageId,
        title: notification.title,
        body: notification.body,
      ),
    );
  }

  /// Mở app từ thông báo (nền / cold start): ghi (đã đọc) + điều hướng.
  void handleOpenedMessage(RemoteMessage message) {
    _record(_fromRemote(message, read: true));
    _navigateFor(message.data);
  }

  void _navigateFor(Map<String, dynamic> data) {
    _onNavigationData?.call(data);
    _onNavigate(resolveNotificationTarget(data));
  }

  AppNotification _fromRemote(RemoteMessage message, {bool read = false}) =>
      AppNotification.fromPush(
        message.data,
        title: message.notification?.title,
        body: message.notification?.body,
        messageId: message.messageId,
        at: message.sentTime,
        read: read,
      );

  void _onLocalNotificationTap(NotificationResponse response) {
    unawaited(_handleNotificationResponse(response));
  }

  /// Tap local notification / action button (public để test).
  Future<void> handleNotificationResponse(NotificationResponse response) =>
      _handleNotificationResponse(response);

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final interaction = decodeNotificationInteraction(response.payload);
    if (interaction == null) {
      _onNavigate(NotificationTarget.inventory);
      return;
    }
    final data = interaction.data;
    final payload = FcmActionPayload.tryParse(data);
    final action = response.actionId;
    if (action == null || action.isEmpty) {
      _record(AppNotification.fromPush(
        data,
        title: interaction.title,
        body: interaction.body,
        messageId: interaction.messageId,
        read: true,
      ));
      _navigateFor(data);
      return;
    }
    if (action == 'COOK_TODAY') {
      final target = payload?.actions
          .where((item) => item.id == action)
          .firstOrNull
          ?.target;
      _openDeepLink(target, fallbackInventory: false);
      return;
    }
    if (action != 'MARK_USED' && action != 'DISCARD') return;
    final itemId = payload?.actionItemId;
    if (itemId == null || itemId.isEmpty) {
      _emit(const NotificationUiEvent(NotificationUiEventType.actionFailed));
      return;
    }
    await _applyQuickAction(
      itemId: itemId,
      action: action,
      notificationId: interaction.notificationId,
    );
  }

  Future<void> _applyQuickAction({
    required String itemId,
    required String action,
    required int notificationId,
  }) async {
    try {
      final result = await _quickActionApi.apply(
        itemId: itemId,
        action: action,
      );
      await _localNotifications.cancel(id: notificationId);
      if (result.applied) {
        await _onInventoryChanged();
        _emit(const NotificationUiEvent(
            NotificationUiEventType.inventoryUpdated));
        return;
      }
      final event = switch (result.transactionReason) {
        'COOKED' => NotificationUiEventType.inventoryAlreadyUsed,
        'WASTE' => NotificationUiEventType.inventoryAlreadyDiscarded,
        _ => NotificationUiEventType.inventoryAlreadyProcessed,
      };
      _emit(NotificationUiEvent(event));
    } on NetworkException {
      _emit(const NotificationUiEvent(NotificationUiEventType.noNetwork));
    } on BusinessException catch (error) {
      if (error.code == 'ERR_INVENTORY_NOT_FOUND') {
        await _localNotifications.cancel(id: notificationId);
        _emit(const NotificationUiEvent(NotificationUiEventType.inventoryGone));
      } else if (error.code == 'ERR_INVENTORY_READONLY_ROLE') {
        _emit(const NotificationUiEvent(
            NotificationUiEventType.inventoryReadonly));
      } else if (error.code == 'ERR_INVENTORY_NO_HOUSEHOLD') {
        _onNavigate(NotificationTarget.inventory);
      } else {
        _emit(const NotificationUiEvent(NotificationUiEventType.actionFailed));
      }
    } on ApiException {
      _emit(const NotificationUiEvent(NotificationUiEventType.actionFailed));
    }
  }

  void _openDeepLink(String? value, {bool fallbackInventory = true}) {
    final target = targetForDeepLink(value);
    if (target != null) {
      _onNavigate(target);
    } else if (fallbackInventory) {
      developer.log('Unknown notification deep-link: $value', name: 'FCM');
      _onNavigate(NotificationTarget.inventory);
    }
  }

  void _emit(NotificationUiEvent event) {
    if (_uiAttached) {
      _uiEventController.add(event);
    } else {
      _pendingUiEvents.add(event);
    }
  }
}

int _notificationId(RemoteMessage message) =>
    (message.messageId ?? jsonEncode(message.data)).hashCode & 0x7fffffff;

/// Payload local mang thêm `messageId`/`title`/`body` để tap dựng lại đúng
/// `AppNotification` và bỏ trùng theo `messageId` (§14.2). Isolate nền
/// (quick-action) dùng chung để giữ nguyên payload qua mọi lần cập nhật (A6).
String encodeNotificationInteraction(
  Map<String, dynamic> data,
  int notificationId, {
  String? messageId,
  String? title,
  String? body,
}) =>
    jsonEncode(<String, dynamic>{
      'notificationId': notificationId,
      'data': data,
      if (messageId != null) 'messageId': messageId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
    });

NotificationInteraction? decodeNotificationInteraction(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final value = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return NotificationInteraction(
      notificationId: (value['notificationId'] as num).toInt(),
      data: Map<String, dynamic>.from(value['data'] as Map),
      messageId: value['messageId'] as String?,
      title: value['title'] as String?,
      body: value['body'] as String?,
    );
  } catch (_) {
    return null;
  }
}

class NotificationInteraction {
  const NotificationInteraction({
    required this.notificationId,
    required this.data,
    this.messageId,
    this.title,
    this.body,
  });

  final int notificationId;
  final Map<String, dynamic> data;
  final String? messageId;
  final String? title;
  final String? body;
}
