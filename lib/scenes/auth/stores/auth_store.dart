import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/auth/google_auth_gateway.dart';
import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../api/auth_api.dart';
import 'form_status.dart';
import 'store_error.dart';

class AuthStore {
  AuthStore(this._api, this._session, this._googleGateway);

  final AuthApi _api;
  final SessionStore _session;
  final GoogleAuthGateway _googleGateway;

  final Observable<FormStatus> _status = Observable(FormStatus.idle);
  final Observable<ApiException?> _error = Observable(null);
  final Observable<int> _loginLockSeconds = Observable(0);
  final Observable<bool> _accountLinked = Observable(false);
  final ObservableMap<String, String> fieldErrors = ObservableMap();
  Map<String, String>? _lastRegisterPayload;
  Map<String, String>? _lastLoginPayload;

  FormStatus get status => _status.value;
  ApiException? get error => _error.value;
  bool get isSubmitting => status == FormStatus.submitting;
  int get loginLockSeconds => _loginLockSeconds.value;
  bool get isLoginLocked => loginLockSeconds > 0;
  bool get accountLinked => _accountLinked.value;
  Timer? _loginLockTimer;

  static bool isValidEmail(String value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  bool validateCredentials({required String email, required String password, String? fullName}) {
    runInAction(() {
      fieldErrors.clear();
      if (!isValidEmail(email)) fieldErrors['email'] = 'auth_email_invalid';
      if (password.length < 8) fieldErrors['password'] = 'auth_password_short';
      if (fullName != null && fullName.trim().isEmpty) fieldErrors['fullName'] = 'auth_name_required';
      if (fullName != null && fullName.trim().length > 100) fieldErrors['fullName'] = 'auth_name_too_long';
    });
    return fieldErrors.isEmpty;
  }

  Future<String?> register({required String email, required String password, required String fullName}) async {
    if (isSubmitting || !validateCredentials(email: email, password: password, fullName: fullName)) return null;
    _lastRegisterPayload = {'email': email.trim(), 'password': password, 'fullName': fullName.trim()};
    _begin();
    try {
      final result = await _api.register(
        email: _lastRegisterPayload!['email']!,
        password: _lastRegisterPayload!['password']!,
        fullName: _lastRegisterPayload!['fullName']!,
      );
      runInAction(() => _status.value = FormStatus.success);
      return result.email;
    } catch (error) {
      _fail(error, emailConflict: true);
      return null;
    }
  }

  Future<String?> retryRegister() async {
    final payload = _lastRegisterPayload;
    if (payload == null) return null;
    return register(email: payload['email']!, password: payload['password']!, fullName: payload['fullName']!);
  }

  Future<bool> login({required String email, required String password}) async {
    if (isSubmitting || isLoginLocked || !validateCredentials(email: email, password: password)) return false;
    _lastLoginPayload = {'email': email.trim(), 'password': password};
    _begin();
    try {
      final session = await _api.login(email: email.trim(), password: password);
      await _session.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken, user: session.user);
      runInAction(() => _status.value = FormStatus.success);
      return true;
    } catch (error) {
      _fail(error);
      return false;
    }
  }

  Future<bool> retryLogin() async {
    final payload = _lastLoginPayload;
    if (payload == null) return false;
    return login(email: payload['email']!, password: payload['password']!);
  }

  Future<bool> googleSignIn() async {
    if (isSubmitting) return false;
    _begin();
    try {
      final idToken = await _googleGateway.signInWithGoogle();
      if (idToken == null) {
        reset();
        return false;
      }
      final session = await _api.loginWithGoogle(idToken);
      await _session.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken, user: session.user);
      runInAction(() {
        _accountLinked.value = session.accountLinked;
        _status.value = FormStatus.success;
      });
      return true;
    } catch (error) {
      _fail(error);
      return false;
    }
  }

  void _begin() => runInAction(() {
        _status.value = FormStatus.submitting;
        _error.value = null;
        fieldErrors.clear();
      });

  void _fail(Object raw, {bool emailConflict = false}) {
    final exception = storeApiException(raw);
    runInAction(() {
      _error.value = exception;
      _status.value = FormStatus.failure;
      if (emailConflict && exception.code == 'ERR_AUTH_003') fieldErrors['email'] = 'auth_email_exists';
      if (exception.code == 'ERR_AUTH_004') fieldErrors['password'] = 'auth_bad_credentials';
      if (exception.code == 'ERR_AUTH_RATE_LIMIT') _startLoginLock();
      if (exception.fieldErrors case final serverErrors?) fieldErrors.addAll(serverErrors);
    });
  }

  void reset() => runInAction(() {
        _loginLockTimer?.cancel();
        _status.value = FormStatus.idle;
        _error.value = null;
        _loginLockSeconds.value = 0;
        _accountLinked.value = false;
        fieldErrors.clear();
      });

  void _startLoginLock() {
    _loginLockTimer?.cancel();
    _loginLockSeconds.value = 60;
    _loginLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      runInAction(() {
        if (_loginLockSeconds.value > 0) _loginLockSeconds.value--;
        if (_loginLockSeconds.value == 0) timer.cancel();
      });
    });
  }

  void dispose() => _loginLockTimer?.cancel();
}
