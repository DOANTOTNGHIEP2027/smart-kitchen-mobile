import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/auth/email_login_scene.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import '../onboarding_harness.dart';

/// Widget test màn đăng nhập / đăng ký (issue #28, fe-onboarding.md
/// Flow 3, Flow 5, §18b).
void main() {
  late OnboardingHarness h;

  setUp(() => h = OnboardingHarness());
  tearDown(Get.reset);

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is AppButton && w.label == label);

  Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey<String>(key)), matching: find.byType(TextField));

  group('EmailLoginScene', () {
    testWidgets('AC: sai mật khẩu → "Sai email hoặc mật khẩu" inline, không hiện key thô',
        (tester) async {
      h.authApi.loginError = BusinessException('ERR_AUTH_004', 'Invalid email or password');
      await h.pump(tester, AppRoutes.emailLogin);

      await tester.enterText(field('login-email'), 'a@b.co');
      await tester.enterText(field('login-password'), '12345678');
      await tester.tap(button('Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Sai email hoặc mật khẩu'), findsOneWidget);
      expect(find.text('auth_bad_credentials'), findsNothing);
      expect(find.byType(EmailLoginScene), findsOneWidget, reason: 'không crash, ở lại màn');
    });

    testWidgets('validate realtime khi gõ, trước khi bấm submit', (tester) async {
      await h.pump(tester, AppRoutes.emailLogin);

      await tester.enterText(field('login-email'), 'abc');
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsOneWidget);

      await tester.enterText(field('login-email'), 'abc@d.co');
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsNothing);

      await tester.enterText(field('login-password'), '123');
      await tester.pump();
      expect(find.text('Ít nhất 8 ký tự'), findsOneWidget);
      expect(h.authApi.loginCalls, 0);
    });

    testWidgets('sửa lại ô mật khẩu → lỗi server biến mất', (tester) async {
      h.authApi.loginError = BusinessException('ERR_AUTH_004', 'x');
      await h.pump(tester, AppRoutes.emailLogin);
      await tester.enterText(field('login-email'), 'a@b.co');
      await tester.enterText(field('login-password'), '12345678');
      await tester.tap(button('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Sai email hoặc mật khẩu'), findsOneWidget);

      await tester.enterText(field('login-password'), '123456789');
      await tester.pump();
      expect(find.text('Sai email hoặc mật khẩu'), findsNothing);
    });

    testWidgets('mất mạng → banner "Kiểm tra kết nối", không crash', (tester) async {
      h.authApi.loginError = NetworkException();
      await h.pump(tester, AppRoutes.emailLogin);
      await tester.enterText(field('login-email'), 'a@b.co');
      await tester.enterText(field('login-password'), '12345678');
      await tester.tap(button('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra kết nối và thử lại'), findsOneWidget);
    });

    testWidgets('đăng nhập đúng, chưa có Nhà → household setup', (tester) async {
      await h.pump(tester, AppRoutes.emailLogin);
      await tester.enterText(field('login-email'), 'a@b.co');
      await tester.enterText(field('login-password'), '12345678');
      await tester.tap(button('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.householdSetup);
      expect(h.storage.refreshToken, 'refresh', reason: 'token đã được lưu');
    });

    testWidgets('submit form trống → lỗi validate, không gọi API', (tester) async {
      await h.pump(tester, AppRoutes.emailLogin);
      await tester.tap(button('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(h.authApi.loginCalls, 0);
    });
  });

  group('EmailRegisterScene', () {
    testWidgets('validate realtime cả 3 ô', (tester) async {
      await h.pump(tester, AppRoutes.register);
      await tester.enterText(field('register-full-name'), 'a');
      await tester.enterText(field('register-full-name'), ' ');
      await tester.enterText(field('register-email'), 'x');
      await tester.enterText(field('register-password'), '1');
      await tester.pump();
      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(find.text('Ít nhất 8 ký tự'), findsWidgets);
    });

    testWidgets('email đã tồn tại (ERR_AUTH_003) → lỗi inline đã dịch', (tester) async {
      h.authApi.registerError = BusinessException('ERR_AUTH_003', 'exists');
      await h.pump(tester, AppRoutes.register);
      await tester.enterText(field('register-full-name'), 'An');
      await tester.enterText(field('register-email'), 'a@b.co');
      await tester.enterText(field('register-password'), '12345678');
      await tester.tap(button('Tạo tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Email này đã được đăng ký'), findsOneWidget);
      expect(find.text('auth_email_exists'), findsNothing);
    });

    testWidgets('đăng ký hợp lệ → sang màn OTP', (tester) async {
      await h.pump(tester, AppRoutes.register);
      await tester.enterText(field('register-full-name'), 'An');
      await tester.enterText(field('register-email'), 'a@b.co');
      await tester.enterText(field('register-password'), '12345678');
      await tester.tap(button('Tạo tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('OTP'), findsOneWidget);
      expect(h.authApi.registerCalls, 1);
    });
  });
}
