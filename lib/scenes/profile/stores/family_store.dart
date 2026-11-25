import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/db/read_cache_dao.dart';
import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../api/family_api.dart';
import '../api/health_api.dart';
import '../../../domain/shared/budget_period.dart';
import '../domain/household_budget.dart';
import '../domain/household_member.dart';
import '../domain/household_roster.dart';
import '../domain/household_tier.dart';
import '../domain/invite_result.dart';
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

  /// Kết quả `createInvite()` gần nhất — giữ trong phiên để mở lại sheet
  /// (S12.9). Đóng sheet KHÔNG xoá giá trị này.
  final Observable<InviteResult?> _lastInvite = Observable<InviteResult?>(null);

  /// Cờ RIÊNG cho xoá thành viên — dialog xoá và sheet mời không dùng chung
  /// cờ (§9).
  final Observable<FormStatus> _removeMemberStatus =
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

  /// `null` = CHƯA TẢI (khác "chưa đặt" — xem [HouseholdBudget.isSet]).
  final Observable<HouseholdBudget?> _budget =
      Observable<HouseholdBudget?>(null);
  final Observable<FormStatus> _budgetLoadStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<FormStatus> _budgetMutationStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _budgetMutationError =
      Observable<ApiException?>(null);
  int _budgetLoadSeq = 0;

  ViewState<HouseholdRoster> get rosterState => _rosterState.value;
  bool get rosterIsFromCache => _rosterIsFromCache.value;
  FormStatus get inviteStatus => _inviteStatus.value;
  InviteResult? get lastInvite => _lastInvite.value;
  FormStatus get removeMemberStatus => _removeMemberStatus.value;
  bool get isRemovingMember =>
      _removeMemberStatus.value == FormStatus.submitting;
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

  HouseholdBudget? get budget => _budget.value;

  /// `submitting` = đang tải. UI PHẢI đọc trạng thái này TRƯỚC [hasBudget] —
  /// tải lỗi không được hiện thành "chưa đặt" (Guard #12, FIX HIGH-A2).
  FormStatus get budgetLoadStatus => _budgetLoadStatus.value;
  bool get hasBudget => _budget.value?.isSet ?? false;

  /// Chỉ mở form đặt/sửa khi ĐÃ biết giá trị hiện tại — tránh upsert ghi đè mù.
  /// Đang có lần ghi chưa xong (sheet bị vuốt đóng giữa chừng) cũng khoá: sheet
  /// mở lại sẽ điền sẵn giá trị CŨ rồi cho "Lưu" đè lên giá trị vừa ghi.
  bool get canEditBudget =>
      isOwner &&
      _budgetLoadStatus.value == FormStatus.success &&
      _budgetMutationStatus.value != FormStatus.submitting;
  FormStatus get budgetMutationStatus => _budgetMutationStatus.value;
  ApiException? get budgetMutationError => _budgetMutationError.value;
  bool get isSubmittingBudget =>
      _budgetMutationStatus.value == FormStatus.submitting;

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

  /// "Mời thành viên" chỉ khi OWNER và roster KHÔNG phải cache (Guard 13).
  bool get canInvite => isOwner && !_rosterIsFromCache.value;

  /// Predicate DUY NHẤT cho nút "Xóa" trên một dòng (Guard 13 + 16): caller
  /// là OWNER, roster không phải cache, không phải chính mình, không phải
  /// dòng OWNER. Chỉ là UX — phân quyền thật ở BE.
  bool canRemove(HouseholdMember m) =>
      isOwner &&
      !_rosterIsFromCache.value &&
      m.userId != _session.currentUser?.id &&
      m.role != 'OWNER';

  String get _rosterCacheKey => 'roster:${_session.householdId}';

  /// [keepCurrent] = nạp lại NỀN: đang có roster thì giữ nguyên tới khi có
  /// kết quả mới, không nháy về Loading (picker giao việc — OD-24).
  Future<void> loadRoster({bool keepCurrent = false}) async {
    if (!keepCurrent || _rosterState.value is! SuccessState<HouseholdRoster>) {
      runInAction(() {
        _rosterState.value = const LoadingState<HouseholdRoster>();
        _rosterIsFromCache.value = false;
      });
    }
    try {
      final roster = await _familyApi.getMyHousehold();
      runInAction(() {
        _rosterState.value = SuccessState<HouseholdRoster>(roster);
        _rosterIsFromCache.value = false;
      });
      unawaited(
          _cache.put(_rosterCacheKey, HouseholdRosterMapper.toJson(roster)));
    } catch (raw) {
      final error = storeApiException(raw);
      // CHỈ mất mạng mới rơi về cache. Lỗi BE (404 ERR_HH_001 …) → ErrorState
      // để FamilyScreen redirect / báo lỗi đúng (§9) — không che bằng cache.
      final cached =
          error is NetworkException ? await _cache.get(_rosterCacheKey) : null;
      if (cached != null) {
        runInAction(() {
          _rosterState.value = SuccessState<HouseholdRoster>(
              HouseholdRosterMapper.fromJson(cached.payload));
          _rosterIsFromCache.value = true;
        });
      } else {
        runInAction(() {
          _rosterState.value = ErrorState<HouseholdRoster>(error);
          _rosterIsFromCache.value = false;
        });
      }
    }
  }

  Future<void> loadMemberSummary(String userId) async {
    runInAction(() =>
        _memberSummaryState.value = const LoadingState<MemberHealthSummary>());
    try {
      final summary = await _healthApi.getMemberHealthSummary(userId);
      runInAction(() => _memberSummaryState.value =
          SuccessState<MemberHealthSummary>(summary));
    } catch (raw) {
      runInAction(() => _memberSummaryState.value =
          ErrorState<MemberHealthSummary>(storeApiException(raw)));
    }
  }

  /// Kết quả (`lastInvite`) BẮT BUỘC được hiển thị (InviteResultSheet,
  /// §10.4 — S12.9).
  Future<bool> createInvite() async {
    if (!canInvite) return false; // Guard 13
    if (_inviteStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _inviteStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      final invite = await _familyApi.createInvite();
      runInAction(() {
        _lastInvite.value = invite;
        _inviteStatus.value = FormStatus.success;
      });
      return true;
    } catch (raw) {
      final error = storeApiException(raw);
      runInAction(() {
        _mutationError.value = error;
        _inviteStatus.value = FormStatus.failure; // 429 ERR_HH_006 — S12.10
      });
      // 403 ERR_HH_004 = caller không còn là OWNER → tải lại để ẩn affordance
      // quản lý (bảng §12).
      if (error.code == 'ERR_HH_004') await loadRoster(keepCurrent: true);
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    // Phòng thủ lớp 2 (Guard 13 + 16): UI đã ẩn nút theo canRemove.
    final roster = _rosterState.value;
    if (roster is! SuccessState<HouseholdRoster>) return false;
    final target =
        roster.data.members.where((m) => m.userId == userId).firstOrNull;
    if (target == null || !canRemove(target)) return false;
    if (_removeMemberStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _removeMemberStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      await _familyApi.removeMember(userId); // 204 No Content
    } catch (raw) {
      final error = storeApiException(raw);
      runInAction(() {
        _mutationError.value = error;
        _removeMemberStatus.value = FormStatus.failure;
      });
      // Mất mạng: không biết server đã xoá chưa — KHÔNG reload (sẽ rơi vào
      // cache). Lỗi BE (ERR_HH_007 / ERR_HH_004): quyền/roster có thể đã đổi
      // → BẮT BUỘC tải lại (S12.6, §14).
      if (error is! NetworkException) await loadRoster(keepCurrent: true);
      return false;
    }
    // BE đã xác nhận xoá (không phải optimistic) → bỏ dòng khỏi roster đang
    // hiển thị ngay, rồi nạp lại nền không nháy Loading (S12.6).
    runInAction(() {
      final current = _rosterState.value;
      if (current is SuccessState<HouseholdRoster>) {
        final r = current.data;
        final members =
            r.members.where((m) => m.userId != userId).toList(growable: false);
        final updated = HouseholdRoster(
          id: r.id,
          name: r.name,
          ownerId: r.ownerId,
          callerRole: r.callerRole,
          memberCount: members.length,
          members: members,
        );
        _rosterState.value = SuccessState<HouseholdRoster>(updated);
        // Cache cũng bỏ dòng đã xoá — nạp nền lỗi mạng không hồi sinh nó.
        unawaited(
            _cache.put(_rosterCacheKey, HouseholdRosterMapper.toJson(updated)));
      }
    });
    // GIỮ `submitting` tới khi nạp lại xong: nút Xóa/Huỷ còn khoá, bấm lần 2
    // không gọi lại với dòng đã biến mất rồi toast lỗi sai (review #29 M3).
    await loadRoster(keepCurrent: true);
    runInAction(() => _removeMemberStatus.value = FormStatus.success);
    return true;
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

  /// Pipeline ĐỘC LẬP với roster: lỗi ở đây không đụng [rosterState].
  Future<void> loadBudget() async {
    final seq = ++_budgetLoadSeq;
    runInAction(() => _budgetLoadStatus.value = FormStatus.submitting);
    try {
      final b = await _familyApi.getBudget();
      if (seq != _budgetLoadSeq) return;
      runInAction(() {
        _budget.value = b;
        _budgetLoadStatus.value = FormStatus.success;
      });
    } catch (_) {
      if (seq != _budgetLoadSeq) return;
      // 404 ERR_HH_001 / network: cùng 1 hành vi P2 — giữ `budget` cũ (nếu
      // có) nhưng UI không coi là "chưa đặt".
      runInAction(() => _budgetLoadStatus.value = FormStatus.failure);
    }
  }

  Future<bool> upsertBudget(BudgetPeriod period, double amount) async {
    if (_budgetMutationStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _budgetMutationStatus.value = FormStatus.submitting;
      _budgetMutationError.value = null;
    });
    try {
      final b = await _familyApi.upsertBudget(period: period, amount: amount);
      runInAction(() {
        _budgetLoadSeq++; // response mới nhất thắng mọi lần tải đang bay
        _budget.value = b;
        _budgetLoadStatus.value = FormStatus.success;
        _budgetMutationStatus.value = FormStatus.success;
      });
      return true;
    } catch (raw) {
      runInAction(() {
        _budgetMutationError.value = storeApiException(raw);
        _budgetMutationStatus.value = FormStatus.failure;
      });
      return false;
    }
  }

  void clearBudgetMutationStatus() => runInAction(() {
        if (_budgetMutationStatus.value == FormStatus.submitting) return;
        _budgetMutationStatus.value = FormStatus.idle;
        _budgetMutationError.value = null;
      });

  void clearInviteError() => runInAction(() {
        if (_inviteStatus.value == FormStatus.submitting) return;
        _inviteStatus.value = FormStatus.idle;
      });

  void clearRemoveMemberError() => runInAction(() {
        if (_removeMemberStatus.value == FormStatus.submitting) return;
        _removeMemberStatus.value = FormStatus.idle;
      });
}
