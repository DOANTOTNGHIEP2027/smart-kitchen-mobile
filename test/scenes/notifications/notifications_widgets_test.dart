import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';
import 'package:smart_kitchen_mobile/data/notification/push_gateway.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/inventory_routes.dart';
import 'package:smart_kitchen_mobile/scenes/notifications/notifications_routes.dart';
import 'package:smart_kitchen_mobile/scenes/notifications/notifications_scene.dart';
import 'package:smart_kitchen_mobile/scenes/notifications/shell_notification_host.dart';
import 'package:smart_kitchen_mobile/stores/notification_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../data/notification/notification_fakes.dart';

void main() {
  late FakePushGateway gateway;
  late FakeDeviceApi deviceApi;
  late FakeNotificationPrefs prefs;
  late SessionStore session;
  late NotificationStore store;

  setUp(() async {
    gateway = FakePushGateway();
    deviceApi = FakeDeviceApi();
    prefs = FakeNotificationPrefs();
    session = newSession();
    store = NotificationStore(gateway: gateway, deviceApi: deviceApi, prefs: prefs, session: session);
    Get.put<NotificationStore>(store);
  });

  tearDown(() {
    store.dispose();
    Get.reset();
  });

  Future<void> pumpApp(WidgetTester tester, {String initial = '/shell'}) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: initial,
      getPages: <GetPage<dynamic>>[
        GetPage<void>(
          name: '/shell',
          page: () => const ShellNotificationHost(child: Scaffold(body: Text('SHELL'))),
        ),
        GetPage<void>(name: NotificationsRoutes.list, page: () => const NotificationsScene()),
        GetPage<void>(name: InventoryRoutes.list, page: () => const Text('INVENTORY')),
        GetPage<void>(name: AppRoutes.shopping, page: () => const Text('SHOPPING')),
        GetPage<void>(name: AppRoutes.family, page: () => const Text('FAMILY')),
      ],
    ));
    await tester.pumpAndSettle();
  }

  group('ShellNotificationHost', () {
    testWidgets('sau đăng nhập đầu → sheet; "Bật thông báo" → xin quyền + đăng ký', (tester) async {
      await signIn(session);
      await store.init();
      await pumpApp(tester);
      expect(find.text('Nhận nhắc hạn dùng thực phẩm, lịch mua sắm và bữa ăn đã lên kế hoạch.'),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notification-permission-enable')));
      await tester.pumpAndSettle();
      expect(gateway.requestCalls, 1);
      expect(prefs.asked, isTrue);
      expect(deviceApi.registered, <String>['token-1']);
    });

    testWidgets('"Để sau" → đặt cờ, không gọi dialog; dựng lại không hiện nữa', (tester) async {
      await signIn(session);
      await store.init();
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('notification-permission-later')));
      await tester.pumpAndSettle();
      expect(gateway.requestCalls, 0);
      expect(prefs.asked, isTrue);
      await pumpApp(tester);
      expect(find.byKey(const ValueKey('notification-permission-later')), findsNothing);
    });

    testWidgets('vuốt/chạm ngoài để đóng sheet = "Để sau"', (tester) async {
      await signIn(session);
      await store.init();
      await pumpApp(tester);
      expect(find.byType(NotificationPermissionSheet), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // chạm vùng barrier
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPermissionSheet), findsNothing);
      expect(gateway.requestCalls, 0);
      expect(prefs.asked, isTrue);
    });

    testWidgets('sheet bị gỡ cùng shell (offAllNamed login) → KHÔNG đặt cờ (L1)', (tester) async {
      await signIn(session);
      await store.init();
      await pumpApp(tester);
      expect(find.byType(NotificationPermissionSheet), findsOneWidget);
      Get.offAllNamed<void>(AppRoutes.shopping);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPermissionSheet), findsNothing);
      expect(prefs.asked, isFalse);
    });

    testWidgets('pendingTarget (cold start) chỉ điều hướng khi shell đã lên, đúng 1 lần', (tester) async {
      prefs.asked = true;
      await store.init();
      store.navigateTo(NotificationTarget.shopping);
      await pumpApp(tester);
      expect(find.text('SHOPPING'), findsOneWidget);
      expect(store.pendingTarget, isNull);

      Get.back<void>();
      await tester.pumpAndSettle();
      store.navigateTo(NotificationTarget.inventory);
      await tester.pumpAndSettle();
      expect(find.text('INVENTORY'), findsOneWidget);
    });
  });

  group('NotificationsScene', () {
    testWidgets('trống + banner chưa bật → bấm "Bật thông báo"', (tester) async {
      await store.init();
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('Chưa có thông báo nào.'), findsOneWidget);
      expect(find.byKey(const ValueKey('notifications-permission-notDetermined')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notifications-permission-action')));
      await tester.pumpAndSettle();
      expect(gateway.requestCalls, 1);
      expect(find.byKey(const ValueKey('notifications-permission-notDetermined')), findsNothing);
    });

    testWidgets('danh sách: tap → đánh dấu đọc + điều hướng theo target', (tester) async {
      gateway.current = NotificationPermissionStatus.granted;
      await store.init();
      store
        ..addNotification(AppNotification.fromPush(
            <String, dynamic>{'type': 'INVENTORY_EXPIRY_ALERT'},
            title: '3 thực phẩm sắp hết hạn', messageId: 'a'))
        ..addNotification(AppNotification.fromPush(
            <String, dynamic>{'type': 'SHOPPING_REMINDER', 'body': 'Còn 4 món'},
            title: 'Nhắc mua sắm', messageId: 'b'));
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('Nhắc mua sắm'), findsOneWidget);
      expect(find.text('Còn 4 món'), findsOneWidget);
      expect(find.text('Vừa xong'), findsNWidgets(2));
      await tester.tap(find.text('Nhắc mua sắm'));
      await tester.pumpAndSettle();
      expect(find.text('SHOPPING'), findsOneWidget);
      expect(store.unreadCount, 1);
    });

    testWidgets('đánh dấu tất cả đã đọc', (tester) async {
      await store.init();
      store.addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'a'));
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('Thông báo mới'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notifications-mark-all-read')));
      await tester.pump();
      expect(store.unreadCount, 0);
    });

    testWidgets('banner theo trạng thái: permanentlyDenied → Mở Cài đặt; unsupported không có nút; granted ẩn',
        (tester) async {
      gateway.current = NotificationPermissionStatus.permanentlyDenied;
      await store.init();
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('Mở Cài đặt'), findsOneWidget);

      gateway.current = NotificationPermissionStatus.granted;
      await store.refreshPermission();
      await tester.pump();
      expect(find.byKey(const ValueKey('notifications-permission-action')), findsNothing);
    });

    testWidgets('denied → xin lại; vẫn denied → mở Cài đặt, permanentlyDenied → không', (tester) async {
      gateway
        ..current = NotificationPermissionStatus.denied
        ..onRequest = NotificationPermissionStatus.denied;
      await store.init();
      var opened = 0;
      Future<bool> openSettings() async {
        opened++;
        return true;
      }

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NotificationPermissionBanner(store: store, openSettings: openSettings)),
      ));
      await tester.tap(find.byKey(const ValueKey('notifications-permission-action')));
      await tester.pumpAndSettle();
      expect(gateway.requestCalls, 1);
      expect(opened, 1);

      // Người dùng vừa bấm "Không cho phép" lần nữa → permanentlyDenied:
      // không đẩy ngay vào Cài đặt.
      gateway
        ..current = NotificationPermissionStatus.denied
        ..onRequest = NotificationPermissionStatus.permanentlyDenied;
      await store.refreshPermission();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('notifications-permission-action')));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.text('Mở Cài đặt'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notifications-permission-action')));
      await tester.pump();
      expect(opened, 2);
    });

    testWidgets('đăng ký token lỗi → banner lỗi trên /notifications', (tester) async {
      gateway.current = NotificationPermissionStatus.granted;
      deviceApi.error = ServerException('ERR_INTERNAL', 'x');
      await signIn(session);
      await store.init();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(store.registrationError, isNotNull);
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.byKey(const ValueKey('notifications-registration-error')), findsOneWidget);
    });

    testWidgets('unsupported → banner không có nút', (tester) async {
      gateway.supported = false;
      await store.init();
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('Thông báo chưa khả dụng trên thiết bị này'), findsOneWidget);
      expect(find.byKey(const ValueKey('notifications-permission-action')), findsNothing);
    });

    testWidgets('relativeTime', (tester) async {
      await pumpApp(tester, initial: NotificationsRoutes.list);
      final ctx = tester.element(find.byType(NotificationsScene));
      final now = DateTime(2026, 11, 25, 12);
      expect(relativeTime(ctx, now.subtract(const Duration(seconds: 30)), now: now), 'Vừa xong');
      expect(relativeTime(ctx, now.subtract(const Duration(minutes: 5)), now: now), '5 phút trước');
      expect(relativeTime(ctx, now.subtract(const Duration(hours: 3)), now: now), '3 giờ trước');
    });
  });

  group('NotificationsScene — hộp thư server (#201)', () {
    late FakeNotificationApi api;

    Future<void> useApi(List<AppNotification> items, {Object? listError}) async {
      store.dispose();
      Get.delete<NotificationStore>();
      api = FakeNotificationApi(items: items, size: 20)..listError = listError;
      store = NotificationStore(
          gateway: gateway..current = NotificationPermissionStatus.granted,
          deviceApi: deviceApi,
          prefs: prefs,
          session: session,
          api: api);
      Get.put<NotificationStore>(store);
      await signIn(session);
      await store.init();
    }

    testWidgets('mở màn → tải từ API; chưa đọc có chấm, đã đọc không', (tester) async {
      await useApi(<AppNotification>[
        serverNotification('s1', type: 'HOUSEHOLD_MEMBER_JOINED'),
        serverNotification('s2', read: true),
      ]);
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('T-s1'), findsOneWidget);
      expect(find.text('T-s2'), findsOneWidget);
      expect(find.byKey(const ValueKey('notification-unread-s1')), findsOneWidget);
      expect(find.byKey(const ValueKey('notification-unread-s2')), findsNothing);
      expect(api.listedPages, isNotEmpty);
    });

    testWidgets('tap HOUSEHOLD_MEMBER_* → màn thành viên + POST đã đọc', (tester) async {
      await useApi(<AppNotification>[serverNotification('s1', type: 'HOUSEHOLD_MEMBER_JOINED')]);
      await pumpApp(tester, initial: NotificationsRoutes.list);
      await tester.tap(find.text('T-s1'));
      await tester.pumpAndSettle();
      expect(find.text('FAMILY'), findsOneWidget);
      expect(api.markedRead, <String>['s1']);
      expect(store.unreadCount, 0);
    });

    testWidgets('lỗi tải lần đầu → màn lỗi + Thử lại → danh sách', (tester) async {
      await useApi(<AppNotification>[serverNotification('s1')], listError: NetworkException());
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      api.listError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('T-s1'), findsOneWidget);
    });

    testWidgets('"Đánh dấu đã đọc tất cả" gọi API, tắt nút khi hết chưa đọc', (tester) async {
      await useApi(<AppNotification>[serverNotification('s1'), serverNotification('s2')]);
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('Đánh dấu đã đọc tất cả'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notifications-mark-all-read')));
      await tester.pumpAndSettle();
      expect(api.markAllCalls, 1);
      expect(find.byKey(const ValueKey('notification-unread-s1')), findsNothing);
      final button = tester.widget<TextButton>(find.byKey(const ValueKey('notifications-mark-all-read')));
      expect(button.onPressed, isNull);
    });

    testWidgets('cuộn tới cuối → tải trang kế (footer)', (tester) async {
      await useApi(<AppNotification>[for (var i = 0; i < 25; i++) serverNotification('s$i')]);
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(store.notifications, hasLength(20));
      await tester.scrollUntilVisible(find.text('T-s24'), 300,
          scrollable: find.descendant(
              of: find.byKey(const ValueKey('notifications-list')), matching: find.byType(Scrollable)));
      await tester.pumpAndSettle();
      expect(store.notifications, hasLength(25));
      expect(store.hasMore, isFalse);
      expect(api.listedPages.where((p) => p == 1), hasLength(1));
    });

    testWidgets('trống từ API → empty view', (tester) async {
      await useApi(<AppNotification>[]);
      await pumpApp(tester, initial: NotificationsRoutes.list);
      expect(find.text('Chưa có thông báo nào.'), findsOneWidget);
    });
  });
}
