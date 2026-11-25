import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_service.dart';
import 'package:smart_kitchen_mobile/data/notification/quick_action_api.dart';

class _NoopQuickActionApi implements QuickActionApi {
  @override
  Future<InventoryQuickActionResult> apply({required String itemId, required String action}) =>
      throw UnimplementedError();
}

void main() {
  late List<NotificationTarget> targets;
  late List<AppNotification> received;
  late NotificationService service;

  setUp(() {
    targets = <NotificationTarget>[];
    received = <AppNotification>[];
    service = NotificationService(
      quickActionApi: _NoopQuickActionApi(),
      onInventoryChanged: () async {},
      onNavigate: targets.add,
      firebaseAvailable: false,
    );
  });

  NotificationResponse tap(Map<String, dynamic>? payload, {String? actionId}) =>
      NotificationResponse(
        notificationResponseType: actionId == null
            ? NotificationResponseType.selectedNotification
            : NotificationResponseType.selectedNotificationAction,
        actionId: actionId,
        payload: payload == null ? null : jsonEncode(payload),
      );

  test('cold start: thông báo đến TRƯỚC khi gắn sink được buffer rồi đẩy khi gắn', () {
    service.handleOpenedMessage(const RemoteMessage(
      messageId: 'm1',
      data: <String, dynamic>{'type': 'SHOPPING_REMINDER', 'title': 'Nhắc mua'},
    ));
    expect(received, isEmpty);
    service.attachSink(received.add);
    expect(received.single.id, 'm1');
    expect(received.single.read, isTrue, reason: 'đã mở = đã đọc');
    expect(targets, <NotificationTarget>[NotificationTarget.shopping]);
  });

  test('foreground không có notification block → ghi vào danh sách, chưa đọc', () async {
    service.attachSink(received.add);
    await service.handleForegroundMessage(const RemoteMessage(
      messageId: 'f1',
      data: <String, dynamic>{'type': 'INVENTORY_LOW_STOCK_ALERT', 'title': 'Sắp hết', 'body': 'Còn 1 hộp sữa'},
    ));
    expect(received.single.title, 'Sắp hết');
    expect(received.single.read, isFalse);
    expect(targets, isEmpty, reason: 'foreground không tự điều hướng');
  });

  test('type lạ khi mở → /notifications (không dùng chuỗi trong payload)', () {
    service.attachSink(received.add);
    service.handleOpenedMessage(const RemoteMessage(
      data: <String, dynamic>{'type': 'NEW_FEATURE', 'route': '/admin'},
    ));
    expect(targets, <NotificationTarget>[NotificationTarget.notifications]);
  });

  test('tap local: dựng lại từ payload (messageId/title/body) + điều hướng theo type', () async {
    service.attachSink(received.add);
    await service.handleNotificationResponse(tap(<String, dynamic>{
      'notificationId': 7,
      'data': <String, dynamic>{'type': 'SHOPPING_ASSIGNED_REMINDER'},
      'messageId': 'm9',
      'title': 'Bạn được giao mua',
      'body': '2 món',
    }));
    expect(received.single.id, 'm9');
    expect(received.single.title, 'Bạn được giao mua');
    expect(targets, <NotificationTarget>[NotificationTarget.shopping]);
  });

  test('tap local payload hỏng → inventory (giữ hành vi cũ)', () async {
    await service.handleNotificationResponse(tap(null));
    expect(targets, <NotificationTarget>[NotificationTarget.inventory]);
  });

  test('action COOK_TODAY → meal plan qua allow-list', () async {
    await service.handleNotificationResponse(tap(<String, dynamic>{
      'notificationId': 1,
      'data': <String, dynamic>{
        'type': 'INVENTORY_EXPIRY_ALERT',
        'actionsSchemaVersion': '1',
        'actions': jsonEncode(<Map<String, String>>[
          <String, String>{
            'id': 'COOK_TODAY',
            'label': 'Nấu hôm nay',
            'type': 'DEEP_LINK',
            'target': 'smartkitchen://meal-plan?source=expiry-alert',
          },
        ]),
      },
    }, actionId: 'COOK_TODAY'));
    expect(targets, <NotificationTarget>[NotificationTarget.mealPlan]);
  });

  test('web/thiếu Firebase: init không ném', () async {
    await service.init();
  });
}
