import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/household/domain/household_models.dart';
import 'package:smart_kitchen_mobile/scenes/household/join_household_scene.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import '../onboarding_harness.dart';

/// Widget test household setup / tạo / tham gia + deep link (issue #28,
/// fe-onboarding.md Flow 6–8, §12b).
void main() {
  late OnboardingHarness h;

  setUp(() => h = OnboardingHarness());
  tearDown(() {
    Get.reset();
  });

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is AppButton && w.label == label);
  Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey<String>(key)), matching: find.byType(TextField));
  String fieldText(WidgetTester tester, String key) =>
      tester.widget<TextField>(field(key)).controller!.text;

  group('HouseholdSetupScene', () {
    testWidgets('2 lựa chọn: tạo Nhà / tham gia (vào thẳng nhập mã)', (tester) async {
      await h.signIn();
      await h.pump(tester, AppRoutes.householdSetup);
      expect(button('Tạo Nhà'), findsOneWidget);
      expect(button('Tham gia Nhà'), findsOneWidget);

      await tester.tap(button('Tham gia Nhà'));
      await tester.pumpAndSettle();
      expect(find.byType(JoinHouseholdScene), findsOneWidget);
      expect(find.byKey(const ValueKey('join-code')), findsOneWidget);
    });

    testWidgets('chọn Tạo Nhà → màn tạo Nhà', (tester) async {
      await h.signIn();
      await h.pump(tester, AppRoutes.householdSetup);
      await tester.tap(button('Tạo Nhà'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('household-name')), findsOneWidget);
    });
  });

  group('CreateHouseholdScene', () {
    testWidgets('tên trống → lỗi validate, không gọi API', (tester) async {
      await h.signIn();
      await h.pump(tester, AppRoutes.householdCreate);
      await tester.tap(button('Tạo Nhà'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên Nhà'), findsOneWidget);
      expect(h.householdApi.createCalls, 0);
    });

    testWidgets('tạo thành công → QR chứa link mời + mã, rồi vào shell', (tester) async {
      await h.signIn();
      await h.pump(tester, AppRoutes.householdCreate);
      await tester.enterText(field('household-name'), 'Nhà An');
      await tester.tap(button('Tạo Nhà'));
      await tester.pumpAndSettle();

      expect(find.text('ABC12345'), findsOneWidget);
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr, isNotNull);
      expect(h.session.householdId, 'h1', reason: 'refresh claim sau khi tạo');

      await tester.tap(button('Để sau'));
      await tester.pumpAndSettle();
      expect(find.text('SHELL'), findsOneWidget);
    });

    testWidgets('mất mạng khi tạo → banner lỗi, ở lại màn', (tester) async {
      h.householdApi.createError = NetworkException();
      await h.signIn();
      await h.pump(tester, AppRoutes.householdCreate);
      await tester.enterText(field('household-name'), 'Nhà An');
      await tester.tap(button('Tạo Nhà'));
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra kết nối và thử lại'), findsOneWidget);
    });
  });

  group('JoinHouseholdScene', () {
    Future<void> openManual(WidgetTester tester) async {
      await h.pump(tester, AppRoutes.householdSetup);
      Get.toNamed(AppRoutes.qrJoin, arguments: const {'manual': true});
      await tester.pumpAndSettle();
    }

    testWidgets('member: nhập mã → preview → tham gia → shell', (tester) async {
      await h.signIn();
      await openManual(tester);
      expect(button('Xem trước lời mời'), findsOneWidget, reason: 'empty state');

      await tester.enterText(field('join-code'), 'abc12345');
      await tester.pump();
      expect(fieldText(tester, 'join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();

      expect(find.text('Nhà An'), findsOneWidget);
      expect(h.householdApi.previewCodes, <String>['ABC12345']);
      expect(find.byKey(const ValueKey('join-have-account')), findsNothing,
          reason: 'đã đăng nhập thì không hiện link đăng nhập');

      await tester.tap(button('Tham gia Nhà').last);
      await tester.pumpAndSettle();
      expect(h.householdApi.joinCalls, 1);
      expect(find.text('SHELL'), findsOneWidget);
    });

    testWidgets('dán cả link mời vào ô nhập → rút đúng mã', (tester) async {
      await h.signIn();
      await openManual(tester);
      await tester.enterText(
          field('join-code'), 'https://app.smartkitchen.vn/join/xyz98765');
      await tester.pump();
      expect(fieldText(tester, 'join-code'), 'XYZ98765');
    });

    testWidgets('mã sai định dạng → S8.6, không gọi API', (tester) async {
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('join-preview-error-ERR_HH_002')), findsOneWidget);
      expect(h.householdApi.previewCodes, isEmpty);
    });

    testWidgets('preview isValid:false với tên null (BE thật) → S8.6, không crash',
        (tester) async {
      h.householdApi.previewResult = InvitePreview.fromJson(<String, dynamic>{
        'householdName': null,
        'ownerName': null,
        'memberCount': null,
        'expiresAt': null,
        'isValid': false,
      });
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      expect(find.text('Lời mời không hợp lệ hoặc đã hết hạn'), findsOneWidget);
    });

    testWidgets('preview isFull → S8.12, không có nút Tham gia', (tester) async {
      h.householdApi.previewResult = InvitePreview(
        householdName: 'Nhà An',
        ownerName: 'An',
        memberCount: 10,
        expiresAt: DateTime.utc(2026, 12, 31),
        isValid: true,
        isFull: true,
      );
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      expect(find.text('Gia đình này đã đủ 10 thành viên'), findsOneWidget);
      expect(button('Tham gia Nhà'), findsNothing);
    });

    testWidgets('preview 404 ERR_HH_001 → S8.6 (quy về ERR_HH_002)', (tester) async {
      h.householdApi.previewError = BusinessException('ERR_HH_001', 'not found');
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('join-preview-error-ERR_HH_002')), findsOneWidget);
    });

    testWidgets('response preview của mã cũ về muộn bị bỏ qua', (tester) async {
      final slow = Completer<InvitePreview>();
      h.householdApi.pendingPreviews['AAAA1111'] = slow;
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'AAAA1111');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pump();
      await h.householdStore.preview('BBBB2222');
      await tester.pumpAndSettle();
      expect(find.text('Nhà An'), findsOneWidget);

      slow.complete(InvitePreview(
          householdName: 'Nhà Cũ', ownerName: 'X', memberCount: 1,
          expiresAt: DateTime.utc(2026, 12, 31), isValid: true));
      await tester.pumpAndSettle();
      expect(find.text('Nhà Cũ'), findsNothing);
      expect(find.text('Nhà An'), findsOneWidget);
    });

    testWidgets('tên hiển thị > 100 ký tự → không gửi join', (tester) async {
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      await tester.enterText(field('join-display-name'), 'a' * 101);
      await tester.pump();
      expect(find.text('Họ tên tối đa 100 ký tự'), findsOneWidget);
      await tester.tap(button('Tham gia Nhà').last);
      await tester.pumpAndSettle();
      expect(h.authApi.guestJoinCalls, 0);
    });

    testWidgets('join 409 ERR_HOUSEHOLD_FULL (race) → S8.12', (tester) async {
      h.householdApi.joinError = BusinessException('ERR_HOUSEHOLD_FULL', 'full');
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      await tester.tap(button('Tham gia Nhà').last);
      await tester.pumpAndSettle();
      expect(find.text('Gia đình này đã đủ 10 thành viên'), findsOneWidget);
      expect(button('Tham gia Nhà'), findsNothing, reason: 'S8.12 ẩn CTA sau 409');
    });

    testWidgets('sau 409 FULL, xem mã khác → không còn banner cũ, có lại nút Tham gia',
        (tester) async {
      h.householdApi.joinError = BusinessException('ERR_HOUSEHOLD_FULL', 'full');
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      await tester.tap(button('Tham gia Nhà').last);
      await tester.pumpAndSettle();
      expect(find.text('Gia đình này đã đủ 10 thành viên'), findsOneWidget);

      await tester.enterText(field('join-code'), 'XYZ98765');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Gia đình này đã đủ 10 thành viên'), findsNothing);
      expect(button('Tham gia Nhà'), findsOneWidget);
    });

    testWidgets('preview isValid:false + isFull:true → S8.6 (ưu tiên isValid)',
        (tester) async {
      h.householdApi.previewResult = InvitePreview(
        householdName: 'Nhà An',
        ownerName: 'An',
        memberCount: 10,
        expiresAt: DateTime.utc(2026, 12, 31),
        isValid: false,
        isFull: true,
      );
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('join-preview-error-ERR_HH_002')), findsOneWidget);
    });

    testWidgets('join 429 → S8.13 copy riêng, giữ preview để bấm lại', (tester) async {
      h.householdApi.joinError = BusinessException('ERR_AUTH_RATE_LIMIT', 'slow');
      await h.signIn();
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      await tester.tap(button('Tham gia Nhà').last);
      await tester.pumpAndSettle();
      expect(find.text('Bạn thao tác quá nhanh, vui lòng thử lại sau ít phút'),
          findsOneWidget);
      expect(find.text('Nhà An'), findsOneWidget);
    });

    testWidgets('đã có Nhà → S8.7 ngay khi mở màn + nút "Về trang chủ"', (tester) async {
      await h.signIn(householdId: 'h9');
      await openManual(tester);
      expect(find.text('Bạn đã thuộc một Nhà'), findsOneWidget);
      expect(find.byKey(const ValueKey('join-code')), findsNothing);
      expect(find.byKey(const ValueKey('join-go-home')), findsOneWidget);
      expect(h.householdApi.joinCalls, 0, reason: 'chặn phía client');
    });

    testWidgets('khách (chưa đăng nhập) → qr-join với tên hiển thị + link đăng nhập',
        (tester) async {
      await openManual(tester);
      await tester.enterText(field('join-code'), 'ABC12345');
      await tester.tap(button('Xem trước lời mời'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('join-have-account')), findsOneWidget);

      await tester.enterText(field('join-display-name'), 'Bé Na');
      await tester.tap(button('Tham gia Nhà').last);
      await tester.pumpAndSettle();
      expect(h.authApi.guestJoinCalls, 1);
      expect(h.authApi.lastGuestDisplayName, 'Bé Na');
      expect(find.text('SHELL'), findsOneWidget);
    });
  });

  group('Deep link /join/<code> (§12b)', () {
    testWidgets('nóng: platform đẩy route → màn join với mã điền sẵn + preview',
        (tester) async {
      await h.signIn();
      await h.pump(tester, AppRoutes.householdSetup);
      await tester.binding.handlePushRoute('/join/abc12345');
      await tester.pumpAndSettle();
      expect(find.byType(JoinHouseholdScene), findsOneWidget);
      expect(fieldText(tester, 'join-code'), 'ABC12345');
      expect(h.householdApi.previewCodes, <String>['ABC12345']);
    });

    testWidgets('nguội: initial route từ platform (path sau override) → màn join',
        (tester) async {
      tester.platformDispatcher.defaultRouteNameTestValue = '/join/ABC12345';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      await h.pump(tester, '/splash-not-registered');
      expect(find.byType(JoinHouseholdScene), findsOneWidget);
      expect(fieldText(tester, 'join-code'), 'ABC12345');
      expect(find.text('Nhà An'), findsOneWidget);
    });

    testWidgets('deep link mã sai định dạng → S8.6, không gọi API', (tester) async {
      await h.signIn();
      await h.pump(tester, AppRoutes.householdSetup);
      await tester.binding.handlePushRoute('/join/BAD');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('join-preview-error-ERR_HH_002')), findsOneWidget);
      expect(h.householdApi.previewCodes, isEmpty);
    });
  });
}
