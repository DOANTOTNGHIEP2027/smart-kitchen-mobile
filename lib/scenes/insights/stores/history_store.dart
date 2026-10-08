import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/api/health_api.dart';
import '../data/adherence_api.dart';
import '../data/history_api.dart';
import '../domain/daily_nutrition_point.dart';
import '../domain/nutrition_aggregator.dart';
import '../domain/streak_summary.dart';
import '../domain/week_quick_stat.dart';
import '../domain/weekly_adherence_point.dart';

/// State + actions cho `MonthlyHistoryScreen` — 3 tab Calo/Macro/Tuân Thủ
/// (nutrition-trend-history.md §7).
///
/// MobX thủ công (Observable + runInAction), cùng pattern `MealLogStore`.
class HistoryStore {
  HistoryStore(
    this._historyApi,
    this._adherenceApi,
    this._healthApi,
    this._sessionStore, {
    DateTime Function()? now,
  }) : _now = now ?? _systemVnToday,
       _monthCursor = Observable<DateTime>(_firstDayOfCurrentMonth(now)) {
    // Gọi ĐÚNG 1 LẦN lúc khởi tạo Store — 2 nguồn này KHÔNG phụ thuộc
    // monthCursor (fix finding LOW ở review).
    unawaited(_loadTarget());
    unawaited(_loadWeekQuickStat());
  }

  final HistoryApi _historyApi;
  final AdherenceApi _adherenceApi;
  final HealthApi _healthApi;
  final SessionStore _sessionStore;

  /// Clock "hôm nay" theo lịch VN — injectable để test (không phụ thuộc clock
  /// thật khi assert `_monthEnd`/`isCurrentMonth`/`nextMonth`).
  final DateTime Function() _now;

  String get _selfId => _sessionStore.currentUser?.id ?? '';

  final Observable<DateTime> _monthCursor;
  final Observable<ViewState<List<DailyNutritionPoint>>> _dailyNutritionState =
      Observable<ViewState<List<DailyNutritionPoint>>>(const LoadingState());
  final Observable<int?> _targetDailyCalories = Observable<int?>(null);
  final Observable<WeekQuickStat?> _weekQuickStat = Observable<WeekQuickStat?>(null);
  final Observable<ViewState<List<WeeklyAdherencePoint>>> _adherenceState =
      Observable<ViewState<List<WeeklyAdherencePoint>>>(const LoadingState());
  final Observable<StreakSummary?> _streak = Observable<StreakSummary?>(null);

  /// Request-token tăng dần — bỏ qua response CŨ của 1 lần `loadMonth()` nếu
  /// nó resolve SAU 1 lần mới hơn (fix race condition, Guard §12.13).
  int _loadGeneration = 0;

  // ── Getters ──────────────────────────────────────────────────────────────

  DateTime get monthCursor => _monthCursor.value;
  ViewState<List<DailyNutritionPoint>> get dailyNutritionState =>
      _dailyNutritionState.value;
  int? get targetDailyCalories => _targetDailyCalories.value;
  WeekQuickStat? get weekQuickStat => _weekQuickStat.value;
  ViewState<List<WeeklyAdherencePoint>> get adherenceState =>
      _adherenceState.value;
  StreakSummary? get streak => _streak.value;

  bool get isCurrentMonth {
    final today = _now();
    return monthCursor.year == today.year && monthCursor.month == today.month;
  }

