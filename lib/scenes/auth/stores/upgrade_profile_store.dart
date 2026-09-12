import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../api/auth_api.dart';
import 'auth_store.dart';
import 'form_status.dart';
import 'store_error.dart';

class UpgradeProfileStore {
  UpgradeProfileStore(this._api, this._session);

  final AuthApi _api;
  final SessionStore _session;
  final Observable<FormStatus> _status = Observable(FormStatus.idle);
  final Observable<ApiException?> _error = Observable(null);
  final ObservableMap<String, String> fieldErrors = ObservableMap();

  FormStatus get status => _status.value;
  ApiException? get error => _error.value;
  bool get isSubmitting => status == FormStatus.submitting;

  Future<bool> submit({required String email, required String password, String? fullName}) async {
    if (isSubmitting) return false;
    runInAction(() {
      fieldErrors.clear();
      if (!AuthStore.isValidEmail(email)) fieldErrors['email'] = 'auth_email_invalid';
      if (password.length < 8) fieldErrors['password'] = 'auth_password_short';
      if (fullName != null && fullName.trim().length > 100) fieldErrors['fullName'] = 'auth_name_too_long';
    });
    if (fieldErrors.isNotEmpty) return false;
    runInAction(() {
      _status.value = FormStatus.submitting;
      _error.value = null;
    });
    try {
      final result = await _api.upgrade(email: email.trim(), password: password, fullName: fullName);
      await _session.replaceTokens(accessToken: result.accessToken, refreshToken: result.refreshToken);
      runInAction(() => _status.value = FormStatus.success);
      return result.requiresOtp;
    } catch (raw) {
      final exception = storeApiException(raw);
      runInAction(() {
        _error.value = exception;
        _status.value = FormStatus.failure;
        if (exception.code == 'ERR_AUTH_003') fieldErrors['email'] = 'auth_email_exists';
      });
      return false;
    }
  }
}
