import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/domain/auth_models.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/form_status.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/password_reset_store.dart';

void main() {
  group('PasswordResetStore', () {
    test('requestOtp email không hợp lệ → không gọi API, set fieldErrors[email]', () async {
      final api = _FakeAuthApi();
      final store = PasswordResetStore(api);
      addTearDown(store.dispose);

      final ok = await store.requestOtp('bad');

      expect(ok, isFalse);
      expect(api.forgotCalls, 0);
      expect(store.fieldErrors['email'], 'auth_email_invalid');
      expect(store.forgotStatus, FormStatus.failure);
    });

    test('requestOtp thành công → forgotStatus success, cooldown = 60, lưu email đã trim', () async {
      final api = _FakeAuthApi();
      final store = PasswordResetStore(api);
      addTearDown(store.dispose);

      final ok = await store.requestOtp(' a@example.com ');

      expect(ok, isTrue);
      expect(api.forgotCalls, 1);
      expect(api.lastForgotEmail, 'a@example.com');
      expect(store.email, 'a@example.com');
      expect(store.forgotStatus, FormStatus.success);
      expect(store.cooldownSeconds, 60);
    });

    test('requestOtp lỗi mạng → failure + error, giữ nguyên email', () async {
      final api = _FakeAuthApi()..forgotError = NetworkException();
      final store = PasswordResetStore(api);
      addTearDown(store.dispose);

      final ok = await store.requestOtp('a@example.com');

      expect(ok, isFalse);
      expect(store.forgotStatus, FormStatus.failure);
      expect(store.error?.code, 'ERR_NETWORK');
    });

    test('reset OTP không đủ 6 số → không gọi API', () async {
      final api = _FakeAuthApi();
      final store = PasswordResetStore(api, email: 'a@example.com');
      addTearDown(store.dispose);

      final ok = await store.reset(otp: '123', newPassword: 'password1');

      expect(ok, isFalse);
      expect(api.resetCalls, 0);
      expect(store.fieldErrors['otp'], 'otp_invalid');
    });

    test('reset mật khẩu xác nhận không khớp → không gọi API', () async {
      final api = _FakeAuthApi();
      final store = PasswordResetStore(api, email: 'a@example.com');
      addTearDown(store.dispose);

      final ok = await store.reset(otp: '123456', newPassword: 'password1', confirmPassword: 'password2');

      expect(ok, isFalse);
      expect(api.resetCalls, 0);
      expect(store.fieldErrors['confirmPassword'], 'auth_password_mismatch');
    });

    test('reset với ERR_AUTH_OTP_INVALID → fieldErrors[otp]', () async {
      final api = _FakeAuthApi()..resetError = BusinessException('ERR_AUTH_OTP_INVALID', 'bad otp');
      final store = PasswordResetStore(api, email: 'a@example.com');
      addTearDown(store.dispose);

      final ok = await store.reset(otp: '123456', newPassword: 'password1');

      expect(ok, isFalse);
      expect(api.resetCalls, 1);
      expect(store.resetStatus, FormStatus.failure);
      expect(store.fieldErrors['otp'], 'otp_invalid');
    });

    test('reset thành công → resetStatus success, gửi đúng payload', () async {
      final api = _FakeAuthApi();
      final store = PasswordResetStore(api, email: 'a@example.com');
      addTearDown(store.dispose);

      final ok = await store.reset(otp: '123456', newPassword: 'password1', confirmPassword: 'password1');

      expect(ok, isTrue);
      expect(api.resetCalls, 1);
      expect(api.lastReset, {'email': 'a@example.com', 'otp': '123456', 'newPassword': 'password1'});
      expect(store.resetStatus, FormStatus.success);
    });

    test('reset ERR_AUTH_RATE_LIMIT → khoá tạm và chặn gửi lại', () async {
      final api = _FakeAuthApi()..resetError = BusinessException('ERR_AUTH_RATE_LIMIT', 'slow down');
      final store = PasswordResetStore(api, email: 'a@example.com');
      addTearDown(store.dispose);

      await store.reset(otp: '123456', newPassword: 'password1');

      expect(store.isLocked, isTrue);
      expect(store.canResend, isFalse);
    });

    test('resendOtp chưa hết cooldown → không gọi API', () async {
      final api = _FakeAuthApi();
      final store = PasswordResetStore(api, email: 'a@example.com');
      addTearDown(store.dispose);
      await store.requestOtp('a@example.com');
      api.forgotCalls = 0;

      final ok = await store.resendOtp();

      expect(ok, isFalse);
      expect(api.forgotCalls, 0);
    });
  });
}

class _FakeAuthApi implements AuthApi {
  int forgotCalls = 0;
  int resetCalls = 0;
  String? lastForgotEmail;
  Map<String, String>? lastReset;
  ApiException? forgotError;
  ApiException? resetError;

  @override
  Future<void> forgotPassword(String email) async {
    forgotCalls++;
    lastForgotEmail = email;
    if (forgotError != null) throw forgotError!;
  }

  @override
  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    resetCalls++;
    lastReset = {'email': email, 'otp': otp, 'newPassword': newPassword};
    if (resetError != null) throw resetError!;
  }

  @override
  Future<void> sendOtp(String email) async {}

  @override
  Future<AuthSession> login({required String email, required String password}) => throw UnimplementedError();

  @override
  Future<AuthSession> loginWithGoogle(String idToken) => throw UnimplementedError();

  @override
  Future<RegisterResult> register({required String email, required String password, required String fullName}) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> verifyOtp({required String email, required String otp}) => throw UnimplementedError();

  @override
  Future<GuestJoinSession> joinAsGuest({required String inviteCode, String? displayName}) => throw UnimplementedError();

  @override
  Future<UpgradeResult> upgrade({required String email, required String password, String? fullName}) =>
      throw UnimplementedError();
}
