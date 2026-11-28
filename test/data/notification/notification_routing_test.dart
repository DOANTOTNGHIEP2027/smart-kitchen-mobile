import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/data/notification/device_api.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';
import 'package:smart_kitchen_mobile/data/notification/push_gateway.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveNotificationTarget (allow-list)', () {
    test('deepLink meal-plan / inventory', () {
      expect(resolveNotificationTarget(<String, dynamic>{'deepLink': 'smartkitchen://meal-plan'}),
          NotificationTarget.mealPlan);
      expect(resolveNotificationTarget(<String, dynamic>{'deepLink': 'smartkitchen://inventory?filter=EXPIRING'}),
          NotificationTarget.inventory);
    });

    test('type INVENTORY_* → inventory; SHOPPING_* → shopping', () {
      expect(resolveNotificationTarget(<String, dynamic>{'type': 'INVENTORY_LOW_STOCK_ALERT'}),
          NotificationTarget.inventory);
      expect(resolveNotificationTarget(<String, dynamic>{'type': 'SHOPPING_REMINDER'}),
          NotificationTarget.shopping);
      expect(resolveNotificationTarget(<String, dynamic>{'type': 'SHOPPING_ASSIGNED_REMINDER'}),
          NotificationTarget.shopping);
    });

    test('#201: SHOPPING_ASSIGNED → shopping; HOUSEHOLD_MEMBER_* → household; '
        'MEAL_ATTENDANCE_REMINDER → mealPlan', () {
      expect(resolveNotificationTarget(<String, dynamic>{'type': 'SHOPPING_ASSIGNED', 'itemId': 'i1'}),
          NotificationTarget.shopping);
      for (final type in <String>[
        'HOUSEHOLD_MEMBER_JOINED',
        'HOUSEHOLD_MEMBER_LEFT',
        'HOUSEHOLD_MEMBER_REMOVED',
        'HOUSEHOLD_MEMBER_ROLE_CHANGED',
      ]) {
        expect(resolveNotificationTarget(<String, dynamic>{'type': type}), NotificationTarget.household,
            reason: type);
      }
      expect(
          resolveNotificationTarget(
              <String, dynamic>{'type': 'MEAL_ATTENDANCE_REMINDER', 'planId': 'p1', 'slotId': 's1'}),
          NotificationTarget.mealPlan);
      expect(resolveNotificationTarget(<String, dynamic>{'type': 'INVENTORY_EXPIRY_ALERT'}),
          NotificationTarget.inventory);
    });

    test('type lạ / data rỗng / deepLink lạ → notifications (không dùng chuỗi payload)', () {
      expect(resolveNotificationTarget(const <String, dynamic>{}), NotificationTarget.notifications);
      expect(resolveNotificationTarget(<String, dynamic>{'type': 'WHATEVER', 'route': '/admin'}),
          NotificationTarget.notifications);
      expect(resolveNotificationTarget(<String, dynamic>{'deepLink': 'https://evil.example/x'}),
          NotificationTarget.notifications);
      expect(targetForDeepLink('smartkitchen://unknown'), isNull);
    });
  });

  group('AppNotification.fromPush', () {
    test('data-only: title/body lấy từ data; id = messageId', () {
      final n = AppNotification.fromPush(
        <String, dynamic>{'type': 'SHOPPING_REMINDER', 'title': 'Nhắc mua', 'body': 'Còn 3 món'},
        messageId: 'm1',
      );
      expect(n.id, 'm1');
      expect(n.title, 'Nhắc mua');
      expect(n.body, 'Còn 3 món');
      expect(n.target, NotificationTarget.shopping);
      expect(n.read, isFalse);
    });

    test('title từ notification thắng data; không có messageId → hash ổn định theo nội dung', () {
      final a = AppNotification.fromPush(<String, dynamic>{'b': '2', 'a': '1', 'title': 'x'}, title: 'T');
      final b = AppNotification.fromPush(<String, dynamic>{'a': '1', 'b': '2', 'title': 'x'});
      expect(a.title, 'T');
      expect(a.id, b.id, reason: 'thứ tự key không đổi id');
    });
  });

  test('mapAuthorizationStatus', () {
    expect(mapAuthorizationStatus(AuthorizationStatus.authorized), NotificationPermissionStatus.granted);
    expect(mapAuthorizationStatus(AuthorizationStatus.provisional), NotificationPermissionStatus.granted);
    expect(mapAuthorizationStatus(AuthorizationStatus.denied), NotificationPermissionStatus.denied);
    expect(mapAuthorizationStatus(AuthorizationStatus.deniedPermanently),
        NotificationPermissionStatus.permanentlyDenied);
    expect(mapAuthorizationStatus(AuthorizationStatus.notDetermined),
        NotificationPermissionStatus.notDetermined);
  });

  test('FirebasePushGateway không có Firebase → unsupported, không gọi plugin', () async {
    final gateway = FirebasePushGateway(firebaseAvailable: false);
    expect(gateway.isSupported, isFalse);
    expect(await gateway.currentPermission(), NotificationPermissionStatus.unsupported);
    expect(await gateway.requestPermission(), NotificationPermissionStatus.unsupported);
    expect(await gateway.getToken(), isNull);
    await gateway.deleteToken();
    expect(await gateway.onTokenRefresh.isEmpty, isTrue);
  });

  group('DeviceApi', () {
    final storage = FakeSecureStorageChannel();
    setUp(storage.install);
    tearDown(storage.uninstall);

    DeviceApiImpl api(FakeHttpAdapter adapter) {
      final client = DioClient.build(
          tokenStorage: TokenStorage(), dio: Dio(BaseOptions(baseUrl: 'https://test.local')));
      client.dio.httpClientAdapter = adapter;
      return DeviceApiImpl(client);
    }

    test('POST /api/v1/devices/register, body camelCase, 201', () async {
      final adapter = FakeHttpAdapter(
          (_) async => jsonResponse(201, successEnvelope(<String, dynamic>{'registered': true})));
      await api(adapter).registerDevice(fcmToken: 'tok');
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/api/v1/devices/register');
      expect(req.data, <String, dynamic>{'deviceToken': 'tok', 'platform': 'ANDROID'});
    });

    test('401 / 500 → ApiException (đã _unwrap)', () async {
      for (final status in <int>[401, 500]) {
        final adapter = FakeHttpAdapter(
            (_) async => jsonResponse(status, errorEnvelope('ERR_X', 'boom')));
        await expectLater(api(adapter).registerDevice(fcmToken: 'tok'),
            throwsA(isA<ApiException>()), reason: '$status');
      }
    });

    test('devicePlatformName', () {
      expect(devicePlatformName(TargetPlatform.iOS), 'IOS');
      expect(devicePlatformName(TargetPlatform.android), 'ANDROID');
    });
  });
}