  /// Ngày cuối của khung tháng đang xem — KHÔNG BAO GIỜ vượt quá hôm nay
  /// (tránh N ngày gap vô nghĩa cuối tháng hiện tại + tránh gọi adherence cho
  /// tuần tương lai, Guard §12.10).
  DateTime get _monthEnd {
    final nextMonth = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    final todayDay = _now();
    return isCurrentMonth && lastDayOfMonth.isAfter(todayDay)
        ? todayDay
        : lastDayOfMonth;
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Gọi 1 lần từ `InsightsBinding` — 2 nhóm fetch ĐỘC LẬP, lỗi 1 nhóm không
  /// chặn nhóm kia (Guard §12.8).
  Future<void> loadMonth() async {
    runInAction(() {
      _dailyNutritionState.value = const LoadingState();
      _adherenceState.value = const LoadingState();
    });
    final gen = ++_loadGeneration;
    final from = monthCursor;
    final to = _monthEnd;
    await Future.wait<dynamic>([
      _loadDailyNutrition(gen, from, to),
      _loadAdherence(gen, from, to),
    ]);
  }

  Future<void> _loadDailyNutrition(int gen, DateTime from, DateTime to) async {
    try {
      final logs =
          await _historyApi.listAllLogsInRange(memberId: _selfId, from: from, to: to);
      if (gen != _loadGeneration) return;
      runInAction(() {
        _dailyNutritionState.value = SuccessState(
          NutritionAggregator.aggregateByDay(logs: logs, from: from, to: to),
        );
      });
    } on ApiException catch (e) {
      if (gen != _loadGeneration) return;
      runInAction(() => _dailyNutritionState.value = ErrorState(e));
    }
  }

  Future<void> _loadTarget() async {
    try {
      final profile = await _healthApi.getMyHealthProfile();
      runInAction(() => _targetDailyCalories.value = profile.targetDailyCalories);
    } on ApiException {
      runInAction(() => _targetDailyCalories.value = null);
    } on DioException {
      // HealthApi chưa `_unwrap` — ném DioException với `.error` là ApiException.
      // Bắt ở store để không thành unhandled async exception (review Task 2).
      runInAction(() => _targetDailyCalories.value = null);
    }
  }

  Future<void> _loadWeekQuickStat() async {
    try {
      final stat = await _historyApi.getSelfWeekQuickStat(_selfId);
      runInAction(() => _weekQuickStat.value = stat);
    } on ApiException {
      runInAction(() => _weekQuickStat.value = null);
    }
  }

  Future<void> _loadAdherence(int gen, DateTime from, DateTime to) async {
    try {
      final mondays = _mondaysOverlapping(from, to);
      final percents = await Future.wait(
        mondays.map(_adherenceApi.getWeeklyAdherencePercent),
      );
      final streakResult = await _adherenceApi.getStreak(_selfId);
      if (gen != _loadGeneration) return;
      runInAction(() {
        _adherenceState.value = SuccessState([
          for (var i = 0; i < mondays.length; i++)
            WeeklyAdherencePoint(
              weekStart: mondays[i],
              adherencePercent: percents[i],
            ),
        ]);
        _streak.value = streakResult;
      });
    } on ApiException catch (e) {
      if (gen != _loadGeneration) return;
      runInAction(() => _adherenceState.value = ErrorState(e));
    }
  }

  void previousMonth() {
    runInAction(() {
      _monthCursor.value =
          DateTime(monthCursor.year, monthCursor.month - 1, 1);
    });
    loadMonth();
  }

  /// No-op nếu đã ở tháng hiện tại — không cho xem tháng tương lai
  /// (Guard §12.5).
  void nextMonth() {
    if (isCurrentMonth) return;
    runInAction(() {
      _monthCursor.value =
          DateTime(monthCursor.year, monthCursor.month + 1, 1);
    });
    loadMonth();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Mọi Monday mà TUẦN của nó giao với [from, to] — kể cả Monday TRƯỚC [from]
  /// nếu [from] không rơi đúng vào Monday.
  static List<DateTime> _mondaysOverlapping(DateTime from, DateTime to) {
    DateTime mondayOnOrBefore(DateTime d) =>
        d.subtract(Duration(days: d.weekday - 1));
    final result = <DateTime>[];
    var cursor = mondayOnOrBefore(from);
    while (!cursor.isAfter(to)) {
      result.add(cursor);
      cursor = cursor.add(const Duration(days: 7));
    }
    return result;
  }

  /// "Hôm nay" theo lịch `Asia/Ho_Chi_Minh` (offset +7h cố định) — 1 nguồn
  /// sự thật DUY NHẤT cho "hôm nay"/"tháng hiện tại" (Guard §12.4).
  static DateTime _systemVnToday() {
    final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime(vn.year, vn.month, vn.day);
  }

  static DateTime _firstDayOfCurrentMonth([DateTime Function()? now]) {
    final today = (now ?? _systemVnToday)();
    return DateTime(today.year, today.month, 1);
  }
}