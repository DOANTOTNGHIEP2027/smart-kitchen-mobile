import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/db/read_cache_dao.dart';
import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../api/family_api.dart';
import '../api/health_api.dart';
import '../domain/household_roster.dart';
import '../domain/member_health_summary.dart';
import '../domain/profile_mappers.dart';
import 'form_status.dart';
import 'store_error.dart';

class FamilyStore {
  FamilyStore(this._familyApi, this._healthApi, this._cache, this._session);

  final FamilyApi _familyApi;
  final HealthApi _healthApi;
  final ReadCacheDao _cache;
  final SessionStore _session;

  final Observable<ViewState<HouseholdRoster>> _rosterState =
      Observable<ViewState<HouseholdRoster>>(
          const LoadingState<HouseholdRoster>());
  final Observable<bool> _rosterIsFromCache = Observable<bool>(false);
  final Observable<FormStatus> _inviteStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ViewState<MemberHealthSummary>> _memberSummaryState =
      Observable<ViewState<MemberHealthSummary>>(
          const LoadingState<MemberHealthSummary>());
  final Observable<ApiException?> _mutationError =
      Observable<ApiException?>(null);

  ViewState<HouseholdRoster> get rosterState => _rosterState.value;
  bool get rosterIsFromCache => _rosterIsFromCache.value;
  FormStatus get inviteStatus => _inviteStatus.value;
  ViewState<MemberHealthSummary> get memberSummaryState =>
      _memberSummaryState.value;
  ApiException? get mutationError => _mutationError.value;

  /// `rosterState.data.callerRole` ưu tiên (tươi hơn JWT). Fallback về
  /// `SessionStore.role` chỉ khi roster chưa load xong (Fix MODERATE-2).
  bool get isOwner {
    final roster = _rosterState.value;
    if (roster is SuccessState<HouseholdRoster>) {
      return roster.data.callerRole == 'OWNER';
    }
    return _session.role == 'OWNER';
  }

  String get _rosterCacheKey => 'roster:${_session.householdId}';

  Future<void> loadRoster() async {
    runInAction(() {
      _rosterState.value = const LoadingState<HouseholdRoster>();
      _rosterIsFromCache.value = false;
    });
    try {
      final roster = await _familyApi.getMyHousehold();
      runInAction(() {
        _rosterState.value = SuccessState<HouseholdRoster>(roster);
        _rosterIsFromCache.value = false;
      });
      unawaited(_cache.put(_rosterCacheKey, HouseholdRosterMapper.toJson(roster)));
    } catch (raw) {
      final cached = await _cache.get(_rosterCacheKey);
      if (cached != null) {
        runInAction(() {
          _rosterState.value = SuccessState<HouseholdRoster>(
              HouseholdRosterMapper.fromJson(cached.payload));
          _rosterIsFromCache.value = true;
        });
      } else {
        runInAction(() => _rosterState.value =
            ErrorState<HouseholdRoster>(storeApiException(raw)));
      }
    }
  }

  Future<void> loadMemberSummary(String userId) async {
    runInAction(() => _memberSummaryState.value =
        const LoadingState<MemberHealthSummary>());
    try {
      final summary = await _healthApi.getMemberHealthSummary(userId);
      runInAction(() => _memberSummaryState.value =
          SuccessState<MemberHealthSummary>(summary));
    } catch (raw) {
      runInAction(() => _memberSummaryState.value =
          ErrorState<MemberHealthSummary>(storeApiException(raw)));
    }
  }

  Future<bool> createInvite() async {
    if (_inviteStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _inviteStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      await _familyApi.createInvite();
      runInAction(() => _inviteStatus.value = FormStatus.success);
      return true;
    } catch (raw) {
      runInAction(() {
        _mutationError.value = storeApiException(raw);
        _inviteStatus.value = FormStatus.failure;
      });
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    if (_inviteStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _inviteStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      await _familyApi.removeMember(userId);
      runInAction(() => _inviteStatus.value = FormStatus.success);
      await loadRoster();
      return true;
    } catch (raw) {
      runInAction(() {
        _mutationError.value = storeApiException(raw);
        _inviteStatus.value = FormStatus.failure;
      });
      return false;
    }
  }

  void clearInviteError() =>
      runInAction(() => _inviteStatus.value = FormStatus.idle);
}
