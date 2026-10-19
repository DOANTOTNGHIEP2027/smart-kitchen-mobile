import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../profile/domain/household_tier.dart';
import '../data/recap_api.dart';
import '../domain/household_streak.dart';
import '../domain/weekly_recap_summary.dart';

/// Trạng thái fetch nhánh con của màn hình Weekly Recap (weekly-recap-screen.md
/// §10) — MobX thủ công (Observable + runInAction).
enum RecapLoadStatus { loading, noHousehold, empty, error, ready }

/// 3 nhánh hiển thị chi tiết chi tiêu PREMIUM (weekly-recap §17.3).
enum SpendDetailGate {
  /// BE đã trả `spendByCategory`.
  unlocked,

  /// BE gate + claim KHÔNG phải PREMIUM → mời nâng cấp.
  lockedUpsell,

  /// BE gate NHƯNG claim là PREMIUM (claim lệch/vừa hạ cấp) → KHÔNG mời.
  lockedNeutral,
}

/// State + actions cho `WeeklyRecapScreen` — hero + household stats +
/// InsightCard + streak counter (weekly-recap-screen.md §10).
class WeeklyRecapStore {
  WeeklyRecapStore(
    this._recapApi,
    this._sessionStore,
  ) {
    fetchAll();
  }

  final RecapApi _recapApi;
  final SessionStore _sessionStore;

  String? get _selfId => _sessionStore.currentUser?.id;

  final Observable<WeeklyRecapSummary?> _summary = Observable<WeeklyRecapSummary?>(null);
  final Observable<HouseholdStreak?> _streak = Observable<HouseholdStreak?>(null);
  final Observable<RecapLoadStatus> _status =
      Observable<RecapLoadStatus>(RecapLoadStatus.loading);
  final Observable<RecapLoadStatus> _streakStatus =
      Observable<RecapLoadStatus>(RecapLoadStatus.loading);
  final Observable<ApiException?> _error = Observable<ApiException?>(null);

  // ── Getters ──────────────────────────────────────────────────────────────

  WeeklyRecapSummary? get summary => _summary.value;
  HouseholdStreak? get streak => _streak.value;
  RecapLoadStatus get status => _status.value;
  RecapLoadStatus get streakStatus => _streakStatus.value;
  ApiException? get error => _error.value;

  bool get isLoading =>
      _status.value == RecapLoadStatus.loading ||
      _streakStatus.value == RecapLoadStatus.loading;

  bool get isNoHousehold => _status.value == RecapLoadStatus.noHousehold;

  /// Insight của CHÍNH người xem (khớp `memberId == self`) — hero dùng badge
  /// này, KHÔNG tự tổng hợp badge household (decision-log D1).
  MemberWeeklyInsight? get ownInsight {
    if (_selfId == null) return null;
    final members = _summary.value?.memberInsights ?? const <MemberWeeklyInsight>[];
    for (final m in members) {
      if (m.memberId == _selfId) return m;
    }
    return null;
  }

  /// Danh sách InsightCard theo thứ tự BE trả — bao gồm self (nếu có),
  /// KHÔNG ẩn self (decision-log D4).
  List<MemberWeeklyInsight> get orderedMemberInsights =>
      _summary.value?.memberInsights ?? const <MemberWeeklyInsight>[];

  /// Nội dung PREMIUM do BE quyết (`spendByCategory == null` ⟺ đã gate); claim
  /// `tier` CHỈ chọn câu chữ của khối thay thế (Guard #14, #20).
  SpendDetailGate? get spendDetailGate {
    final s = _summary.value;
    if (s == null) return null;
    if (s.spendByCategory != null) return SpendDetailGate.unlocked;
    return HouseholdTier.fromApi(_sessionStore.tier) == HouseholdTier.premium
        ? SpendDetailGate.lockedNeutral
        : SpendDetailGate.lockedUpsell;
  }

  /// Soft hint cho CTA "Đặt ngân sách" — quyền thật do BE (403 ERR_HH_004).
  /// Đọc thẳng JWT role là ngoại lệ có chủ đích (§17.3, D17): không kéo
  /// FamilyStore vào module recap.
  bool get canSetBudget => _sessionStore.role == 'OWNER';

  // ── Actions ──────────────────────────────────────────────────────────────

  /// 2 nhóm fetch ĐỘC LẬP (weekly + streak). Lỗi 1 nhóm KHÔNG chặn nhóm kia
  /// (Guard #7). Trước khi gọi API, guard client-side `householdId == null`
  /// (Guard #9) và `currentUser?.id == null` (Guard #11).
  Future<void> fetchAll() async {
    if (_sessionStore.householdId == null) {
      runInAction(() {
        _status.value = RecapLoadStatus.noHousehold;
        _streakStatus.value = RecapLoadStatus.error;
        _summary.value = null;
        _streak.value = null;
      });
      return;
    }
    runInAction(() {
      _status.value = RecapLoadStatus.loading;
      if (_streakStatus.value != RecapLoadStatus.error) {
        _streakStatus.value = RecapLoadStatus.loading;
      }
    });
    await Future.wait<dynamic>([
      _fetchRecap(),
      _fetchStreak(),
    ]);
  }

  Future<void> _fetchRecap() async {
    try {
      final summary = await _recapApi.getWeeklyRecap();
      runInAction(() {
        _summary.value = summary;
        // isStale=true KHÔNG phải lỗi (Guard #3) — chỉ phần AI rơi vào state
        // ready + empty insight-list, household stats vẫn hiển thị.
        _status.value = RecapLoadStatus.ready;
      });
    } on BusinessException catch (e) {
      if (e.code == 'ERR_RECAP_NOT_FOUND') {
        runInAction(() {
          _summary.value = null;
          _status.value = RecapLoadStatus.empty;
        });
        return;
      }
      if (e.code == 'ERR_RECAP_NO_HOUSEHOLD') {
        runInAction(() {
          _summary.value = null;
          _status.value = RecapLoadStatus.noHousehold;
        });
        return;
      }
      runInAction(() {
        _summary.value = null;
        _status.value = RecapLoadStatus.error;
        _error.value = e;
      });
    } catch (e) {
      // Gồm cả lỗi parse (TypeError) của field mới méo shape — không để màn
      // kẹt skeleton mãi. Lỗi không phải ApiException → error = null để màn
      // rơi về `l10n.recapError`, không lộ chuỗi tiếng Anh "Unexpected response".
      runInAction(() {
        _summary.value = null;
        _status.value = RecapLoadStatus.error;
        _error.value = e is ApiException ? e : null;
      });
    }
  }

  Future<void> _fetchStreak() async {
    if (_selfId == null) {
      runInAction(() => _streakStatus.value = RecapLoadStatus.error);
      return;
    }
    try {
      final streak = await _recapApi.getHouseholdStreak(memberId: _selfId!);
      runInAction(() {
        _streak.value = streak;
        _streakStatus.value = RecapLoadStatus.ready;
      });
    } catch (_) {
      // Gồm cả lỗi parse — streak không được kẹt ở loading.
      runInAction(() {
        _streak.value = null;
        _streakStatus.value = RecapLoadStatus.error;
      });
    }
  }

  void retry() => fetchAll();

  void retryStreak() {
    runInAction(() => _streakStatus.value = RecapLoadStatus.loading);
    unawaited(_fetchStreak());
  }
}