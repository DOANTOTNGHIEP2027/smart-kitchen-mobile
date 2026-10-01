import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_exception.dart';
import 'device_api.dart';
import 'fcm_action_payload.dart';
import 'quick_action_api.dart';
import '../../l10n/app_localizations.dart';

const String inventoryExpiryCategory = 'SK_INVENTORY_EXPIRY_V1';

enum NotificationUiEventType {
  openInventory,
  openMealPlan,
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
  );
}

Future<void> _showInventoryNotification(
  FcmActionPayload payload, {
  required int notificationId,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  const channel = AndroidNotificationChannel(
    'smart_kitchen_inventory_alerts',
    'Inventory alerts',
    description: 'Expiry and low-stock inventory alerts',
    importance: Importance.high,
  );
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(channel);
  await plugin.show(
    id: notificationId,
    title: payload.title,
    body: payload.body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        actions: payload.actions
            .map((action) => AndroidNotificationAction(
                  action.id,
                  action.label,
                  showsUserInterface: true,
                  cancelNotification: false,
                ))
            .toList(growable: false),
      ),
    ),
    payload: _encodeInteraction(payload.data, notificationId),
  );
}

class NotificationService {
  NotificationService({
    required DeviceApi deviceApi,
    required QuickActionApi quickActionApi,
    required bool Function() isAuthenticated,
    required Future<void> Function() onInventoryChanged,
  })  : _deviceApi = deviceApi,
        _quickActionApi = quickActionApi,
        _isAuthenticated = isAuthenticated,
        _onInventoryChanged = onInventoryChanged;

  final DeviceApi _deviceApi;
  final QuickActionApi _quickActionApi;
  final bool Function() _isAuthenticated;
  final Future<void> Function() _onInventoryChanged;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _messageController = StreamController<RemoteMessage>.broadcast();
  final _uiEventController = StreamController<NotificationUiEvent>.broadcast();
  final List<NotificationUiEvent> _pendingUiEvents = <NotificationUiEvent>[];

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  String? _pendingToken;
  bool _uiAttached = false;

  Stream<RemoteMessage> get onMessage => _messageController.stream;
  Stream<NotificationUiEvent> get uiEvents => _uiEventController.stream;

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

  Future<void> init({bool tryInit = true}) async {
    try {
      await _initLocalNotifications();
      await _requestPermission();
      await _setupFcm();
    } catch (error) {
      developer.log(
        'NotificationService init failed: $error',
        name: 'FCM',
      );
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _messageController.close();
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
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);

    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      unawaited(_handleNotificationResponse(response));
    }
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
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerTokenIfAuthenticated(token);
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerTokenIfAuthenticated,
    );
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleOpened(initial);
  }

  Future<void> onAuthChanged() async {
    if (!_isAuthenticated()) return;
    final token = _pendingToken ?? await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerTokenIfAuthenticated(token);
  }

  Future<void> _registerTokenIfAuthenticated(String token) async {
    _pendingToken = token;
    if (!_isAuthenticated()) return;
    try {
      await _deviceApi.registerDevice(fcmToken: token);
      _pendingToken = null;
    } catch (error) {
      developer.log('FCM token registration failed: $error', name: 'FCM');
    }
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    _messageController.add(message);
    final payload = FcmActionPayload.tryParse(message.data);
    if (payload?.renderLocally == true) {
      await _showInventoryNotification(
        payload!,
        notificationId: _notificationId(message),
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
      payload: _encodeInteraction(message.data, _notificationId(message)),
    );
  }

  void _handleOpened(RemoteMessage message) {
    _messageController.add(message);
    _openDeepLink(FcmActionPayload.tryParse(message.data)?.deepLink);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    unawaited(_handleNotificationResponse(response));
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final interaction = _decodeInteraction(response.payload);
    if (interaction == null) {
      _emit(const NotificationUiEvent(NotificationUiEventType.openInventory));
      return;
    }
    final data = interaction.data;
    final payload = FcmActionPayload.tryParse(data);
    final action = response.actionId;
    if (action == null || action.isEmpty) {
      _openDeepLink(payload?.deepLink);
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
        _emit(const NotificationUiEvent(NotificationUiEventType.openInventory));
      } else {
        _emit(const NotificationUiEvent(NotificationUiEventType.actionFailed));
      }
    } on ApiException {
      _emit(const NotificationUiEvent(NotificationUiEventType.actionFailed));
    }
  }

  void _openDeepLink(String? value, {bool fallbackInventory = true}) {
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri?.scheme == 'smartkitchen' && uri?.host == 'meal-plan') {
      _emit(const NotificationUiEvent(NotificationUiEventType.openMealPlan));
    } else if (uri?.scheme == 'smartkitchen' && uri?.host == 'inventory') {
      _emit(const NotificationUiEvent(NotificationUiEventType.openInventory));
    } else if (fallbackInventory) {
      developer.log('Unknown notification deep-link: $value', name: 'FCM');
      _emit(const NotificationUiEvent(NotificationUiEventType.openInventory));
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

String _encodeInteraction(Map<String, dynamic> data, int notificationId) =>
    jsonEncode(<String, dynamic>{
      'notificationId': notificationId,
      'data': data,
    });

_NotificationInteraction? _decodeInteraction(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final value = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return _NotificationInteraction(
      notificationId: (value['notificationId'] as num).toInt(),
      data: Map<String, dynamic>.from(value['data'] as Map),
    );
  } catch (_) {
    return null;
  }
}

class _NotificationInteraction {
  const _NotificationInteraction({
    required this.notificationId,
    required this.data,
  });

  final int notificationId;
  final Map<String, dynamic> data;
}
