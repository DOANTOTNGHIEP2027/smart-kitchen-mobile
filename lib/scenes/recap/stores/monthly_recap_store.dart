import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../profile/domain/household_tier.dart';
import '../data/monthly_recap_api.dart';
import '../domain/monthly_recap_summary.dart';
import 'weekly_recap_store.dart';

/// Trạng thái màn Tổng kết tháng.
enum MonthlyRecapStatus { loading, noHousehold, error, ready }

/// State + actions cho màn Tổng kết tháng — MobX thủ công (Observable +
/// runInAction), mọi ghi observable sau `await` đều nằm trong runInAction.
class MonthlyRecapStore {
  MonthlyRecapStore(
    this._api,
    this._sessionStore, {
    DateTime Function()? now,
  })  : _now = now ?? _systemVnToday,
        _month = Observable<DateTime>(_firstDayOf((now ?? _systemVnToday)()));

  final MonthlyRecapApi _api;
  final SessionStore _sessionStore;

  /// "Hôm nay" theo giờ Việt Nam — inject được để test.
  final DateTime Function() _now;

  String? get _selfId => _sessionStore.currentUser?.id;

  final Observable<DateTime> _month;
  final Observable<MonthlyRecapSummary?> _summary =
      Observable<MonthlyRecapSummary?>(null);
  final Observable<MonthlyRecapStatus> _status =
      Observable<MonthlyRecapStatus>(MonthlyRecapStatus.loading);
  final Observable<ApiException?> _error = Observable<ApiException?>(null);

  /// Bỏ qua phản hồi CŨ khi người dùng chuyển tháng nhanh.
  int _generation = 0;

  // ── Getters ──────────────────────────────────────────────────────────────

  /// Ngày 1 của tháng đang xem.
  DateTime get month => _month.value;
  MonthlyRecapSummary? get summary => _summary.value;
  MonthlyRecapStatus get status => _status.value;
  ApiException? get error => _error.value;

  DateTime get _currentMonth => _firstDayOf(_now());

  bool get isCurrentMonth => !month.isBefore(_currentMonth);

  /// Không cho xem tháng tương lai.
  bool get canGoNext =>
      !isCurrentMonth && _status.value != MonthlyRecapStatus.loading;

  /// Theo `hasPrevious` của BE; khi lỗi/đang tải thì tắt.
  bool get canGoPrevious =>
      _status.value == MonthlyRecapStatus.ready &&
      (_summary.value?.hasPrevious ?? false);

  /// Insight của chính người xem — hero dùng badge này.
  MonthlyMemberInsight? get ownInsight {
    final self = _selfId;
    if (self == null) return null;
    for (final m in orderedMemberInsights) {
      if (m.memberId == self) return m;
    }
    return null;
  }

  List<MonthlyMemberInsight> get orderedMemberInsights =>
      _summary.value?.memberInsights ?? const <MonthlyMemberInsight>[];

  /// Cùng quy tắc Tổng kết tuần: BE quyết bằng `spendByCategory == null`,
  /// claim `tier` chỉ chọn câu chữ.
  SpendDetailGate? get spendDetailGate {
    final s = _summary.value;
    if (s == null) return null;
    if (s.spendByCategory != null) return SpendDetailGate.unlocked;
    return HouseholdTier.fromApi(_sessionStore.tier) == HouseholdTier.premium
        ? SpendDetailGate.lockedNeutral
        : SpendDetailGate.lockedUpsell;
  }

  bool get canSetBudget => _sessionStore.role == 'OWNER';

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Tải tháng hiện tại (không gửi `month` — BE tự chọn tháng hiện tại).
  Future<void> loadCurrentMonth() => _load(null);

  /// Tải lại tháng đang xem.
  Future<void> reload() => _load(isCurrentMonth ? null : month);

  void retry() => unawaited(reload());

  Future<void> previousMonth() async {
    if (!canGoPrevious) return;
    await _load(DateTime(month.year, month.month - 1));
  }

  Future<void> nextMonth() async {
    if (!canGoNext) return;
    final next = DateTime(month.year, month.month + 1);
    await _load(next.isBefore(_currentMonth) ? next : null);
  }

  Future<void> _load(DateTime? target) async {
    final generation = ++_generation;
    if (_sessionStore.householdId == null) {
      runInAction(() {
        _summary.value = null;
        _error.value = null;
        _status.value = MonthlyRecapStatus.noHousehold;
      });
      return;
    }
    runInAction(() {
      _month.value = target ?? _currentMonth;
      _error.value = null;
      _status.value = MonthlyRecapStatus.loading;
    });
    try {
      final summary = await _api.getMonthlyRecap(month: target);
      if (generation != _generation) return;
      runInAction(() {
        _summary.value = summary;
        _month.value = summary.month;
        _status.value = MonthlyRecapStatus.ready;
      });
    } on BusinessException catch (e) {
      if (generation != _generation) return;
      runInAction(() {
        _summary.value = null;
        if (e.code == 'ERR_RECAP_NO_HOUSEHOLD') {
          _status.value = MonthlyRecapStatus.noHousehold;
        } else {
          _error.value = e;
          _status.value = MonthlyRecapStatus.error;
        }
      });
    } catch (e) {
      // Gồm cả lỗi parse — không để màn kẹt ở trạng thái đang tải.
      if (generation != _generation) return;
      runInAction(() {
        _summary.value = null;
        _error.value = e is ApiException ? e : null;
        _status.value = MonthlyRecapStatus.error;
      });
    }
  }

  static DateTime _systemVnToday() {
    final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime(vn.year, vn.month, vn.day);
  }

  static DateTime _firstDayOf(DateTime d) => DateTime(d.year, d.month);
}
