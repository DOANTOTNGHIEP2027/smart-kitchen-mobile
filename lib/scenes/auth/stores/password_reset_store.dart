import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../api/auth_api.dart';
import 'auth_store.dart';
import 'form_status.dart';
import 'store_error.dart';

/// Store cho luồng quên / đặt lại mật khẩu (2 bước: forgot → reset).
///
/// Không tái dùng [OtpStore] vì nó gắn chặt với việc cấp JWT
/// (`SessionStore.setSession`) và hai flow register/upgrade. Store này **không**
/// lưu session: reset mật khẩu thành công chỉ quay về màn đăng nhập.
class PasswordResetStore {
  PasswordResetStore(this._api, {this.email = ''}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final AuthApi _api;

  /// Email được giữ giữa bước forgot và reset.
  String email;

  final Observable<FormStatus> _forgotStatus = Observable(FormStatus.idle);
  final Observable<FormStatus> _resetStatus = Observable(FormStatus.idle);
  final Observable<ApiException?> _error = Observable(null);
  final ObservableMap<String, String> fieldErrors = ObservableMap();
  final Observable<int> _ttlSeconds = Observable(600);
  // 60s — khớp cooldown server-side (OtpServiceImpl.RESEND_COOLDOWN_SECONDS,
  // OD-49) để nút "Gửi lại" chỉ mở khi BE thực sự cho phép gửi.
  final Observable<int> _cooldownSeconds = Observable(0);
  final Observable<int> _lockSeconds = Observable(0);
  Timer? _timer;

  FormStatus get forgotStatus => _forgotStatus.value;
  FormStatus get resetStatus => _resetStatus.value;
  ApiException? get error => _error.value;
  int get ttlSeconds => _ttlSeconds.value;
  int get cooldownSeconds => _cooldownSeconds.value;
  int get lockSeconds => _lockSeconds.value;
  bool get isLocked => lockSeconds > 0;
  bool get isSubmitting => forgotStatus == FormStatus.submitting || resetStatus == FormStatus.submitting;
  bool get canResend => cooldownSeconds == 0 && !isSubmitting && !isLocked;

  /// Bước 1: yêu cầu OTP cho [email].
  ///
  /// Contract BE luôn trả 200 cho mọi email (chống enumeration), kể cả khi đang
  /// trong cooldown. Vì vậy không có nhánh lỗi 429 cho bước này.
  Future<bool> requestOtp(String email) async {
    if (isSubmitting) return false;
    final trimmed = email.trim();
    runInAction(() {
      fieldErrors.clear();
      _error.value = null;
      _forgotStatus.value = FormStatus.submitting;
    });
    if (!AuthStore.isValidEmail(trimmed)) {
      runInAction(() {
        fieldErrors['email'] = 'auth_email_invalid';
        _forgotStatus.value = FormStatus.failure;
      });
      return false;
    }
    try {
      await _api.forgotPassword(trimmed);
      runInAction(() {
        this.email = trimmed;
        _forgotStatus.value = FormStatus.success;
        _ttlSeconds.value = 600;
        _cooldownSeconds.value = 60;
      });
      return true;
    } catch (raw) {
      _fail(raw, _forgotStatus);
      return false;
    }
  }

  /// Bước 2a: gửi lại OTP cho [email] đã lưu. FE tự chặn bằng cooldown cục bộ.
  Future<bool> resendOtp() async {
    if (!canResend || email.isEmpty) return false;
    runInAction(() => _error.value = null);
    try {
      await _api.forgotPassword(email);
      runInAction(() {
        _ttlSeconds.value = 600;
        _cooldownSeconds.value = 60;
      });
      return true;
    } catch (raw) {
      runInAction(() {
        final exception = storeApiException(raw);
        if (_isLimit(exception.code)) {
          _cooldownSeconds.value = 60;
        } else {
          _error.value = exception;
        }
      });
      return false;
    }
  }

  /// Bước 2b: xác thực OTP + đặt mật khẩu mới.
  ///
  /// [confirmPassword] tuỳ chọn: khi scene truyền vào, store kiểm tra khớp và
  /// báo lỗi ở `fieldErrors['confirmPassword']`.
  Future<bool> reset({required String otp, required String newPassword, String? confirmPassword}) async {
    if (isSubmitting) return false;
    final errors = <String, String>{};
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) errors['otp'] = 'otp_invalid';
    if (newPassword.length < 8) errors['newPassword'] = 'auth_password_short';
    if (confirmPassword != null && confirmPassword != newPassword) {
      errors['confirmPassword'] = 'auth_password_mismatch';
    }
    if (errors.isNotEmpty) {
      runInAction(() {
        fieldErrors.clear();
        fieldErrors.addAll(errors);
        _resetStatus.value = FormStatus.failure;
      });
      return false;
    }
    runInAction(() {
      fieldErrors.clear();
      _error.value = null;
      _resetStatus.value = FormStatus.submitting;
    });
    try {
      await _api.resetPassword(email: email, otp: otp, newPassword: newPassword);
      runInAction(() => _resetStatus.value = FormStatus.success);
      return true;
    } catch (raw) {
      _fail(raw, _resetStatus, otpField: true);
      return false;
    }
  }

  void _fail(Object raw, Observable<FormStatus> target, {bool otpField = false}) {
    final exception = storeApiException(raw);
    runInAction(() {
      _error.value = exception;
      target.value = FormStatus.failure;
      if (otpField && exception.code == 'ERR_AUTH_OTP_INVALID') fieldErrors['otp'] = 'otp_invalid';
      if (_isLimit(exception.code)) _lockSeconds.value = 60;
      if (exception.fieldErrors case final serverErrors?) fieldErrors.addAll(serverErrors);
    });
  }

  bool _isLimit(String code) => code == 'ERR_AUTH_OTP_LIMIT' || code == 'ERR_AUTH_RATE_LIMIT';

  void _tick() => runInAction(() {
        if (_ttlSeconds.value > 0) _ttlSeconds.value--;
        if (_cooldownSeconds.value > 0) _cooldownSeconds.value--;
        if (_lockSeconds.value > 0) _lockSeconds.value--;
      });

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
