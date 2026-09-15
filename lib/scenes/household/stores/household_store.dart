import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../../auth/api/auth_api.dart';
import '../../auth/stores/form_status.dart';
import '../../auth/stores/store_error.dart';
import '../api/household_api.dart';
import '../domain/household_models.dart';

class HouseholdStore {
  HouseholdStore(this._api, this._authApi, this._session);

  final HouseholdApi _api;
  final AuthApi _authApi;
  final SessionStore _session;
  final Observable<FormStatus> _status = Observable(FormStatus.idle);
  final Observable<ApiException?> _error = Observable(null);
  final Observable<ViewState<InvitePreview>> _previewState =
      Observable(const EmptyState());
  final Observable<HouseholdCreated?> _created = Observable(null);
  String? _lastPreviewCode;

  FormStatus get status => _status.value;
  ApiException? get error => _error.value;
  ViewState<InvitePreview> get previewState => _previewState.value;
  HouseholdCreated? get created => _created.value;
  bool get isSubmitting => status == FormStatus.submitting;

  Future<bool> create(String name) async {
    final value = name.trim();
    if (isSubmitting || value.isEmpty || value.length > 255) return false;
    _begin();
    try {
      final result = await _api.create(value);
      _session.applyHouseholdContext(householdId: result.id, role: 'OWNER');
      runInAction(() {
        _created.value = result;
        _status.value = FormStatus.success;
      });
      return true;
    } catch (raw) {
      _fail(raw);
      if (_error.value?.code == 'ERR_HH_003') {
        try {
          await _session.refreshSession();
        } catch (_) {
          // The next authenticated request/bootstrap will resolve the stale claim.
        }
      }
      return false;
    }
  }

  Future<void> preview(String rawCode) async {
    final code = normalizeInviteCode(rawCode);
    _lastPreviewCode = code;
    if (code.length != 8) {
      runInAction(() => _previewState.value = ErrorState(
          BusinessException('ERR_HH_002', 'Invalid invite code')));
      return;
    }
    runInAction(() => _previewState.value = const LoadingState());
    try {
      final preview = await _api.preview(code);
      runInAction(() => _previewState.value = preview.isValid
          ? SuccessState(preview)
          : ErrorState(
              BusinessException('ERR_HH_002', 'Invalid invite code')));
    } catch (raw) {
      runInAction(
          () => _previewState.value = ErrorState(storeApiException(raw)));
    }
  }

  Future<bool> retryPreview() async {
    if (_lastPreviewCode == null) return false;
    await preview(_lastPreviewCode!);
    return previewState is SuccessState<InvitePreview>;
  }

  Future<bool> join({String? displayName}) async {
    if (isSubmitting || _lastPreviewCode == null) return false;
    if (_session.status == AuthStatus.authenticated &&
        _session.householdId != null) {
      _fail(BusinessException('CLIENT_ALREADY_IN_HOUSEHOLD',
          'User already belongs to a household'));
      return false;
    }
    _begin();
    try {
      if (_session.status == AuthStatus.authenticated) {
        final result = await _api.join(_lastPreviewCode!);
        if (result.requiresTokenRefresh) {
          await _session.refreshSession();
        } else {
          _session.applyHouseholdContext(
              householdId: result.householdId, role: result.role);
        }
      } else {
        final result = await _authApi.joinAsGuest(
            inviteCode: _lastPreviewCode!, displayName: displayName);
        await _session.setSession(
          accessToken: result.session.accessToken,
          refreshToken: result.session.refreshToken,
          user: result.session.user,
        );
      }
      runInAction(() => _status.value = FormStatus.success);
      return true;
    } catch (raw) {
      _fail(raw);
      return false;
    }
  }

  static String normalizeInviteCode(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

  void _begin() => runInAction(() {
        _status.value = FormStatus.submitting;
        _error.value = null;
      });

  void _fail(Object raw) => runInAction(() {
        _error.value = raw is ApiException ? raw : storeApiException(raw);
        _status.value = FormStatus.failure;
      });

  void resetMutation() => runInAction(() {
        _status.value = FormStatus.idle;
        _error.value = null;
        _created.value = null;
        _previewState.value = const EmptyState();
        _lastPreviewCode = null;
      });
}
