import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../data/meal_plan_api.dart';
import '../data/meal_attendance_api.dart';
import '../domain/meal_attendance.dart';
import '../data/meal_suggestion_api.dart';
import '../domain/meal_plan_slot.dart';
import '../domain/meal_suggestion.dart';

enum MealPlanLoadStatus { loading, ready, error }

/// Plan state is independent of attendance and AI request lifecycle.
class MealPlanStore extends GetLifeCycle {
  MealPlanStore({
    required MealPlanApi api,
    required MealSuggestionApi suggestionApi,
    MealAttendanceApi? attendanceApi,
    SessionStore? session,
  })  : _api = api,
        _suggestionApi = suggestionApi,
        _attendanceApi = attendanceApi {
    if (session != null) {
      _sessionDisposer = reaction(
        (_) => (session.currentUser?.id, session.householdId),
        (_) => _resetSession(),
      );
    }
  }
  final MealAttendanceApi? _attendanceApi;
  final ObservableMap<String, MealAttendance> attendances = ObservableMap();
  final Observable<ApiException?> _attendanceError = Observable(null);
  ApiException? get attendanceError => _attendanceError.value;
  final MealPlanApi _api;
  final MealSuggestionApi _suggestionApi;
  final Observable<MealPlanLoadStatus> _status = Observable(
    MealPlanLoadStatus.loading,
  );
  final Observable<ApiException?> _loadError = Observable(null);
  final Observable<DateTime> _currentWeekStart = Observable(
    _mondayOf(DateTime.now()),
  );
  final Observable<String?> _currentPlanId = Observable(null);
  final Observable<String> _planStatus = Observable('DRAFT');
  final Observable<bool> _confirming = Observable(false);
  final ObservableMap<String, MealPlanSlot> _slots = ObservableMap();
  final ObservableMap<String, List<MealSuggestion>> suggestions =
      ObservableMap();
  int _loadSequence = 0;
  int _refreshSequence = 0;
  int _attendanceSequence = 0;
  final Map<String, _DishRequests> _dishRequests = {};
  int _planEpoch = 0;
  int _planWriteVersion = 0;
  bool _disposed = false;
  ReactionDisposer? _sessionDisposer;
  ({Future<MealPlanDto> future, int ticket})? _planRead;
  int _planReadSequence = 0;
  int _lastAppliedPlanRead = 0;

  // Public refresh request ordering stays independent; all snapshot sources
  // share this watermark so older reads cannot replace newer applied data.
  bool _freshPlanRead(int ticket) => ticket >= _lastAppliedPlanRead;

  void _applyPlanSnapshot(MealPlanDto plan, int ticket) {
    _lastAppliedPlanRead = ticket;
    runInAction(() {
      _slots.clear();
      for (final slot in plan.slots) {
        _slots['${_isoDate(slot.slotDate)}_${slot.mealTime}'] = slot;
      }
      _planStatus.value = plan.status;
    });
  }

  void _invalidatePlanReads() {
    _planWriteVersion++;
    _planRead = null;
  }

  DishSuggestionState suggestionState(String dishId) => _requestsFor(dishId);
  bool canEditDish(String dishId) =>
      !_disposed && !isConfirmed && _requestsFor(dishId).canWrite;

  _DishRequests _requestsFor(String did) => _dishRequests.putIfAbsent(
      did, () => _DishRequests(currentPlanId, _planEpoch));

  bool _current(_DishRequests request) =>
      !_disposed &&
      request.active &&
      request.planId == currentPlanId &&
      request.epoch == _planEpoch;

  void _invalidateDishRequests() {
    _planEpoch++;
    _invalidatePlanReads();
    _lastAppliedPlanRead = 0;
    for (final request in _dishRequests.values) {
      runInAction(() {
        request._active.value = false;
        request._pending.value = null;
        request._listLoading.value = false;
        request._planLoading.value = false;
      });
      for (final waiter in request.waiters) {
        if (!waiter.isCompleted) waiter.complete(DishRequestResult.ignored);
      }
      request.waiters.clear();
    }
    _dishRequests.clear();
  }

  void _resetSession() {
    _loadSequence++;
    _refreshSequence++;
    _attendanceSequence++;
    _invalidateDishRequests();
    runInAction(() {
      _currentPlanId.value = null;
      _slots.clear();
      suggestions.clear();
      attendances.clear();
      _planStatus.value = 'DRAFT';
    });
  }

