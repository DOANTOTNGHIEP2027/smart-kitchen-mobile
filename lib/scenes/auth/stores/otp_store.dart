import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../api/auth_api.dart';
import 'form_status.dart';
import 'store_error.dart';

enum OtpFlow { register, upgrade }

class OtpStore {
  OtpStore(this._api, this._session, {required this.email, required this.flow}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final AuthApi _api;
  final SessionStore _session;
  final String email;
  final OtpFlow flow;
  final Observable<FormStatus> _status = Observable(FormStatus.idle);
  final Observable<ApiException?> _error = Observable(null);
  final Observable<int> _ttlSeconds = Observable(600);
  final Observable<int> _cooldownSeconds = Observable(30);
  Timer? _timer;

  FormStatus get status => _status.value;
  ApiException? get error => _error.value;
  int get ttlSeconds => _ttlSeconds.value;
  int get cooldownSeconds => _cooldownSeconds.value;
  bool get canResend => cooldownSeconds == 0 && status != FormStatus.submitting;
  bool get isSubmitting => status == FormStatus.submitting;

  Future<bool> verify(String otp) async {
    if (isSubmitting) return false;
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      runInAction(() => _error.value = const BusinessException('ERR_AUTH_OTP_INVALID', 'OTP must contain six digits'));
      return false;
    }
    _begin();
    try {
      final session = await _api.verifyOtp(email: email, otp: otp);
      await _session.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken, user: session.user);
      runInAction(() => _status.value = FormStatus.success);
      return true;
    } catch (raw) {
      _fail(raw);
      return false;
    }
  }

  Future<bool> resend() async {
    if (!canResend) return false;
    _begin();
    try {
      await _api.sendOtp(email);
      runInAction(() {
        _status.value = FormStatus.idle;
        _ttlSeconds.value = 600;
        _cooldownSeconds.value = 30;
      });
      return true;
    } catch (raw) {
      _fail(raw);
      return false;
    }
  }

  void _begin() => runInAction(() {
        _status.value = FormStatus.submitting;
        _error.value = null;
      });

  void _fail(Object raw) => runInAction(() {
        _error.value = storeApiException(raw);
        _status.value = FormStatus.failure;
      });

  void _tick() => runInAction(() {
        if (_ttlSeconds.value > 0) _ttlSeconds.value--;
        if (_cooldownSeconds.value > 0) _cooldownSeconds.value--;
      });

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
