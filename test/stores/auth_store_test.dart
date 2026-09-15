import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/stores/submission_state.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/onboarding_harness.dart';
import '../helpers/secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();

  setUp(storageChannel.install);
  tearDown(storageChannel.uninstall);

  group('Flow 3 — đăng ký', () {
    test('S3.2 validation phía client chặn trước khi gọi BE', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(201, successEnvelope(null))),
      );

      final ok = await harness.authStore.register(
        email: 'sai-dinh-dang',
        password: 'short',
        fullName: '  ',
      );

      expect(ok, isFalse);
      expect(harness.adapter.requests, isEmpty, reason: 'không được chạm BE');
      expect(harness.authStore.registerFieldErrors, <String, String>{
        'email': 'invalidEmail',
        'password': 'passwordTooShort',
        'fullName': 'fullNameRequired',
      });
    });

    test('thành công → lưu pendingEmail và bật cooldown resend', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            201,
            successEnvelope(<String, dynamic>{
              'requiresOtpVerification': true,
              'message': 'sent',
              'email': 'a@b.com',
            }),
          ),
        ),
      );

      final ok = await harness.authStore.register(
        email: 'a@b.com',
        password: 'password123',
        fullName: 'Phúc',
      );

      expect(ok, isTrue);
      expect(harness.authStore.pendingEmail, 'a@b.com');
      expect(harness.authStore.otpFlow, OtpFlow.register);
      expect(harness.authStore.canResendOtp, isFalse);
    });

    test('S3.4 — ERR_AUTH_003 giữ nguyên code để view hiện inline', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            409,
            errorEnvelope('ERR_AUTH_003', 'Email already registered'),
          ),
        ),
      );

      await harness.authStore.register(
        email: 'a@b.com',
        password: 'password123',
        fullName: 'Phúc',
      );

      final state = harness.authStore.registerState;
      expect(state, isA<SubmissionFailure>());
      expect((state as SubmissionFailure).code, 'ERR_AUTH_003');
    });
  });

  group('Flow 4 — OTP', () {
    test('S4.5 verify đúng → phiên được lưu, claim đọc từ JWT', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            200,
            successEnvelope(sessionData(householdId: 'h1', role: 'MEMBER')),
          ),
        ),
      );
      harness.authStore.prepareOtp(email: 'a@b.com', flow: OtpFlow.register);

      final ok = await harness.authStore.verifyOtp('123456');

      expect(ok, isTrue);
      expect(harness.sessionStore.status, AuthStatus.authenticated);
      expect(harness.sessionStore.householdId, 'h1');
      expect(harness.sessionStore.role, 'MEMBER');
    });

    test('OTP sai định dạng không chạm BE', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );
      harness.authStore.prepareOtp(email: 'a@b.com', flow: OtpFlow.register);

      final ok = await harness.authStore.verifyOtp('12');

      expect(ok, isFalse);
      expect(harness.adapter.requests, isEmpty);
    });

    test('S4.4 — resend chạm giới hạn trả ERR_AUTH_OTP_LIMIT', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            429,
            errorEnvelope('ERR_AUTH_OTP_LIMIT', 'Too many'),
          ),
        ),
      );
      harness.authStore.prepareOtp(email: 'a@b.com', flow: OtpFlow.register);
      // Cooldown phía client vừa bật — phải hết hạn thì mới gọi được.
      harness.authStore.resendAvailableAt =
          DateTime.now().subtract(const Duration(seconds: 1));

      await harness.authStore.resendOtp();

      final state = harness.authStore.resendState;
      expect((state as SubmissionFailure).code, 'ERR_AUTH_OTP_LIMIT');
    });

    test('cooldown phía client chặn resend, không chạm BE', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );
      harness.authStore.prepareOtp(email: 'a@b.com', flow: OtpFlow.register);

      await harness.authStore.resendOtp();

      expect(harness.adapter.requests, isEmpty);
    });
  });

  group('Flow 5 — đăng nhập', () {
    test('S5.3 — ERR_AUTH_004 không bị tách thành hai trường hợp', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            401,
            errorEnvelope('ERR_AUTH_004', 'Invalid credentials'),
          ),
        ),
      );

      await harness.authStore.login(email: 'a@b.com', password: 'wrong');

      final state = harness.authStore.loginState as SubmissionFailure;
      expect(state.code, 'ERR_AUTH_004');
      expect(harness.authStore.isLoginLocked, isFalse);
    });

    test('S5.4 — ERR_AUTH_RATE_LIMIT bật khoá và chặn lần submit kế tiếp',
        () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            429,
            errorEnvelope('ERR_AUTH_RATE_LIMIT', 'Too many attempts'),
          ),
        ),
      );

      await harness.authStore.login(email: 'a@b.com', password: 'x');
      expect(harness.authStore.isLoginLocked, isTrue);

      final requestsBefore = harness.adapter.requests.length;
      final ok = await harness.authStore.login(
        email: 'a@b.com',
        password: 'x',
      );

      expect(ok, isFalse);
      expect(harness.adapter.requests.length, requestsBefore,
          reason: 'đang khoá thì không được gửi request nữa');
    });
  });

  // M2 — use case này từng dùng Get.find<SessionStore>() nên không test được.
  group('Flow 9 — nâng cấp GUEST', () {
    test('thành công → chuyển sang OTP flow=upgrade và cập nhật claim',
        () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            200,
            successEnvelope(<String, dynamic>{
              'accessToken': fakeJwt(<String, dynamic>{
                'sub': 'u1',
                'household_id': 'h1',
                'role': 'MEMBER',
                'provider': 'EMAIL',
              }),
              'refreshToken': 'r2',
              'expiresIn': 900,
              'requiresOtpVerification': true,
              'message': 'verify',
            }),
          ),
        ),
      );

      final ok = await harness.authStore.upgradeProfile(
        email: 'guest@demo.local',
        password: 'password123',
      );

      expect(ok, isTrue);
      expect(harness.authStore.otpFlow, OtpFlow.upgrade);
      expect(harness.authStore.pendingEmail, 'guest@demo.local');
      // GUEST vừa thành EMAIL — claim phải được đồng bộ ngay.
      expect(harness.sessionStore.provider, 'EMAIL');
      expect(await harness.tokenStorage.readRefreshToken(), 'r2');
    });

    test('S9.4 — ERR_AUTH_003 giữ code để view hiện inline', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async =>
              jsonResponse(409, errorEnvelope('ERR_AUTH_003', 'taken')),
        ),
      );

      await harness.authStore.upgradeProfile(
        email: 'taken@demo.local',
        password: 'password123',
      );

      expect(
        (harness.authStore.upgradeState as SubmissionFailure).code,
        'ERR_AUTH_003',
      );
    });

    test('validation phía client chặn trước khi gọi BE', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );

      final ok = await harness.authStore.upgradeProfile(
        email: 'sai',
        password: 'ngan',
      );

      expect(ok, isFalse);
      expect(harness.adapter.requests, isEmpty);
    });
  });

  // H1 — store onboarding sống lâu hơn một phiên; phải được dọn khi phiên kết thúc.
  group('Dọn state khi phiên kết thúc', () {
    test('SessionStore.clear() kéo theo reset store onboarding', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            429,
            errorEnvelope('ERR_AUTH_RATE_LIMIT', 'x'),
          ),
        ),
      );
      harness.sessionStore.addOnClearedListener(() {
        harness.authStore.reset();
        harness.householdStore.reset();
      });

      harness.authStore.prepareOtp(email: 'a@b.com', flow: OtpFlow.upgrade);
      await harness.authStore.login(email: 'a@b.com', password: 'x');
      expect(harness.authStore.pendingEmail, 'a@b.com');
      expect(harness.authStore.isLoginLocked, isTrue);

      await harness.sessionStore.clear();

      expect(harness.authStore.pendingEmail, isNull);
      expect(harness.authStore.isLoginLocked, isFalse);
      expect(harness.authStore.otpFlow, OtpFlow.register);
      expect(harness.authStore.loginState, isA<SubmissionIdle>());
    });

    test('listener ném lỗi không được chặn việc đăng xuất', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
      );
      harness.sessionStore
          .addOnClearedListener(() => throw StateError('feature bể'));

      await expectLater(harness.sessionStore.clear(), completes);
      expect(harness.sessionStore.status, AuthStatus.unauthenticated);
    });
  });

  group('Flow 2 — Google', () {
    test('user hủy popup → idle, KHÔNG phải lỗi', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
        googleGateway: FakeGoogleAuthGateway(idToken: null),
      );

      final ok = await harness.authStore.signInWithGoogle();

      expect(ok, isFalse);
      expect(harness.authStore.googleState, isA<SubmissionIdle>());
      expect(harness.adapter.requests, isEmpty);
    });

    test('S2.2 — ERR_AUTH_FIREBASE_UNAVAILABLE thành SubmissionFailure',
        () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            503,
            errorEnvelope('ERR_AUTH_FIREBASE_UNAVAILABLE', 'unavailable'),
          ),
        ),
      );

      await harness.authStore.signInWithGoogle();

      final state = harness.authStore.googleState as SubmissionFailure;
      expect(state.code, 'ERR_AUTH_FIREBASE_UNAVAILABLE');
    });

    test('accountLinked: true → bật toast một lần rồi tắt', () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter(
          (_) async => jsonResponse(
            200,
            successEnvelope(sessionData(accountLinked: true)),
          ),
        ),
      );

      await harness.authStore.signInWithGoogle();
      expect(harness.authStore.showAccountLinkedToast, isTrue);

      harness.authStore.consumeAccountLinkedToast();
      expect(harness.authStore.showAccountLinkedToast, isFalse);
    });

    test('SDK ném lỗi lạ vẫn quy về ApiException, không thoát ra ngoài',
        () async {
      final harness = OnboardingHarness(
        FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
        googleGateway: FakeGoogleAuthGateway(
          throwOnSignIn: StateError('SDK bể'),
        ),
      );

      await expectLater(harness.authStore.signInWithGoogle(), completes);
      expect(harness.authStore.googleState, isA<SubmissionFailure>());
    });
  });
}