  MealPlanLoadStatus get status => _status.value;
  ApiException? get loadError => _loadError.value;
  DateTime get currentWeekStart => _currentWeekStart.value;
  String? get currentPlanId => _currentPlanId.value;
  bool get isConfirmed => _planStatus.value == 'CONFIRMED';
  bool get isConfirming => _confirming.value;
  ObservableMap<String, MealPlanSlot> get slots => _slots;
  @visibleForTesting
  set currentPlanIdForTesting(String? value) {
    if (currentPlanId != value) _invalidateDishRequests();
    runInAction(() => _currentPlanId.value = value);
  }

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
    if (_disposed) return;
    if (week != currentWeekStart) _invalidateDishRequests();
    final sequence = ++_loadSequence;
    final writeVersion = _planWriteVersion;
    final readTicket = ++_planReadSequence;
    ++_refreshSequence;
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
      if (sequence != _loadSequence || _disposed) return;
      final changedPlan = currentPlanId != plan.id;
      if (changedPlan) _invalidateDishRequests();
      // A read started before a menu mutation must not roll its response back.
      if (!changedPlan &&
          (writeVersion != _planWriteVersion || !_freshPlanRead(readTicket))) {
        runInAction(() => _status.value = MealPlanLoadStatus.ready);
        return;
      }
      runInAction(() {
        _currentWeekStart.value = plan.weekStart;
        _currentPlanId.value = plan.id;
        attendances.clear();
        if (changedPlan) suggestions.clear();
        _applyPlanSnapshot(plan, readTicket);
        _status.value = MealPlanLoadStatus.ready;
      });
      await refreshAttendance();
    } on ApiException catch (e) {
      if (sequence != _loadSequence || _disposed) return;
      if (!_freshPlanRead(readTicket)) {
        runInAction(() => _status.value = MealPlanLoadStatus.ready);
        return;
      }
      runInAction(() {
        _loadError.value = e;
        _status.value = MealPlanLoadStatus.error;
      });
    }
  }

  Future<bool> refreshPlan() async {
    final pid = currentPlanId;
    if (pid == null || _disposed) return false;
    final epoch = _planEpoch;
    final version = _planWriteVersion;
    final refresh = ++_refreshSequence;
    final readTicket = ++_planReadSequence;
    final plan = await _api.getById(pid);
    if (currentPlanId != pid ||
        _planEpoch != epoch ||
        _disposed ||
        version != _planWriteVersion ||
        !_freshPlanRead(readTicket) ||
        _refreshSequence != refresh) {
      return false;
    }
    _applyPlanSnapshot(plan, readTicket);
    return true;
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

  Future<DishRequestResult> loadSuggestions(String sid, String did,
          {bool regenerate = false}) =>
      regenerate
          ? _mutateDish(sid, did, DishMutation.generate)
          : _readDish(sid, did, plan: false);

  Future<DishRequestResult> selectSuggestion(
          String sid, String did, String id) =>
      _mutateDish(sid, did, DishMutation.select, suggestionId: id);

  Future<DishRequestResult> recheckSuggestion(String sid, String did) =>
      _readDish(sid, did,
          plan: _requestsFor(did).lastMutation == DishMutation.select);

  bool acknowledgeSuggestion(String did) {
    final r = _requestsFor(did);
    if (!_current(r) || isConfirmed || !r.canContinue) return false;
    runInAction(() {
      r._unknown.value = false;
      r._mutationError.value = null;
      r._rechecked.value = false;
    });
    return true;
  }

  ({Future<MealPlanDto> future, int ticket}) _fetchPlan(String pid) {
    final existing = _planRead;
    if (existing != null && _freshPlanRead(existing.ticket)) return existing;
    final read = (future: _api.getById(pid), ticket: ++_planReadSequence);
    _planRead = read;
    void clear() {
      if (identical(_planRead?.future, read.future)) _planRead = null;
    }

    unawaited(read.future.then<void>((_) => clear(),
        onError: (Object error, StackTrace trace) => clear()));
    return read;
  }

  Future<DishRequestResult> _readDish(String sid, String did,
      {required bool plan}) {
    final r = _requestsFor(did);
    if (currentPlanId == null || !_current(r)) {
      return Future.value(DishRequestResult.ignored);
    }
    if (r.pending != null) {
      final queued = plan ? r.queuedPlan : r.queuedList;
      if (queued != null) return queued.future;
      final waiter = Completer<DishRequestResult>();
      r.waiters.add(waiter);
      if (plan) {
        r.queuedPlan = waiter;
      } else {
        r.queuedList = waiter;
      }
      return waiter.future;
    }
    final flight = plan ? r.planFlight : r.listFlight;
    if (flight != null) return flight.future;
    final waiter = Completer<DishRequestResult>();
    r.waiters.add(waiter);
    if (plan) {
      r.planFlight = waiter;
    } else {
      r.listFlight = waiter;
    }
    final revision = r.revision;
    final writeVersion = _planWriteVersion;
    runInAction(() {
      (plan ? r._planLoading : r._listLoading).value = true;
      r._readError.value = null;
      r._rechecked.value = false;
    });
    final pid = r.planId!;
    unawaited(() async {
      var result = DishRequestResult.ignored;
      int? planReadTicket;
      bool valid() =>
          _current(r) &&
          revision == r.revision &&
          (!plan ||
              (writeVersion == _planWriteVersion &&
                  (planReadTicket == null || _freshPlanRead(planReadTicket))));
      try {
        if (plan) {
          final read = _fetchPlan(pid);
          planReadTicket = read.ticket;
          final snapshot = await read.future;
          if (valid()) _applyPlanSnapshot(snapshot, read.ticket);
        } else {
          final rows = await _suggestionApi.list(pid, sid, did);
          if (valid()) runInAction(() => suggestions[did] = rows);
        }
        if (valid()) {
          result = DishRequestResult.applied;
          runInAction(() {
            if (!r.outcomeUnknown ||
                plan == (r.lastMutation == DishMutation.select)) {
              r._rechecked.value = true;
            }
            r._denied.value = false;
          });
        }
      } catch (error) {
        if (valid()) {
          result = DishRequestResult.rejected;
          runInAction(() {
            r._readError.value = _apiError(error);
            r._denied.value = _scopeDenied(r.readError!);
          });
        }
      } finally {
        if (_current(r) && revision == r.revision) {
          runInAction(
              () => (plan ? r._planLoading : r._listLoading).value = false);
          if (plan) {
            r.planFlight = null;
          } else {
            r.listFlight = null;
          }
        }
        r.waiters.remove(waiter);
        if (!waiter.isCompleted) waiter.complete(result);
      }
    }());
    return waiter.future;
  }

  Future<DishRequestResult> _mutateDish(
      String sid, String did, DishMutation kind,
      {String? suggestionId,
      Future<MealPlanDish> Function()? manualSelection}) {
    final r = _requestsFor(did);
    if (currentPlanId == null || !_current(r)) {
      return Future.value(DishRequestResult.ignored);
    }
    if (!canEditDish(did)) return Future.value(DishRequestResult.rejected);
    r.revision++;
    _invalidatePlanReads();
    // Retire older reads immediately; their network callbacks are still guarded.
    for (final read in [r.listFlight, r.planFlight]) {
      if (read != null) {
        r.waiters.remove(read);
        if (!read.isCompleted) read.complete(DishRequestResult.ignored);
      }
    }
    r.listFlight = null;
    r.planFlight = null;
    r.lastMutation = kind;
    runInAction(() {
      r._pending.value = kind;
      r._mutationError.value = null;
      r._readError.value = null;
      r._rechecked.value = false;
      r._listLoading.value = false;
      r._planLoading.value = false;
    });
    final waiter = Completer<DishRequestResult>();
    r.waiters.add(waiter);
    final pid = r.planId!;
    unawaited(() async {
      var result = DishRequestResult.ignored;
      try {
        if (kind == DishMutation.generate) {
          final rows = await _suggestionApi.generate(pid, sid, did);
          if (_current(r)) runInAction(() => suggestions[did] = rows);
        } else {
          final dish = manualSelection != null
              ? await manualSelection()
              : await _suggestionApi.select(pid, sid, did, suggestionId!);
          if (_current(r)) applyServerDish(dish);
        }
        if (_current(r)) result = DishRequestResult.applied;
      } catch (error) {
        if (_current(r)) {
          final apiError = _apiError(error);
          result = DishRequestResult.rejected;
          runInAction(() {
            r._mutationError.value = apiError;
            r._unknown.value = _uncertain(kind, apiError);
            r._denied.value = _scopeDenied(apiError);
            if (apiError.code == 'ERR_PLAN_003') {
              _planStatus.value = 'CONFIRMED';
            }
          });
          if (apiError.code == 'ERR_PLAN_003') {
            r.queuedPlan ??= Completer<DishRequestResult>();
          } else if (const {
            'ERR_PLAN_SUGGESTION_NOT_FOUND',
            'ERR_PLAN_SUGGESTION_STALE',
            'ERR_MEAL_OPTION_BLOCKED'
          }.contains(apiError.code)) {
            r.queuedList ??= Completer<DishRequestResult>();
          }
        }
      } finally {
        if (_current(r)) {
          _invalidatePlanReads();
          runInAction(() => r._pending.value = null);
          _drainReads(r, sid, did);
        }
        r.waiters.remove(waiter);
        if (!waiter.isCompleted) waiter.complete(result);
      }
    }());
    return waiter.future;
  }

  void _drainReads(_DishRequests r, String sid, String did) {
    final list = r.queuedList;
    final plan = r.queuedPlan;
    r.queuedList = null;
    r.queuedPlan = null;
    void drain(Completer<DishRequestResult>? queued, bool planRead) {
      if (queued == null) return;
      unawaited(_readDish(sid, did, plan: planRead).then((result) {
        r.waiters.remove(queued);
        if (!queued.isCompleted) queued.complete(result);
      }));
    }

    drain(list, false);
    drain(plan, true);
  }

  static ApiException _apiError(Object error) => error is ApiException
      ? error
      : ServerException('ERR_UNKNOWN', 'Unexpected response');

  static bool _uncertain(DishMutation kind, ApiException error) {
    if (error is NetworkException) return true;
    if (error is! ServerException) return false;
    return kind != DishMutation.generate ||
        !const {
          'ERR_AI_TIMEOUT',
          'ERR_AI_SERVICE_DOWN',
          'ERR_AI_INVALID_OUTPUT',
        }.contains(error.code);
  }

  static bool _scopeDenied(ApiException error) =>
      error is AuthExpiredException ||
      const {
        'ERR_PLAN_NO_HOUSEHOLD',
        'ERR_PLAN_NOT_FOUND',
        'ERR_PLAN_SLOT_NOT_FOUND',
        'ERR_PLAN_DISH_NOT_FOUND',
        'ERR_MEAL_FORBIDDEN',
        'ERR_PLAN_OWNER_ONLY'
      }.contains(error.code);

  Future<bool> assignManual(
    String sid,
    String did,
    String recipeId,
    String name,
  ) async {
    final pid = currentPlanId;
    if (pid == null || !canEditDish(did)) return false;
    final result = await _mutateDish(sid, did, DishMutation.select,
        manualSelection: () => _api.assignDishRecipe(pid, sid, did,
            recipeId: recipeId, recipeName: name));
    return result == DishRequestResult.applied;
  }

  Future<bool> confirm() async {
    final pid = currentPlanId;
    if (pid == null || isConfirming || _disposed) return false;
    final epoch = _planEpoch;
    _invalidatePlanReads();
    runInAction(() => _confirming.value = true);
    try {
      await _api.confirm(pid);
      if (currentPlanId != pid || epoch != _planEpoch || _disposed) {
        return false;
      }
      runInAction(() => _planStatus.value = 'CONFIRMED');
      return true;
    } on ApiException catch (e) {
      if (currentPlanId != pid || epoch != _planEpoch || _disposed) {
        return false;
      }
      runInAction(() => _loadError.value = e);
      return false;
    } finally {
      if (currentPlanId == pid && epoch == _planEpoch && !_disposed) {
        _invalidatePlanReads();
      }
      runInAction(() => _confirming.value = false);
    }
  }

  void applyManualAssign(String key, MealPlanDish dish) =>
      _replaceDish(key, dish);
  @override
  void onClose() {
    dispose();
    super.onClose();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sessionDisposer?.call();
    _loadSequence++;
    _invalidateDishRequests();
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
    _invalidatePlanReads();
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
    if (key == null || planId == null || !canEditDish(dishId)) return;
    try {
      await _api.removeDish(planId, slotId, dishId);
      if (currentPlanId != planId) return;
      final slot = _slots[key];
      if (slot == null) return;
      final retired = _dishRequests.remove(dishId);
      if (retired != null) {
        runInAction(() => retired._active.value = false);
        for (final waiter in retired.waiters) {
          if (!waiter.isCompleted) waiter.complete(DishRequestResult.ignored);
        }
        retired.waiters.clear();
      }
      runInAction(() => suggestions.remove(dishId));
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

/// Public observation for all panels of a dish; never a server operation status.
enum DishRequestResult { applied, ignored, rejected }

enum DishMutation { generate, select }

class DishSuggestionState {
  final Observable<bool> _active = Observable(true);
  final Observable<DishMutation?> _pending = Observable(null);
  final Observable<bool> _unknown = Observable(false);
  final Observable<bool> _rechecked = Observable(false);
  final Observable<bool> _denied = Observable(false);
  final Observable<bool> _listLoading = Observable(false);
  final Observable<bool> _planLoading = Observable(false);
  final Observable<ApiException?> _mutationError = Observable(null);
  final Observable<ApiException?> _readError = Observable(null);
  bool get active => _active.value;
  DishMutation? get pending => _pending.value;
  bool get outcomeUnknown => _unknown.value;
  bool get reading => _listLoading.value || _planLoading.value;
  bool get canWrite =>
      active && pending == null && !outcomeUnknown && !_denied.value;
  bool get canContinue =>
      active &&
      outcomeUnknown &&
      _rechecked.value &&
      !_denied.value &&
      !reading &&
      pending == null;
  ApiException? get mutationError => _mutationError.value;
  ApiException? get readError => _readError.value;
}

class _DishRequests extends DishSuggestionState {
  _DishRequests(this.planId, this.epoch);
  final String? planId;
  final int epoch;
  int revision = 0;
  DishMutation? lastMutation;
  Completer<DishRequestResult>? queuedList, queuedPlan, listFlight, planFlight;
  final Set<Completer<DishRequestResult>> waiters = {};
}
