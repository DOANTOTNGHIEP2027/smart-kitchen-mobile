import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../data/recap_api.dart';
import '../domain/household_streak.dart';
import '../domain/weekly_recap_summary.dart';

/// Trạng thái fetch nhánh con của màn hình Weekly Recap (weekly-recap-screen.md
/// §10) — MobX thủ công (Observable + runInAction).
enum RecapLoadStatus { loading, noHousehold, empty, error, ready }

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
    } on ApiException catch (e) {
      runInAction(() {
        _summary.value = null;
        _status.value = RecapLoadStatus.error;
        _error.value = e;
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
    } on ApiException {
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