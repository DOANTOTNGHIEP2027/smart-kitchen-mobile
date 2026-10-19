import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/db/read_cache_dao.dart';
import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../api/family_api.dart';
import '../api/health_api.dart';
import '../domain/household_member.dart';
import '../domain/household_roster.dart';
import '../domain/household_tier.dart';
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
  final Observable<FormStatus> _changeRoleStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _changeRoleError =
      Observable<ApiException?>(null);
  final Observable<FormStatus> _tierUpdateStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _tierUpdateError =
      Observable<ApiException?>(null);

  ViewState<HouseholdRoster> get rosterState => _rosterState.value;
  bool get rosterIsFromCache => _rosterIsFromCache.value;
  FormStatus get inviteStatus => _inviteStatus.value;
  ViewState<MemberHealthSummary> get memberSummaryState =>
      _memberSummaryState.value;
  ApiException? get mutationError => _mutationError.value;
  FormStatus get changeRoleStatus => _changeRoleStatus.value;
  bool get isSubmittingChangeRole =>
      _changeRoleStatus.value == FormStatus.submitting;
  bool get isSubmittingTierUpdate =>
      _tierUpdateStatus.value == FormStatus.submitting;
  ApiException? get changeRoleError => _changeRoleError.value;
  FormStatus get tierUpdateStatus => _tierUpdateStatus.value;
  ApiException? get tierUpdateError => _tierUpdateError.value;

  /// `403 ERR_TIER_SEAT_LIMIT` — quyết định dứt khoát của BE (Guard 1).
  bool get isSeatLimitError =>
      _changeRoleStatus.value == FormStatus.failure &&
      _changeRoleError.value?.code == 'ERR_TIER_SEAT_LIMIT';

  String? get currentUserId => _session.currentUser?.id;

  /// Tier đọc từ JWT claim (Guard 5 — roster không có tier).
  HouseholdTier get tier => HouseholdTier.fromApi(_session.tier);

  /// Hint số ghế Remote Viewer — `null` khi roster chưa tải. KHÔNG dùng để
  /// chặn cứng (Guard 1).
  RemoteViewerSeatInfo? get seatInfo {
    final roster = _rosterState.value;
    if (roster is! SuccessState<HouseholdRoster>) return null;
    return RemoteViewerSeatInfo(
      used: roster.data.members.where((m) => m.isRemoteViewer).length,
      tier: tier,
    );
  }

  /// Tra role từ roster đã tải (health-summary không trả role) — tier-gate §11.
  bool isMemberRemoteViewer(String userId) {
    final roster = _rosterState.value;
    if (roster is! SuccessState<HouseholdRoster>) return false;
    return roster.data.members
        .any((m) => m.userId == userId && m.isRemoteViewer);
  }

  /// Cùng thứ tự ưu tiên với [isOwner]: roster trước, JWT sau.
  bool get isRemoteViewer => _callerRole == 'REMOTE_VIEWER';

  /// `rosterState.data.callerRole` ưu tiên (tươi hơn JWT). Fallback về
  /// `SessionStore.role` chỉ khi roster chưa load xong (Fix MODERATE-2).
  bool get isOwner => _callerRole == 'OWNER';

  String? get _callerRole {
    final roster = _rosterState.value;
    return roster is SuccessState<HouseholdRoster>
        ? roster.data.callerRole
        : _session.role;
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

  /// `role` CHỈ 'MEMBER' | 'REMOTE_VIEWER' (Guard 3). Thành công → tải lại
  /// roster như [removeMember].
  Future<bool> changeRole(String userId, String role) async {
    if (_changeRoleStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _changeRoleStatus.value = FormStatus.submitting;
      _changeRoleError.value = null;
    });
    try {
      await _familyApi.changeRole(userId, role);
      // Giữ `submitting` tới khi roster tải lại xong — nếu báo success trước,
      // nút Xác nhận mở lại giữa chừng và có thể gửi/pop sheet lần hai.
      await loadRoster();
      runInAction(() => _changeRoleStatus.value = FormStatus.success);
      return true;
    } catch (raw) {
      runInAction(() {
        _changeRoleError.value = storeApiException(raw);
        _changeRoleStatus.value = FormStatus.failure;
      });
      return false;
    }
  }

  /// Thành công → PHẢI `await` refresh claim trước khi báo success, để màn
  /// hình đọc `SessionStore.tier` mới ngay (Guard 4). `refreshClaims()` tự
  /// nuốt lỗi nên không làm hỏng kết quả mutation.
  Future<bool> updateTier(HouseholdTier target) async {
    if (_tierUpdateStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _tierUpdateStatus.value = FormStatus.submitting;
      _tierUpdateError.value = null;
    });
    try {
      final result = await _familyApi.updateTier(target);
      if (result.requiresTokenRefresh) {
        await _session.refreshClaims();
      }
      runInAction(() => _tierUpdateStatus.value = FormStatus.success);
      return true;
    } catch (raw) {
      runInAction(() {
        _tierUpdateError.value = storeApiException(raw);
        _tierUpdateStatus.value = FormStatus.failure;
      });
      return false;
    }
  }

  void clearChangeRoleStatus() => runInAction(() {
        if (_changeRoleStatus.value == FormStatus.submitting) return;
        _changeRoleStatus.value = FormStatus.idle;
        _changeRoleError.value = null;
      });

  void clearTierUpdateStatus() => runInAction(() {
        if (_tierUpdateStatus.value == FormStatus.submitting) return;
        _tierUpdateStatus.value = FormStatus.idle;
        _tierUpdateError.value = null;
      });

  void clearInviteError() =>
      runInAction(() => _inviteStatus.value = FormStatus.idle);
}
