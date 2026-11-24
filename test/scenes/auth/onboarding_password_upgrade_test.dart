import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/auth/reset_password_scene.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/widgets/inputs/app_text_field.dart';

import '../onboarding_harness.dart';

/// Các form auth đã chuyển sang `AppTextField` (fe-onboarding.md §18b):
/// quên/đặt lại mật khẩu và nâng cấp GUEST.
void main() {
  late OnboardingHarness h;

  setUp(() => h = OnboardingHarness());
  tearDown(Get.reset);

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is AppButton && w.label == label);
  Finder input(String label) => find.descendant(
        of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
        matching: find.byType(TextField),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('Quên / đặt lại mật khẩu', () {
    testWidgets('email sai → lỗi realtime; đúng → sang bước đặt lại', (tester) async {
      await h.pump(tester, AppRoutes.forgotPassword);
      await tester.enterText(input('Email'), 'abc');
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsOneWidget);

      await tester.enterText(input('Email'), 'a@b.co');
      await tester.tap(button('Gửi mã'));
      await settle(tester);
      expect(find.byType(ResetPasswordScene), findsOneWidget);
    });

    testWidgets('xác nhận mật khẩu không khớp → lỗi realtime; khớp → về login',
        (tester) async {
      await h.pump(tester, AppRoutes.forgotPassword);
      await tester.enterText(input('Email'), 'a@b.co');
      await tester.tap(button('Gửi mã'));
      await settle(tester);

      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.enterText(input('Mật khẩu mới'), '12345678');
      await tester.enterText(input('Xác nhận mật khẩu'), '1234');
      await tester.pump();
      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
      expect(find.text('Ít nhất 8 ký tự'), findsNothing);

      await tester.enterText(input('Xác nhận mật khẩu'), '12345678');
      await tester.pump();
      expect(find.text('Mật khẩu xác nhận không khớp'), findsNothing);

      await tester.tap(button('Đặt lại mật khẩu'));
      await settle(tester);
      expect(h.authApi.resetCalls, 1);
      expect(find.text('LOGIN'), findsOneWidget);
      // Snackbar của GetX giữ ticker — đóng hẳn trước khi test kết thúc.
      // (Get.snackbar tự đóng sau 3s rồi chạy animation ẩn.)
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('ô email ở bước đặt lại là chỉ đọc', (tester) async {
      await h.pump(tester, AppRoutes.forgotPassword);
      await tester.enterText(input('Email'), 'a@b.co');
      await tester.tap(button('Gửi mã'));
      await settle(tester);
      final email = tester.widget<TextField>(input('Email'));
      expect(email.readOnly, isTrue);
      expect(email.controller!.text, 'a@b.co');
    });
  });

  group('Nâng cấp GUEST', () {
    testWidgets('validate realtime; họ tên tuỳ chọn được để trống', (tester) async {
      await h.pump(tester, AppRoutes.profileUpgrade);
      await tester.enterText(input('Email'), 'x');
      await tester.enterText(input('Mật khẩu'), '1');
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(find.text('Ít nhất 8 ký tự'), findsOneWidget);
      expect(find.text('Vui lòng nhập họ tên'), findsNothing);
    });

    testWidgets('email đã tồn tại → lỗi inline đã dịch; sửa email → lỗi mất',
        (tester) async {
      h.authApi.upgradeError = BusinessException('ERR_AUTH_003', 'exists');
      await h.pump(tester, AppRoutes.profileUpgrade);
      await tester.enterText(input('Email'), 'a@b.co');
      await tester.enterText(input('Mật khẩu'), '12345678');
      await tester.tap(button('Tiếp tục'));
      await settle(tester);
      expect(find.text('Email này đã được đăng ký'), findsOneWidget);

      await tester.enterText(input('Email'), 'b@b.co');
      await tester.pump();
      expect(find.text('Email này đã được đăng ký'), findsNothing);
    });

    testWidgets('hợp lệ → sang OTP', (tester) async {
      await h.signIn(householdId: 'h1');
      await h.pump(tester, AppRoutes.profileUpgrade);
      await tester.enterText(input('Email'), 'a@b.co');
      await tester.enterText(input('Mật khẩu'), '12345678');
      await tester.tap(button('Tiếp tục'));
      await settle(tester);
      expect(h.authApi.upgradeCalls, 1);
      expect(find.text('OTP'), findsOneWidget);
    });
  });
}
