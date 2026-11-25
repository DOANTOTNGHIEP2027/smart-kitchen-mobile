import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/profile_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/stores/notification_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../data/notification/notification_fakes.dart';
import '../../helpers/secure_storage_channel.dart';

/// ProfileScreen — P1/P2/P3 (profile-family-screens.md §10.1). Không có
/// fetch: mọi dữ liệu đọc từ `SessionStore.currentUser`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late SessionStore session;

  setUp(() {
    storageChannel.install();
    Get.testMode = true;
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()));
    Get.put<SessionStore>(session);
    Get.put<ProfileStore>(ProfileStore(
        _UnusedHealthApi(), _UnusedProfileApi(), _UnusedCache(), session));
  });

  tearDown(() {
    Get.reset();
    storageChannel.uninstall();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: '/profile',
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/profile', page: () => const ProfileScreen()),
        GetPage<dynamic>(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('login-page'))),
      ],
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('#48 — tile Thông báo hiện badge số chưa đọc', (tester) async {
    session.currentUser = const UserSummary(id: 'u1', fullName: 'Nguyen A');
    final store = NotificationStore(
      gateway: FakePushGateway(),
      deviceApi: FakeDeviceApi(),
      prefs: FakeNotificationPrefs(),
      session: session,
    );
    Get.put<NotificationStore>(store);

    await pumpScreen(tester);
    expect(find.byKey(const ValueKey<String>('profile-notifications')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('profile-tile-badge')), findsNothing);

    store
      ..addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'a'))
      ..addNotification(AppNotification.fromPush(const <String, dynamic>{}, messageId: 'b'));
    await tester.pump();
    expect(find.text('2 chưa đọc'), findsOneWidget);

    store.markAllRead();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('profile-tile-badge')), findsNothing);
  });

  testWidgets('P1 — hiện tên, email, nút Chỉnh sửa, lối vào l10n',
      (tester) async {
    session.currentUser =
        const UserSummary(id: 'u1', fullName: 'Nguyen A', email: 'a@b.c');

    await pumpScreen(tester);

    expect(find.text('Nguyen A'), findsOneWidget);
    expect(find.text('a@b.c'), findsOneWidget);
    expect(find.text('N'), findsOneWidget); // chữ cái đầu (avatarUrl null)
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('Tổng kết tuần'), findsOneWidget);
    expect(find.text('Hoàn tất hồ sơ để duy trì quyền truy cập Nhà của bạn'),
        findsNothing);
  });

  testWidgets('P2 — GUEST: fullName/email null → "Thành viên" + banner email',
      (tester) async {
    session.currentUser = const UserSummary(id: 'g1');

    await pumpScreen(tester);

    expect(find.text('Thành viên'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.text('Chưa đặt email'), findsOneWidget);
    expect(find.text('Hoàn tất hồ sơ để duy trì quyền truy cập Nhà của bạn'),
        findsOneWidget);
  });

  testWidgets('P3 — không có session → "Đăng nhập lại" điều hướng /login',
      (tester) async {
    session.currentUser = null;

    await pumpScreen(tester);

    expect(find.text('Không thể tải hồ sơ'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập lại'));
    await tester.pumpAndSettle();
    expect(find.text('login-page'), findsOneWidget);
  });

  testWidgets('Guard 2 — updateCurrentUser → P1 tự cập nhật tên mới',
      (tester) async {
    session.currentUser =
        const UserSummary(id: 'u1', fullName: 'Tên cũ', email: 'a@b.c');
    await pumpScreen(tester);

    await tester.runAsync(() => session.updateCurrentUser(
        const UserSummary(id: 'u1', fullName: 'Tên mới', email: 'a@b.c')));
    await tester.pump();

    expect(find.text('Tên mới'), findsOneWidget);
    expect(find.text('Tên cũ'), findsNothing);
  });
}

class _UnusedHealthApi implements HealthApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedProfileApi implements ProfileApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedCache implements ReadCacheDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
