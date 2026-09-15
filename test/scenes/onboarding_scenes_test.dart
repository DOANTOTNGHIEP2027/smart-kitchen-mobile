import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/onboarding/auth_landing_scene.dart';
import 'package:smart_kitchen_mobile/scenes/onboarding/invite_preview_scene.dart';
import 'package:smart_kitchen_mobile/scenes/onboarding/login_scene.dart';
import 'package:smart_kitchen_mobile/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/stores/household_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/onboarding_harness.dart';
import '../helpers/pump_app.dart';
import '../helpers/secure_storage_channel.dart';

/// Ánh xạ `error.code` → copy người dùng nhìn thấy nằm ở view, không ở store —
/// đúng phần mà bảng truy vết §19 của spec ràng buộc.
///
/// Mọi bước dựng state gọi qua Dio đều phải nằm trong [WidgetTester.runAsync]:
/// `testWidgets` chạy trong FakeAsync, còn `DioMixin.fetch` mở đầu bằng
/// `Future(() => ...)` — tức lên **event loop**, không phải microtask. `await`
/// thẳng một future như vậy mà chưa `pump()` sẽ treo vĩnh viễn, không timeout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();

  setUp(storageChannel.install);
  tearDown(() {
    storageChannel.uninstall();
    Get.reset();
  });

  void register(OnboardingHarness harness) {
    Get.put<SessionStore>(harness.sessionStore, permanent: true);
    Get.put<AuthStore>(harness.authStore, permanent: true);
    Get.put<HouseholdStore>(harness.householdStore, permanent: true);
  }

  Map<String, dynamic> validPreview() => <String, dynamic>{
        'householdName': 'Gia đình Nguyễn',
        'ownerName': 'Phúc',
        'memberCount': 3,
        'expiresAt': '2026-09-20T10:00:00Z',
        'isValid': true,
      };

  group('S2.x — landing hiện đúng copy theo error.code của Google', () {
    Future<void> pumpAfterGoogleError(
      WidgetTester tester,
      String code,
      int status,
    ) async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(status, errorEnvelope(code, 'x'))),
      );
      register(harness);
      await tester.runAsync(() => harness.authStore.signInWithGoogle());
      await tester.pumpAppWidget(const AuthLandingScene());
      await tester.pump();
    }

    testWidgets('S2.2 — ERR_AUTH_FIREBASE_UNAVAILABLE',
        (WidgetTester tester) async {
      await pumpAfterGoogleError(tester, 'ERR_AUTH_FIREBASE_UNAVAILABLE', 503);

      expect(find.text("We can't reach Google right now."), findsOneWidget);
      // Nhánh này phải kèm lối thoát sang email.
      expect(find.text('Use email instead'), findsOneWidget);
    });

    testWidgets('S2.4 — ERR_AUTH_001 không đưa ra lối thoát email',
        (WidgetTester tester) async {
      await pumpAfterGoogleError(tester, 'ERR_AUTH_001', 401);

      expect(
        find.text('Google sign-in failed, please try again.'),
        findsOneWidget,
      );
      expect(find.text('Use email instead'), findsNothing);
    });

    testWidgets('code lạ rơi về S13.2 chứ không hiện code thô',
        (WidgetTester tester) async {
      await pumpAfterGoogleError(tester, 'ERR_SOMETHING_NEW', 500);

      expect(
        find.text('Something went wrong, please try again'),
        findsOneWidget,
      );
      expect(find.textContaining('ERR_'), findsNothing);
    });
  });

  group('S5.3 — login không bao giờ tách hai trường hợp sai', () {
    testWidgets('ERR_AUTH_004 hiện một lỗi chung duy nhất',
        (WidgetTester tester) async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async =>
              jsonResponse(401, errorEnvelope('ERR_AUTH_004', 'Invalid')),
        ),
      );
      register(harness);
      await tester.runAsync(
        () => harness.authStore.login(email: 'a@b.com', password: 'wrong'),
      );

      await tester.pumpAppWidget(const LoginScene());
      await tester.pump();

      expect(find.text('Email or password is incorrect'), findsOneWidget);
      // Không được có bất kỳ copy nào ám chỉ email tồn tại hay không.
      expect(find.textContaining('email'), findsNothing);
    });

    testWidgets('S5.4 — khoá 429 vô hiệu hoá nút đăng nhập',
        (WidgetTester tester) async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async =>
              jsonResponse(429, errorEnvelope('ERR_AUTH_RATE_LIMIT', 'x')),
        ),
      );
      register(harness);
      await tester.runAsync(
        () => harness.authStore.login(email: 'a@b.com', password: 'x'),
      );

      await tester.pumpAppWidget(const LoginScene());
      await tester.pump();

      expect(find.textContaining('Too many attempts'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Sign in'),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('S8.x — invite preview', () {
    testWidgets('S8.7 — đã thuộc household khác: chặn, không có nút Tham gia',
        (WidgetTester tester) async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(200, successEnvelope(validPreview())),
        ),
      );
      register(harness);
      await tester.runAsync(() async {
        await harness.sessionStore.setSession(
          accessToken: fakeJwt(<String, dynamic>{'household_id': 'h-khac'}),
          refreshToken: 'r1',
          user: const UserSummary(id: 'u1'),
        );
        await harness.householdStore.loadPreview('DEMO1234');
      });

      await tester.pumpAppWidget(const InvitePreviewScene());
      await tester.pump();

      expect(find.text('You already belong to another family.'), findsOneWidget);
      expect(find.text('Join'), findsNothing);
    });

    testWidgets('S8.6 — mã hết hạn: hai lối thoát, không có nút Tham gia',
        (WidgetTester tester) async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(400, errorEnvelope('ERR_HH_002', 'expired')),
        ),
      );
      register(harness);
      await tester.runAsync(
        () => harness.householdStore.loadPreview('EXPIRED1'),
      );

      await tester.pumpAppWidget(const InvitePreviewScene());
      await tester.pump();

      expect(
        find.text('This invite code is invalid or has expired'),
        findsOneWidget,
      );
      expect(find.text('Try another code'), findsOneWidget);
      expect(find.text('Scan again'), findsOneWidget);
      expect(find.text('Join'), findsNothing);
    });

    testWidgets('S8.5 — chưa đăng nhập thì mới hỏi tên hiển thị',
        (WidgetTester tester) async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(200, successEnvelope(validPreview())),
        ),
      );
      register(harness);
      await tester.runAsync(
        () => harness.householdStore.loadPreview('DEMO1234'),
      );

      await tester.pumpAppWidget(const InvitePreviewScene());
      await tester.pump();

      expect(find.text('Gia đình Nguyễn'), findsOneWidget);
      expect(find.text('Your display name'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('S8.9 — race hiện banner "vừa được người khác dùng"',
        (WidgetTester tester) async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((options) async {
          if (options.path.startsWith('/api/v1/households/invites/')) {
            return jsonResponse(200, successEnvelope(validPreview()));
          }
          return jsonResponse(400, errorEnvelope('ERR_HH_005', 'used'));
        }),
      );
      register(harness);
      await tester.runAsync(() async {
        await harness.sessionStore.setSession(
          accessToken: fakeJwt(<String, dynamic>{'sub': 'u1'}),
          refreshToken: 'r1',
          user: const UserSummary(id: 'u1'),
        );
        await harness.householdStore.loadPreview('DEMO1234');
        await harness.householdStore.confirmJoin();
      });

      await tester.pumpAppWidget(const InvitePreviewScene());
      await tester.pump();

      expect(
        find.text('Someone just used this invite code'),
        findsOneWidget,
      );
    });
  });
}
