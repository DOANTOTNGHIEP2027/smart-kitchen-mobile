import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/routing/route_guards.dart';
import 'package:smart_kitchen_mobile/scenes/splash/splash_scene.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import 'onboarding_harness.dart';

/// Luồng onboarding đầu-cuối (AuthFlowTest của issue #28) + guard điều hướng
/// household (fe-onboarding.md Flow 6).
void main() {
  late OnboardingHarness h;

  setUp(() => h = OnboardingHarness());
  tearDown(Get.reset);

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is AppButton && w.label == label);
  Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey<String>(key)), matching: find.byType(TextField));

  testWidgets('login email → household setup → tạo Nhà → shell', (tester) async {
    await h.pump(tester, AppRoutes.emailLogin);

    await tester.enterText(field('login-email'), 'a@b.co');
    await tester.enterText(field('login-password'), '12345678');
    await tester.tap(button('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.householdSetup);

    await tester.tap(button('Tạo Nhà'));
    await tester.pumpAndSettle();
    await tester.enterText(field('household-name'), 'Nhà An');
    await tester.tap(button('Tạo Nhà'));
    await tester.pumpAndSettle();
    expect(find.text('ABC12345'), findsOneWidget);

    await tester.tap(button('Để sau'));
    await tester.pumpAndSettle();
    expect(find.text('SHELL'), findsOneWidget);
    expect(h.session.householdId, 'h1');
  });

  group('HouseholdSetupGuard', () {
    test('chưa đăng nhập → login', () {
      expect(HouseholdSetupGuard().redirect(AppRoutes.householdSetup)?.name,
          AppRoutes.login);
    });

    test('đã có Nhà → shell', () async {
      await h.signIn(householdId: 'h1');
      expect(HouseholdSetupGuard().redirect(AppRoutes.householdSetup)?.name,
          AppRoutes.shellRoot);
    });

    test('đăng nhập, chưa có Nhà → cho qua', () async {
      await h.signIn();
      expect(HouseholdSetupGuard().redirect(AppRoutes.householdSetup), isNull);
    });
  });

  testWidgets('splash: đăng nhập nhưng chưa có Nhà → household setup', (tester) async {
    await h.signIn();
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: AppRoutes.splash,
      getPages: <GetPage<dynamic>>[
        GetPage<void>(name: AppRoutes.splash, page: () => const SplashScene()),
        GetPage<void>(name: AppRoutes.householdSetup, page: () => const Text('SETUP')),
        GetPage<void>(name: AppRoutes.login, page: () => const Text('LOGIN')),
        GetPage<void>(name: '/', page: () => const Text('SHELL')),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('SETUP'), findsOneWidget);
  });
}
