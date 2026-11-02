import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mobx/mobx.dart';
import '../../../data/network/api_exception.dart';
import '../data/meal_plan_api.dart';
import '../data/meal_attendance_api.dart';
import '../domain/meal_attendance.dart';
import '../data/meal_suggestion_api.dart';
import '../domain/meal_plan_slot.dart';
import '../domain/meal_suggestion.dart';

enum MealPlanLoadStatus { loading, ready, error }

/// Plan state is independent of attendance and AI request lifecycle.
class MealPlanStore {
  MealPlanStore(
      {required MealPlanApi api,
      required MealSuggestionApi suggestionApi,
      MealAttendanceApi? attendanceApi})
      : _api = api,
        _suggestionApi = suggestionApi,
        _attendanceApi = attendanceApi;
  final MealAttendanceApi? _attendanceApi;
  final ObservableMap<String, MealAttendance> attendances = ObservableMap();
  final Observable<ApiException?> _attendanceError = Observable(null);
  ApiException? get attendanceError => _attendanceError.value;
  final MealPlanApi _api;
  final MealSuggestionApi _suggestionApi;
  final Observable<MealPlanLoadStatus> _status =
      Observable(MealPlanLoadStatus.loading);
  final Observable<ApiException?> _loadError = Observable(null);
  final Observable<DateTime> _currentWeekStart =
      Observable(_mondayOf(DateTime.now()));
  final Observable<String?> _currentPlanId = Observable(null);
  final Observable<String> _planStatus = Observable('DRAFT');
  final Observable<bool> _confirming = Observable(false);
  final ObservableMap<String, MealPlanSlot> _slots = ObservableMap();
  final ObservableMap<String, List<MealSuggestion>> suggestions =
      ObservableMap();
  int _loadSequence = 0;
  int _attendanceSequence = 0;
  final Map<String, int> _suggestionSequences = {};
  MealPlanLoadStatus get status => _status.value;
  ApiException? get loadError => _loadError.value;
  DateTime get currentWeekStart => _currentWeekStart.value;
  String? get currentPlanId => _currentPlanId.value;
  bool get isConfirmed => _planStatus.value == 'CONFIRMED';
  bool get isConfirming => _confirming.value;
  ObservableMap<String, MealPlanSlot> get slots => _slots;
  @visibleForTesting
  set currentPlanIdForTesting(String? value) =>
      runInAction(() => _currentPlanId.value = value);
  List<String> get currentWeekSlotKeys => List<String>.generate(21, (i) {
        const meals = ['BREAKFAST', 'LUNCH', 'DINNER'];
        return '${_isoDate(currentWeekStart.add(Duration(days: i ~/ 3)))}_${meals[i % 3]}';
      });
  SlotUiStatus uiStatusOf(String key) {
    final ds = _slots[key]?.dishes ?? [];
    if (ds.isEmpty) return SlotUiStatus.empty;
    return ds.every((d) => d.recipe != null)
        ? SlotUiStatus.confirmed
        : SlotUiStatus.inProgress;
  }

  String? slotKeyOf(String id) =>
      _slots.entries.where((e) => e.value.id == id).firstOrNull?.key;
  Future<void> loadWeekPlan() => _load(_currentWeekStart.value);
  Future<bool> navigateWeek(int direction) async {
    await _load(currentWeekStart.add(Duration(days: 7 * direction)));
    return status == MealPlanLoadStatus.ready;
  }

  Future<void> _load(DateTime week) async {
    final sequence = ++_loadSequence;
    runInAction(() {
      _status.value = MealPlanLoadStatus.loading;
      _loadError.value = null;
    });
    try {
      MealPlanDto plan;
      try {
        plan = await _api.getWeek(week);
      } on ApiException catch (e) {
        if (e.code != 'ERR_PLAN_NOT_FOUND') rethrow;
        try {
          plan = await _api.create(week);
        } on ApiException catch (conflict) {
          if (conflict.code != 'ERR_PLAN_001') rethrow;
          plan = await _api.getWeek(week);
        }
      }
      if (sequence != _loadSequence) return;
      runInAction(() {
        _currentWeekStart.value = plan.weekStart;
        _currentPlanId.value = plan.id;
        _planStatus.value = plan.status;
        _slots.clear();
        attendances.clear();
        suggestions.clear();
        for (final slot in plan.slots) {
          _slots['${_isoDate(slot.slotDate)}_${slot.mealTime}'] = slot;
        }
        _status.value = MealPlanLoadStatus.ready;
      });
      await refreshAttendance();
    } on ApiException catch (e) {
      if (sequence != _loadSequence) return;
      runInAction(() {
        _loadError.value = e;
        _status.value = MealPlanLoadStatus.error;
      });
    }
  }

  Future<void> refreshAttendance() async {
    final pid = currentPlanId;
    final api = _attendanceApi;
    if (pid == null || api == null) return;
    final seq = ++_attendanceSequence;
    try {
      final rows = await api.list(pid);
      if (pid != currentPlanId || seq != _attendanceSequence) return;
      runInAction(() {
        attendances.clear();
        for (final row in rows) {
          attendances[row.slotId] = row;
        }
        _attendanceError.value = null;
      });
    } on ApiException catch (e) {
      if (pid == currentPlanId && seq == _attendanceSequence) {
        runInAction(() => _attendanceError.value = e);
      }
    }
  }

