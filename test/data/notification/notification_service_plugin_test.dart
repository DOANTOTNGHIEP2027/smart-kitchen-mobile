import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_prefs.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_service.dart';
import 'package:smart_kitchen_mobile/data/notification/quick_action_api.dart';

import '../../helpers/secure_storage_channel.dart';

class _FakeQuickActionApi implements QuickActionApi {
  Object? error;
  InventoryQuickActionResult result = const InventoryQuickActionResult(
      itemId: 'i1', itemName: 'Sữa', action: 'MARK_USED', applied: true);
  final List<(String, String)> calls = <(String, String)>[];

  @override
  Future<InventoryQuickActionResult> apply({required String itemId, required String action}) async {
    calls.add((itemId, action));
    if (error != null) throw error!;
    return result;
  }
}

/// Nhánh gọi plugin local notification + quick-action (kênh plugin được giả
/// lập) — fcm-notification-flow.md §5, inventory-management.md §20.3.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];

  late _FakeQuickActionApi quick;
  late List<NotificationTarget> targets;
  late List<NotificationUiEventType> events;
  late int inventoryChanged;
  late NotificationService service;

  setUp(() {
    // Test không chạy GeneratedPluginRegistrant → đăng ký bản Android tay.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => true,
        'getNotificationAppLaunchDetails' => null,
        _ => null,
      };
    });
    quick = _FakeQuickActionApi();
    targets = <NotificationTarget>[];
    events = <NotificationUiEventType>[];
    inventoryChanged = 0;
    service = NotificationService(
      quickActionApi: quick,
      onInventoryChanged: () async => inventoryChanged++,
      onNavigate: targets.add,
      firebaseAvailable: false,
    );
    service.uiEvents.listen((e) => events.add(e.type));
    service.attachUi();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  NotificationResponse action(String id) => NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: id,
        payload: jsonEncode(<String, dynamic>{
          'notificationId': 5,
          'data': <String, dynamic>{
            'type': 'INVENTORY_EXPIRY_ALERT',
            'actionsSchemaVersion': '1',
            'actionItemId': 'i1',
            'actions': jsonEncode(<Map<String, String>>[
              <String, String>{'id': 'MARK_USED', 'label': 'Đã dùng', 'type': 'API_CALL'},
            ]),
          },
        }),
      );

  Future<void> flush() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('init: khởi tạo plugin local (không xin quyền FCM — Guard 1)', () async {
    await service.init();
    expect(calls.map((c) => c.method), contains('initialize'));
    expect(calls.map((c) => c.method).where((m) => m.contains('requestPermission')), isEmpty);
  });

  test('foreground có notification block → hiện local notification kèm messageId', () async {
    final received = <AppNotification>[];
    service.attachSink(received.add);
    await service.handleForegroundMessage(const RemoteMessage(
      messageId: 'm1',
      data: <String, dynamic>{'type': 'SHOPPING_REMINDER'},
      notification: RemoteNotification(title: 'Nhắc mua', body: 'Còn 2 món'),
    ));
    final show = calls.singleWhere((c) => c.method == 'show');
    final payload = jsonDecode((show.arguments as Map)['payload'] as String) as Map;
    expect(payload['messageId'], 'm1');
    expect(payload['title'], 'Nhắc mua');
    expect(received.single.title, 'Nhắc mua');
  });

  test('quick-action thành công → huỷ notification + đồng bộ kho + toast cập nhật', () async {
    await service.handleNotificationResponse(action('MARK_USED'));
    await flush();
    expect(quick.calls, <(String, String)>[('i1', 'MARK_USED')]);
    expect(calls.map((c) => c.method), contains('cancel'));
    expect(inventoryChanged, 1);
    expect(events, <NotificationUiEventType>[NotificationUiEventType.inventoryUpdated]);
  });

  test('quick-action không áp dụng (đã nấu / đã bỏ / khác) → toast tương ứng', () async {
    for (final (reason, expected) in <(String?, NotificationUiEventType)>[
      ('COOKED', NotificationUiEventType.inventoryAlreadyUsed),
      ('WASTE', NotificationUiEventType.inventoryAlreadyDiscarded),
      (null, NotificationUiEventType.inventoryAlreadyProcessed),
    ]) {
      events.clear();
      quick.result = InventoryQuickActionResult(
          itemId: 'i1', itemName: 'Sữa', action: 'MARK_USED', applied: false, transactionReason: reason);
      await service.handleNotificationResponse(action('MARK_USED'));
      await flush();
      expect(events, <NotificationUiEventType>[expected], reason: '$reason');
    }
  });

  test('quick-action lỗi → toast / điều hướng đúng', () async {
    final cases = <(Object, NotificationUiEventType?)>[
      (NetworkException(), NotificationUiEventType.noNetwork),
      (BusinessException('ERR_INVENTORY_NOT_FOUND', 'x'), NotificationUiEventType.inventoryGone),
      (BusinessException('ERR_INVENTORY_READONLY_ROLE', 'x'), NotificationUiEventType.inventoryReadonly),
      (BusinessException('ERR_OTHER', 'x'), NotificationUiEventType.actionFailed),
      (ServerException('ERR_UNKNOWN', 'x'), NotificationUiEventType.actionFailed),
      (BusinessException('ERR_INVENTORY_NO_HOUSEHOLD', 'x'), null),
    ];
    for (final (error, expected) in cases) {
      events.clear();
      targets.clear();
      quick.error = error;
      await service.handleNotificationResponse(action('DISCARD'));
      await flush();
      if (expected == null) {
        expect(targets, <NotificationTarget>[NotificationTarget.inventory]);
      } else {
        expect(events, <NotificationUiEventType>[expected], reason: '$error');
      }
    }
  });

  test('action thiếu actionItemId → actionFailed; action lạ → bỏ qua', () async {
    await service.handleNotificationResponse(NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotificationAction,
      actionId: 'MARK_USED',
      payload: jsonEncode(<String, dynamic>{'notificationId': 1, 'data': <String, dynamic>{'type': 'X'}}),
    ));
    await service.handleNotificationResponse(NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotificationAction,
      actionId: 'SOMETHING',
      payload: jsonEncode(<String, dynamic>{'notificationId': 1, 'data': <String, dynamic>{}}),
    ));
    expect(events, <NotificationUiEventType>[NotificationUiEventType.actionFailed]);
    expect(quick.calls, isEmpty);
  });

  test('UI chưa attach → event được giữ lại rồi trả khi attach', () async {
    final late = NotificationService(
      quickActionApi: quick,
      onInventoryChanged: () async {},
      onNavigate: (_) {},
      firebaseAvailable: false,
    );
    quick.error = NetworkException();
    await late.handleNotificationResponse(action('MARK_USED'));
    await flush();
    expect(late.attachUi().map((e) => e.type), <NotificationUiEventType>[NotificationUiEventType.noNetwork]);
    await late.dispose();
  });

  group('SecureNotificationPrefs', () {
    final storage = FakeSecureStorageChannel();
    setUp(storage.install);
    tearDown(storage.uninstall);

    test('mặc định chưa hỏi; đánh dấu thì nhớ', () async {
      final prefs = SecureNotificationPrefs();
      expect(await prefs.hasAskedPermission(), isFalse);
      await prefs.markPermissionAsked();
      expect(await prefs.hasAskedPermission(), isTrue);
    });
  });
}
