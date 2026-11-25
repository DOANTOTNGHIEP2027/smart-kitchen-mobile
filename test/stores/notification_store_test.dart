import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';
import 'package:smart_kitchen_mobile/data/notification/push_gateway.dart';
import 'package:smart_kitchen_mobile/stores/notification_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../data/notification/notification_fakes.dart';

Future<void> settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakePushGateway gateway;
  late FakeDeviceApi deviceApi;
  late FakeNotificationPrefs prefs;
  late SessionStore session;
  late NotificationStore store;

  NotificationStore build() => store = NotificationStore(
        gateway: gateway,
        deviceApi: deviceApi,
        prefs: prefs,
        session: session,
      );

  setUp(() {
    gateway = FakePushGateway();
    deviceApi = FakeDeviceApi();
    prefs = FakeNotificationPrefs();
    session = newSession();
  });

  tearDown(() => store.dispose());

  group('init', () {
    test('web / thiếu Firebase → unsupported, không hỏi, không sheet', () async {
      gateway.supported = false;
      await signIn(session);
      await build().init();
      expect(store.permissionStatus, NotificationPermissionStatus.unsupported);
      expect(store.shouldShowRationale, isFalse);
      expect(gateway.currentCalls, 0);
    });

    test('KHÔNG xin quyền ở init (Guard 1); đọc quyền + cờ hiện tại', () async {
      gateway.current = NotificationPermissionStatus.denied;
      prefs.asked = true;
      await build().init();
      expect(gateway.requestCalls, 0);
      expect(store.permissionStatus, NotificationPermissionStatus.denied);
      expect(store.hasAskedPermission, isTrue);
    });

    test('trước khi init xong thì không hiện sheet', () async {
      await signIn(session);
      build();
      expect(store.shouldShowRationale, isFalse);
    });
  });

  group('sheet xin quyền (một lần sau đăng nhập)', () {
    test('chưa đăng nhập → không hiện; đăng nhập → hiện', () async {
      await build().init();
      expect(store.shouldShowRationale, isFalse);
      await signIn(session);
      expect(store.shouldShowRationale, isTrue);
    });

    test('đã hỏi trước đó (cờ) → không hiện', () async {
      prefs.asked = true;
      await signIn(session);
      await build().init();
      expect(store.shouldShowRationale, isFalse);
    });

    test('quyền đã granted (Android < 13) → không hiện', () async {
      gateway.current = NotificationPermissionStatus.granted;
      await signIn(session);
      await build().init();
      expect(store.shouldShowRationale, isFalse);
    });

    test('đã hiện trong phiên → không hiện lần 2', () async {
      await signIn(session);
      await build().init();
      store.markRationaleShown();
      expect(store.shouldShowRationale, isFalse);
    });

    test('"Bật thông báo" → đặt cờ, granted, đăng ký token', () async {
      await signIn(session);
      await build().init();
      await settle();
      await store.requestPermission();
      await settle();
      expect(prefs.asked, isTrue);
      expect(store.permissionStatus, NotificationPermissionStatus.granted);
      expect(deviceApi.registered, <String>['token-1']);
      expect(store.fcmToken, 'token-1');
      expect(store.shouldShowRationale, isFalse);
    });

    test('từ chối → denied, không đăng ký', () async {
      gateway.onRequest = NotificationPermissionStatus.permanentlyDenied;
      await signIn(session);
      await build().init();
      await store.requestPermission();
      await settle();
      expect(store.permissionStatus, NotificationPermissionStatus.permanentlyDenied);
      expect(deviceApi.registered, isEmpty);
    });

    test('"Để sau" → đặt cờ, không gọi dialog', () async {
      await signIn(session);
      await build().init();
      await store.dismissRationale();
      expect(prefs.asked, isTrue);
      expect(gateway.requestCalls, 0);
      expect(store.shouldShowRationale, isFalse);
    });
  });

  group('token', () {
    test('cold start đã đăng nhập + granted → đăng ký', () async {
      gateway.current = NotificationPermissionStatus.granted;
      await signIn(session);
      await build().init();
      await settle();
      expect(deviceApi.registered, <String>['token-1']);
    });

    test('chưa có quyền → không đăng ký dù đã đăng nhập', () async {
      await signIn(session);
      await build().init();
      await settle();
      expect(deviceApi.registered, isEmpty);
    });

    test('granted rồi mới đăng nhập → đăng ký; onTokenRefresh → đăng ký lại', () async {
      gateway.current = NotificationPermissionStatus.granted;
      await build().init();
      await settle();
      expect(deviceApi.registered, isEmpty);
      await signIn(session);
      await settle();
      expect(deviceApi.registered, <String>['token-1']);
      gateway.refreshController.add('token-new');
      await settle();
      expect(deviceApi.registered, <String>['token-1', 'token-new']);
      expect(store.fcmToken, 'token-new');
    });

    test('đăng ký lỗi 401/500 → registrationError, không ném', () async {
      gateway.current = NotificationPermissionStatus.granted;
      deviceApi.error = ServerException('ERR_INTERNAL', 'boom');
      await signIn(session);
      await build().init();
      await settle();
      expect(store.registrationError, isA<ServerException>());
      deviceApi.error = AuthExpiredException('ERR_AUTH_001', 'expired');
      await store.refreshToken();
      expect(store.registrationError, isA<AuthExpiredException>());
      deviceApi.error = null;
      await store.refreshToken();
      expect(store.registrationError, isNull);
    });

    test('getToken lỗi không làm kẹt hàng đợi token', () async {
      gateway.current = NotificationPermissionStatus.granted;
      gateway.getTokenError = StateError('offline');
      await signIn(session);
      await build().init();
      await settle();
      gateway.getTokenError = null;
      await store.refreshToken();
      expect(deviceApi.registered, <String>['token-1']);
    });

    test('đăng xuất → deleteToken + xoá state; cold start chưa đăng nhập không xoá', () async {
      gateway.current = NotificationPermissionStatus.granted;
      await build().init();
      await settle();
      expect(gateway.deleteCalls, 0, reason: 'cold start chưa đăng nhập');

      await signIn(session);
      await settle();
      store
        ..addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'a'))
        ..navigateTo(NotificationTarget.shopping);
      await session.clear();
      await settle();
      expect(gateway.deleteCalls, 1);
      expect(store.fcmToken, isNull);
      expect(store.notifications, isEmpty);
      expect(store.pendingTarget, isNull);
    });

    test('đăng xuất: xoá state NGAY, không chờ deleteToken (mạng chậm) — M1', () async {
      gateway.current = NotificationPermissionStatus.granted;
      await signIn(session);
      await build().init();
      await settle();
      store
        ..addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'a'))
        ..navigateTo(NotificationTarget.shopping);
      gateway.holdDelete = Completer<void>();
      await session.clear();
      await settle();
      expect(gateway.deleteCalls, 1);
      expect(store.notifications, isEmpty);
      expect(store.unreadCount, 0);
      expect(store.pendingTarget, isNull);
      expect(store.fcmToken, isNull);

      // Người kế tiếp nhận thông báo trước khi deleteToken xong → không bị xoá.
      store.addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'b'));
      gateway.holdDelete!.complete();
      await settle();
      expect(store.notifications.single.id, 'b');
    });

    test('đăng ký đang chạy lúc đăng xuất → kết quả về muộn bị bỏ (N1)', () async {
      for (final fail in <bool>[false, true]) {
        gateway = FakePushGateway()..current = NotificationPermissionStatus.granted;
        deviceApi = FakeDeviceApi()..hold = Completer<void>();
        if (fail) deviceApi.error = ServerException('ERR_INTERNAL', 'x');
        session = newSession();
        await signIn(session);
        await build().init();
        await settle();
        await session.clear();
        await settle();
        deviceApi.hold!.complete();
        await settle();
        expect(store.fcmToken, isNull, reason: 'fail=$fail');
        expect(store.registrationError, isNull, reason: 'fail=$fail');
        store.dispose();
      }
    });

    test('logout rồi login ngay: deleteToken chạy xong trước getToken', () async {
      gateway.current = NotificationPermissionStatus.granted;
      await signIn(session);
      await build().init();
      await settle();
      gateway.log.clear();
      await session.clear();
      await signIn(session);
      await settle();
      expect(gateway.log, <String>['deleteToken', 'getToken']);
      expect(deviceApi.registered.last, 'token-2');
    });
  });

  group('resume', () {
    test('quyền bị tắt trong Cài đặt → denied', () async {
      gateway.current = NotificationPermissionStatus.granted;
      await build().init();
      gateway.current = NotificationPermissionStatus.denied;
      await store.refreshPermission();
      expect(store.permissionStatus, NotificationPermissionStatus.denied);
    });

    test('vừa được cấp quyền trong Cài đặt → đăng ký token', () async {
      gateway.current = NotificationPermissionStatus.denied;
      await signIn(session);
      await build().init();
      gateway.current = NotificationPermissionStatus.granted;
      await store.refreshPermission();
      await settle();
      expect(deviceApi.registered, <String>['token-1']);
    });

    test('resume trong lúc dialog quyền đang mở (isLoading) → bỏ qua', () async {
      await signIn(session);
      await build().init();
      final before = gateway.currentCalls;
      gateway.holdRequest = Completer<void>();
      final pending = store.requestPermission();
      await settle();
      expect(store.isLoading, isTrue);
      await store.refreshPermission();
      expect(gateway.currentCalls - before, 0);
      gateway.holdRequest!.complete();
      await pending;
      expect(store.isLoading, isFalse);
    });

    test('single-flight: 2 lần resume liên tiếp chỉ đọc 1 lần', () async {
      await build().init();
      final before = gateway.currentCalls;
      gateway.holdPermissionRead = Completer<void>();
      final a = store.refreshPermission();
      final b = store.refreshPermission();
      gateway.holdPermissionRead!.complete();
      await Future.wait(<Future<void>>[a, b]);
      expect(gateway.currentCalls - before, 1);
    });
  });

  group('danh sách trong phiên', () {
    test('mới nhất ở đầu; bỏ trùng id; trùng mà đã đọc → đánh dấu đọc', () async {
      await build().init();
      store
        ..addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'a'))
        ..addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'b'))
        ..addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'a'));
      expect(store.notifications.map((n) => n.id), <String>['b', 'a']);
      expect(store.unreadCount, 2);
      store.addNotification(
          AppNotification.fromPush(const <String, dynamic>{}, messageId: 'a', read: true));
      expect(store.unreadCount, 1);
      store.markAllRead();
      expect(store.unreadCount, 0);
    });

    test('giới hạn 50 mục', () async {
      await build().init();
      for (var i = 0; i < 60; i++) {
        store.addNotification(
            AppNotification.fromPush(const <String, dynamic>{}, messageId: 'm$i'));
      }
      expect(store.notifications, hasLength(NotificationStore.maxNotifications));
      expect(store.notifications.first.id, 'm59');
    });

    test('markRead + pendingTarget lấy-và-xoá', () async {
      await build().init();
      store.addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'x'));
      store.markRead('x');
      expect(store.unreadCount, 0);
      store.navigateTo(NotificationTarget.mealPlan);
      expect(store.consumePendingTarget(), NotificationTarget.mealPlan);
      expect(store.consumePendingTarget(), isNull);
    });
  });
}
