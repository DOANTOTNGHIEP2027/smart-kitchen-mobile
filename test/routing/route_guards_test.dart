import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/app/env_config.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/routing/app_pages.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/routing/route_guards.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late SessionStore store;

  setUp(() {
    storageChannel.install();
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) async => jsonResponse(200, successEnvelope(null)),
      );
    store = SessionStore(TokenStorage(), AuthRefreshUseCase(dio));
    Get.put<SessionStore>(store, permanent: true);
  });

  tearDown(() {
    storageChannel.uninstall();
    Get.reset();
  });

  group('AuthGuard', () {
    test('unauthenticated → redirect sang login', () async {
      await store.clear();

      expect(AuthGuard().redirect(AppRoutes.shellRoot)?.name, AppRoutes.login);
    });

    test('authenticated → cho qua', () async {
      await store.setSession(
        accessToken: fakeJwt(<String, dynamic>{'role': 'OWNER'}),
        refreshToken: 'r1',
        user: const UserSummary(id: 'u1'),
      );

      expect(AuthGuard().redirect(AppRoutes.shellRoot), isNull);
    });

    test('status unknown → CHẶN (không có access token nào ở trạng thái này)',
        () {
      expect(store.status, AuthStatus.unknown);

      expect(AuthGuard().redirect(AppRoutes.shellRoot)?.name, AppRoutes.login);
    });
  });

  group('GuestOnlyGuard', () {
    test('authenticated → bounce về shell', () async {
      await store.setSession(
        accessToken: fakeJwt(<String, dynamic>{'role': 'OWNER'}),
        refreshToken: 'r1',
        user: const UserSummary(id: 'u1'),
      );

      expect(GuestOnlyGuard().redirect(AppRoutes.login)?.name,
          AppRoutes.shellRoot);
    });

    test('unauthenticated → cho qua', () async {
      await store.clear();

      expect(GuestOnlyGuard().redirect(AppRoutes.login), isNull);
    });
  });

  test('bảng route không có tên trùng nhau', () {
    final names = AppPages.pages.map((GetPage<dynamic> p) => p.name).toList();

    expect(names.toSet().length, names.length);
    expect(names, contains(AppRoutes.splash));
    expect(names, contains(AppRoutes.shellRoot));
  });

  test('onboarding sở hữu route login/qr-join, shell không đăng ký chúng', () {
    final names = AppPages.pages.map((GetPage<dynamic> p) => p.name).toList();

    expect(names, contains(AppRoutes.login));
    expect(names, contains(AppRoutes.qrJoin));
    // Shell chỉ dành sẵn *tên*; việc đăng ký GetPage thuộc về feature (D2).
    expect(
      AppPages.shellPages.map((GetPage<dynamic> p) => p.name),
      isNot(contains(AppRoutes.login)),
    );
  });

  test('demo mode bị chặn ở build prod', () {
    // Test chạy không có --dart-define nên DEMO_MODE mặc định false.
    expect(EnvConfig.isDemoMode, isFalse);
  });
}