  Future<void> loadSuggestions(String sid, String did,
      {bool regenerate = false}) async {
    final pid = currentPlanId;
    if (pid == null) return;
    final epoch = _loadSequence;
    final seq = (_suggestionSequences[did] ?? 0) + 1;
    _suggestionSequences[did] = seq;
    final rows = regenerate
        ? await _suggestionApi.generate(pid, sid, did)
        : await _suggestionApi.list(pid, sid, did);
    if (currentPlanId == pid &&
        epoch == _loadSequence &&
        _suggestionSequences[did] == seq) {
      runInAction(() => suggestions[did] = rows);
    }
  }

  Future<void> selectSuggestion(String sid, String did, String id) async {
    final pid = currentPlanId;
    if (pid == null) return;
    final dish = await _suggestionApi.select(pid, sid, did, id);
    if (currentPlanId == pid) applyServerDish(dish);
  }

  Future<bool> assignManual(
      String sid, String did, String recipeId, String name) async {
    final pid = currentPlanId;
    if (pid == null || isConfirmed) return false;
    try {
      final dish = await _api.assignDishRecipe(pid, sid, did,
          recipeId: recipeId, recipeName: name);
      if (currentPlanId == pid) applyServerDish(dish);
      return true;
    } on ApiException catch (e) {
      runInAction(() => _loadError.value = e);
      return false;
    }
  }

  Future<bool> confirm() async {
    final pid = currentPlanId;
    if (pid == null || isConfirming) return false;
    runInAction(() => _confirming.value = true);
    try {
      await _api.confirm(pid);
      if (currentPlanId == pid) {
        runInAction(() => _planStatus.value = 'CONFIRMED');
      }
      return true;
    } on ApiException catch (e) {
      runInAction(() => _loadError.value = e);
      return false;
    } finally {
      runInAction(() => _confirming.value = false);
    }
  }

  void applyManualAssign(String key, MealPlanDish dish) =>
      _replaceDish(key, dish);
  void dispose() {
    _loadSequence++;
  }

  /// ĐIỂM DUY NHẤT ghi vào `slots[key].dishes` — Guard §15.15.
  ///
  /// Sau Finding #2 MEDIUM (review pass 1): tách thành 2 helper,
  /// `_replaceDish` (thay dish tồn tại) và `_setDishes` (thay toàn bộ list —
  /// dùng bởi `addDish`/`removeDish`). Cả 2 đều qua cùng 1 cửa `runInAction`.
  void _replaceDish(String slotKey, MealPlanDish updated) {
    final slot = _slots[slotKey];
    if (slot == null) return;
    _setDishes(
      slotKey,
      slot.dishes
          .map((MealPlanDish d) => d.id == updated.id ? updated : d)
          .toList(growable: false),
    );
  }

  /// Thay toàn bộ danh sách dishes của 1 slot — DUY NHẤT viết `slots[key]`.
  void _setDishes(String slotKey, List<MealPlanDish> newDishes) {
    final slot = _slots[slotKey];
    if (slot == null) return;
    runInAction(() => _slots[slotKey] = slot.copyWith(dishes: newDishes));
  }

  /// Reconcile 1 dish sau `PUT .../dishes/{dishId}` — KHÔNG tin `sortOrder`
  /// từ response (HIGH-1 fix).
  void applyServerDish(MealPlanDish serverDish) {
    final key = slotKeyOf(serverDish.slotId);
    if (key == null) return;
    final slot = _slots[key];
    if (slot == null) return;
    final existing = slot.dishes
        // ignore: always_specify_types
        .where((MealPlanDish d) => d.id == serverDish.id)
        .firstOrNull;
    final merged = existing == null
        ? serverDish
        : existing.copyWith(
            status: serverDish.status,
            recipe: serverDish.recipe,
            clearRecipe: serverDish.recipe == null,
          );
    _replaceDish(key, merged);
  }

  /// Thêm 1 dish rỗng (nút "+ Thêm món"). KHÔNG optimistic — chờ `id` thật.
  Future<MealPlanDish?> addDish(String slotId) async {
    final planId = _currentPlanId.value;
    final key = slotKeyOf(slotId);
    if (key == null || planId == null) return null;
    try {
      final dish = await _api.addDish(planId, slotId);
      if (currentPlanId != planId) return null;
      final slot = _slots[key];
      if (slot == null) return null;
      // Đi qua _setDishes (Guard §15.15) thay vì inline slots[key]= trực tiếp.
      _setDishes(key, <MealPlanDish>[...slot.dishes, dish]);
      return dish;
    } on ApiException catch (e) {
      runInAction(() => _loadError.value = e);
      return null;
    }
  }

  /// Xoá 1 dish (chỉ gọi sau người dùng confirm). KHÔNG optimistic — chờ 204.
  Future<void> removeDish(String slotId, String dishId) async {
    final planId = _currentPlanId.value;
    final key = slotKeyOf(slotId);
    if (key == null || planId == null) return;
    try {
      await _api.removeDish(planId, slotId, dishId);
      if (currentPlanId != planId) return;
      final slot = _slots[key];
      if (slot == null) return;
      _setDishes(
        key,
        slot.dishes
            .where((MealPlanDish d) => d.id != dishId)
            .toList(growable: false),
      );
    } on ApiException catch (e) {
      runInAction(() => _loadError.value = e);
    }
  }

  static DateTime _mondayOf(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
