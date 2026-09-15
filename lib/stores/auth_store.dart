import 'package:mobx/mobx.dart';

import '../data/network/api_exception.dart';
import '../domain/auth/auth_usecases.dart';
import '../utils/error_mapper.dart';
import '../utils/validators.dart';
import 'submission_state.dart';

part 'auth_store.g.dart';

/// Ngữ cảnh mà màn hình OTP được mở (fe-onboarding.md Flow 4).
/// Quyết định điều hướng sau khi verify thành công.
enum OtpFlow {
  /// Đến từ đăng ký email → sau khi verify thì đi tiếp điều hướng household.
  register,

  /// Đến từ nâng cấp GUEST → quay lại profile, `household_id`/`role` giữ nguyên.
  upgrade,
}

/// State cho Flow 2, 3, 4, 5, 9 (fe-onboarding.md).
// ignore: library_private_types_in_public_api — mixin application chuẩn của MobX
class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  _AuthStore({
    required GoogleLoginUseCase googleLogin,
    required RegisterUseCase register,
    required SendOtpUseCase sendOtp,
    required VerifyOtpUseCase verifyOtp,
    required EmailLoginUseCase emailLogin,
    required UpgradeProfileUseCase upgradeProfile,
  })  : _googleLogin = googleLogin,
        _register = register,
        _sendOtp = sendOtp,
        _verifyOtp = verifyOtp,
        _emailLogin = emailLogin,
        _upgradeProfile = upgradeProfile;

  /// Cooldown resend OTP phía client — chỉ để giữ nhịp UX. Giới hạn thật của
  /// BE là 3 OTP đang active và trả `ERR_AUTH_OTP_LIMIT`.
  static const Duration resendCooldown = Duration(seconds: 30);

  /// Ước tính phía client cho `ERR_AUTH_RATE_LIMIT`. BE mới là nguồn xác
  /// thực; thử lại sớm chỉ nhận thêm một 429 và xử lý y hệt.
  static const Duration loginLockout = Duration(seconds: 60);

  final GoogleLoginUseCase _googleLogin;
  final RegisterUseCase _register;
  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final EmailLoginUseCase _emailLogin;
  final UpgradeProfileUseCase _upgradeProfile;

  // ── Flow 2: Google ───────────────────────────────────────────────
  @observable
  SubmissionState googleState = const SubmissionIdle();

  /// Toast một lần khi Google UID vừa được link vào email đã tồn tại.
  @observable
  bool showAccountLinkedToast = false;

  // ── Flow 3: Register ─────────────────────────────────────────────
  @observable
  SubmissionState registerState = const SubmissionIdle();

  @observable
  ObservableMap<String, String> registerFieldErrors =
      ObservableMap<String, String>();

  // ── Flow 4: OTP ──────────────────────────────────────────────────
  @observable
  SubmissionState otpState = const SubmissionIdle();

  @observable
  SubmissionState resendState = const SubmissionIdle();

  @observable
  String? pendingEmail;

  @observable
  OtpFlow otpFlow = OtpFlow.register;

  @observable
  DateTime? resendAvailableAt;

  // ── Flow 5: Login ────────────────────────────────────────────────
  @observable
  SubmissionState loginState = const SubmissionIdle();

  @observable
  ObservableMap<String, String> loginFieldErrors =
      ObservableMap<String, String>();

  @observable
  DateTime? loginLockedUntil;

  // ── Flow 9: Upgrade GUEST ────────────────────────────────────────
  @observable
  SubmissionState upgradeState = const SubmissionIdle();

  @observable
  ObservableMap<String, String> upgradeFieldErrors =
      ObservableMap<String, String>();

  /// Ẩn banner nâng cấp trong phiên hiện tại; hiện lại ở lần mở app kế tiếp
  /// (Decision D6).
  @observable
  bool upgradeBannerDismissed = false;

  @computed
  bool get isLoginLocked =>
      loginLockedUntil != null && loginLockedUntil!.isAfter(DateTime.now());

  @computed
  bool get canResendOtp =>
      !resendState.isBusy &&
      (resendAvailableAt == null || resendAvailableAt!.isBefore(DateTime.now()));

  // ── Flow 2 ───────────────────────────────────────────────────────

  /// Trả `true` khi đăng nhập thành công, `false` khi user hủy popup **hoặc**
  /// khi lỗi. Caller phân biệt bằng [googleState]: hủy để state về `idle`
  /// (không phải lỗi, không hiện banner), lỗi để `SubmissionFailure`.
  @action
  Future<bool> signInWithGoogle() async {
    googleState = const SubmissionInProgress();
    try {
      final session = await _googleLogin();
      if (session == null) {
        googleState = const SubmissionIdle(); // user hủy — không phải lỗi
        return false;
      }
      showAccountLinkedToast = session.accountLinked;
      googleState = const SubmissionSuccess();
      return true;
    } catch (error) {
      googleState = SubmissionFailure(toApiException(error));
      return false;
    }
  }

  @action
  void consumeAccountLinkedToast() => showAccountLinkedToast = false;

  @action
  void resetGoogleState() => googleState = const SubmissionIdle();

  // ── Flow 3 ───────────────────────────────────────────────────────

  @action
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final errors = <String, String>{};
    if (!Validators.isValidEmail(email)) errors['email'] = 'invalidEmail';
    if (!Validators.isValidPassword(password)) {
      errors['password'] = 'passwordTooShort';
    }
    if (!Validators.isValidFullName(fullName)) {
      errors['fullName'] = 'fullNameRequired';
    }
    registerFieldErrors = ObservableMap<String, String>.of(errors);
    if (errors.isNotEmpty) {
      registerState = const SubmissionIdle(); // S3.2 — không gọi BE
      return false;
    }

    registerState = const SubmissionInProgress();
    try {
      final result = await _register(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
      );
      pendingEmail = result.email;
      otpFlow = OtpFlow.register;
      _startResendCooldown();
      registerState = const SubmissionSuccess();
      return true;
    } catch (error) {
      final mapped = toApiException(error);
      _applyServerFieldErrors(mapped, registerFieldErrors);
      registerState = SubmissionFailure(mapped);
      return false;
    }
  }

  // ── Flow 4 ───────────────────────────────────────────────────────

  @action
  void prepareOtp({required String email, required OtpFlow flow}) {
    pendingEmail = email;
    otpFlow = flow;
    otpState = const SubmissionIdle();
    resendState = const SubmissionIdle();
    _startResendCooldown();
  }

  @action
  Future<bool> verifyOtp(String otp) async {
    final email = pendingEmail;
    if (email == null || !Validators.isValidOtp(otp)) {
      otpState = SubmissionFailure(
        BusinessException('ERR_AUTH_OTP_INVALID', 'Mã OTP không hợp lệ'),
      );
      return false;
    }

    otpState = const SubmissionInProgress();
    try {
      await _verifyOtp(email: email, otp: otp.trim());
      otpState = const SubmissionSuccess();
      return true;
    } catch (error) {
      otpState = SubmissionFailure(toApiException(error));
      return false;
    }
  }

  @action
  Future<void> resendOtp() async {
    final email = pendingEmail;
    if (email == null || !canResendOtp) return;

    resendState = const SubmissionInProgress();
    try {
      await _sendOtp(email);
      _startResendCooldown();
      resendState = const SubmissionSuccess();
    } catch (error) {
      // ERR_AUTH_OTP_LIMIT (429) → S4.4, banner chờ tĩnh; BE không trả
      // retry-after nên không đếm ngược.
      resendState = SubmissionFailure(toApiException(error));
    }
  }

  // ── Flow 5 ───────────────────────────────────────────────────────

  @action
  Future<bool> login({required String email, required String password}) async {
    if (isLoginLocked) return false;

    final errors = <String, String>{};
    if (!Validators.isValidEmail(email)) errors['email'] = 'invalidEmail';
    if (password.isEmpty) errors['password'] = 'passwordRequired';
    loginFieldErrors = ObservableMap<String, String>.of(errors);
    if (errors.isNotEmpty) {
      loginState = const SubmissionIdle();
      return false;
    }

    loginState = const SubmissionInProgress();
    try {
      await _emailLogin(email: email.trim(), password: password);
      loginState = const SubmissionSuccess();
      return true;
    } catch (error) {
      final mapped = toApiException(error);
      if (mapped.code == 'ERR_AUTH_RATE_LIMIT') {
        loginLockedUntil = DateTime.now().add(loginLockout);
      }
      loginState = SubmissionFailure(mapped);
      return false;
    }
  }

  @action
  void clearLoginLock() => loginLockedUntil = null;

  // ── Flow 9 ───────────────────────────────────────────────────────

  @action
  Future<bool> upgradeProfile({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final errors = <String, String>{};
    if (!Validators.isValidEmail(email)) errors['email'] = 'invalidEmail';
    if (!Validators.isValidPassword(password)) {
      errors['password'] = 'passwordTooShort';
    }
    upgradeFieldErrors = ObservableMap<String, String>.of(errors);
    if (errors.isNotEmpty) {
      upgradeState = const SubmissionIdle();
      return false;
    }

    upgradeState = const SubmissionInProgress();
    try {
      await _upgradeProfile(
        email: email.trim(),
        password: password,
        fullName: fullName?.trim(),
      );
      pendingEmail = email.trim();
      otpFlow = OtpFlow.upgrade;
      _startResendCooldown();
      upgradeState = const SubmissionSuccess();
      return true;
    } catch (error) {
      final mapped = toApiException(error);
      _applyServerFieldErrors(mapped, upgradeFieldErrors);
      upgradeState = SubmissionFailure(mapped);
      return false;
    }
  }

  @action
  void dismissUpgradeBanner() => upgradeBannerDismissed = true;

  /// Xoá sạch state của phiên onboarding.
  ///
  /// Store này đăng ký `permanent` để `pendingEmail` sống được từ màn đăng ký
  /// sang màn OTP, nên nó tồn tại lâu hơn một phiên. Khi phiên kết thúc mà
  /// không dọn, user kế tiếp trên cùng thiết bị sẽ thấy email của user trước
  /// ở màn OTP và vẫn dính khoá 429 của user trước.
  @action
  void reset() {
    googleState = const SubmissionIdle();
    registerState = const SubmissionIdle();
    otpState = const SubmissionIdle();
    resendState = const SubmissionIdle();
    loginState = const SubmissionIdle();
    upgradeState = const SubmissionIdle();
    registerFieldErrors = ObservableMap<String, String>();
    loginFieldErrors = ObservableMap<String, String>();
    upgradeFieldErrors = ObservableMap<String, String>();
    pendingEmail = null;
    otpFlow = OtpFlow.register;
    resendAvailableAt = null;
    loginLockedUntil = null;
    showAccountLinkedToast = false;
    upgradeBannerDismissed = false;
  }

  // ── Nội bộ ───────────────────────────────────────────────────────

  void _startResendCooldown() =>
      resendAvailableAt = DateTime.now().add(resendCooldown);

  /// `ValidationException` mang `fieldErrors` theo từng field — dùng nó thay
  /// vì chỉ hiện `message` dưới dạng toast (fe-onboarding.md S10.5).
  void _applyServerFieldErrors(
    ApiException error,
    ObservableMap<String, String> target,
  ) {
    final fieldErrors = error.fieldErrors;
    if (fieldErrors == null) return;
    target
      ..clear()
      ..addAll(fieldErrors);
  }
}
