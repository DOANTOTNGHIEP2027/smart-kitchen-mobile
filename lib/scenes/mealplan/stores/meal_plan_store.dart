import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/realtime/ws_event_envelope.dart';
import '../../../stores/realtime_store.dart';
import '../../../stores/session_store.dart';
import '../data/meal_plan_api.dart';
import '../data/vote_api.dart';
import '../domain/meal_plan_slot.dart';
import '../domain/vote_session_summary.dart';

/// Status tải tuần (FE-7 §7).
enum MealPlanLoadStatus { loading, ready, error }

/// MobX store quản lý trạng thái meal plan + vote realtime (FE-7 §7).
///
/// **Quyết định kiến trúc (Implementation Guards §15):**
/// - `activeSessions` khoá theo `dishId` (không phải slotId/sessionId) — UNIQUE
///   (dish_id) của #43 cho phép N session OPEN cho N dish cùng slot.
/// - `slots` là `ObservableMap<String-key, MealPlanSlot>` — granular reactivity
///   (chỉ 1 ô lưới rebuild khi slot đó đổi, Guard §15.1).
/// - `_replaceDish` là ĐIỂM DUY NHẤT được phép ghi vào `slots[key].dishes`
///   (Guard §15.15).
/// - WS event parse THẲNG `raw['type']`, không bọc envelope (destination
///   `/vote` JSON phẳng, khác `/inventory` has envelope).
class MealPlanStore {
  MealPlanStore({
    required MealPlanApi api,
    required VoteApi voteApi,
    required RealtimeStore realtimeStore,
    required SessionStore sessionStore,
  })  : _api = api,
        _voteApi = voteApi,
        _realtimeStore = realtimeStore,
        _sessionStore = sessionStore;

  final MealPlanApi _api;
  final VoteApi _voteApi;
  final RealtimeStore _realtimeStore;
  final SessionStore _sessionStore;

  StreamSubscription<WsEventEnvelope>? _wsSub;
  final Map<String, MealPlanDto> _weekPlanCache = <String, MealPlanDto>{};

  final Observable<MealPlanLoadStatus> _status =
      Observable<MealPlanLoadStatus>(MealPlanLoadStatus.loading);
  final Observable<ApiException?> _loadError =
      Observable<ApiException?>(null);
  final Observable<DateTime> _currentWeekStart =
      Observable<DateTime>(_mondayOf(DateTime.now()));
  final Observable<String?> _currentPlanId = Observable<String?>(null);
  final ObservableMap<String, MealPlanSlot> _slots =
      ObservableMap<String, MealPlanSlot>();
  final ObservableMap<String, VoteSessionSummary> _activeSessions =
      ObservableMap<String, VoteSessionSummary>();

  // ── Getters ──────────────────────────────────────────────────────────────

  MealPlanLoadStatus get status => _status.value;
  ApiException? get loadError => _loadError.value;
  DateTime get currentWeekStart => _currentWeekStart.value;
  String? get currentPlanId => _currentPlanId.value;

  /// Cho test seed planId mà không qua API thật.
  @visibleForTesting
  set currentPlanIdForTesting(String? value) =>
      runInAction(() => _currentPlanId.value = value);
  ObservableMap<String, MealPlanSlot> get slots => _slots;
  ObservableMap<String, VoteSessionSummary> get activeSessions =>
      _activeSessions;

  /// CHỈ dùng để dựng CẤU TRÚC lưới (21 key) — Guard §15.1: không đọc trực tiếp
  /// computed này trong Observer của 1 ô để lấy NỘI DUNG hiển thị.
  List<String> get currentWeekSlotKeys {
    return List<String>.generate(21, (int i) {
      final date = _currentWeekStart.value.add(Duration(days: i ~/ 3));
      const meals = <String>['BREAKFAST', 'LUNCH', 'DINNER'];
      return '${_isoDate(date)}_${meals[i % 3]}';
    });
  }

  int get pendingVoteCount =>
      _activeSessions.values
          .where((VoteSessionSummary s) =>
              s.status == VoteSessionUiStatus.open)
          .length;

  /// [AMEND, mới] Trạng thái 4-giá-trị của SLOT — suy derive tại client từ
  /// `dishes` (mirror `SlotStatusResolver` BE). KHÔNG đọc thẳng `status` field
  /// (lệch ngay sau optimistic/WS event mà không có lượt GET mới).
  SlotUiStatus uiStatusOf(String slotKey) {
    final slot = _slots[slotKey];
    if (slot == null || slot.dishes.isEmpty) return SlotUiStatus.empty;
    final hasVoting =
        slot.dishes.any((MealPlanDish d) => d.status == DishUiStatus.voting);
    if (hasVoting) return SlotUiStatus.voting;
    if (slot.dishes
        .every((MealPlanDish d) => d.status == DishUiStatus.confirmed)) {
      return SlotUiStatus.confirmed;
    }
    return SlotUiStatus.inProgress;
  }

  /// Tìm `slotKey` theo `slotId` thật — helper dùng chung cho mọi điểm cần
  /// reconcile 1 dish trong đúng slot.
  String? slotKeyOf(String slotId) => _slots.entries
      // ignore: always_specify_types
      .where((MapEntry<String, MealPlanSlot> e) =>
          e.value.id == slotId)
      .firstOrNull
      ?.key;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> loadWeekPlan() async {
    runInAction(() {
      _status.value = MealPlanLoadStatus.loading;
      _loadError.value = null;
    });
    try {
      final plan = await _api.getCurrent();
      _applyPlan(plan);
      runInAction(() => _status.value = MealPlanLoadStatus.ready);
      unawaited(_subscribeWs());
    } on ApiException catch (e) {
      runInAction(() {
        _loadError.value = e;
        _status.value = MealPlanLoadStatus.error;
      });
    }
  }

  /// Điều hướng tuần bất kỳ (Gap #1, D3). Trả `true` nếu hiển thị được.
  Future<bool> navigateWeek(int direction) async {
    final target =
        _currentWeekStart.value.add(Duration(days: 7 * direction));
    final targetIso = _isoDate(target);

    final cached = _weekPlanCache[targetIso];
    if (cached != null) {
      _applyPlan(cached, weekStart: target);
      runInAction(() => _status.value = MealPlanLoadStatus.ready);
      return true;
    }

    runInAction(() {
      _status.value = MealPlanLoadStatus.loading;
      _loadError.value = null;
    });
    try {
      final plan = await _api.create(target);
      _applyPlan(plan, weekStart: target);
      runInAction(() => _status.value = MealPlanLoadStatus.ready);
      return true;
    } catch (e) {
      if (e is BusinessException && e.code == 'ERR_PLAN_001') {
        // Tuần đã có plan ở server nhưng FE không có id — gap chưa fix BE.
        runInAction(() {
          _currentWeekStart.value = target;
          _slots.clear();
          _activeSessions.clear();
          _loadError.value = e;
          _status.value = MealPlanLoadStatus.error;
        });
        return false;
      }
      if (e is ApiException) {
        runInAction(() {
          _loadError.value = e;
          _status.value = MealPlanLoadStatus.error;
        });
        return false;
      }
      rethrow;
    }
  }

  void _applyPlan(MealPlanDto plan, {DateTime? weekStart}) {
    final wsIso = _isoDate(weekStart ?? plan.weekStart);
    _weekPlanCache[wsIso] = plan;
    runInAction(() {
      _currentWeekStart.value = weekStart ?? plan.weekStart;
      _currentPlanId.value = plan.id;
      for (final slot in plan.slots) {
        _slots['${_isoDate(slot.slotDate)}_${slot.mealTime}'] = slot;
      }
    });
  }

  /// Mở vote session cho 1 dish — fallback `GET vote/result` nếu 409 (Gap #2,
  /// D11). Trả summary đã được thêm vào `activeSessions[dishId]`.
  Future<VoteSessionSummary> openVoteSession(
    String slotId,
    String dishId, {
    int deadlineHours = 24,
  }) async {
    final planId = _currentPlanId.value;
    if (planId == null) {
      throw StateError('MealPlanStore.openVoteSession without currentPlanId');
    }
    try {
      final session = await _voteApi.open(
        planId,
        slotId,
        dishId,
        deadlineHours: deadlineHours,
      );
      runInAction(() => _activeSessions[dishId] = session);
      _setDishStatusLocal(slotId, dishId, DishUiStatus.voting);
      return session;
    } catch (e) {
      if (e is BusinessException && e.code == 'ERR_PLAN_002') {
        // Join session đã tồn tại qua sentinel — degraded fallback.
        final raw = await _voteApi.getResult(planId, slotId, dishId);
        final session = VoteSessionSummary.fromResultResponse(
          VoteSessionSummary.unknownSessionId,
          slotId,
          dishId,
          raw,
        );
        runInAction(() => _activeSessions[dishId] = session);
        _setDishStatusLocal(slotId, dishId, DishUiStatus.voting);
        return session;
      }
      rethrow;
    }
  }

  /// Merge raw `{votes, totalMembers, myVote}` vào session ĐÃ CÓ trong
  /// `activeSessions`. No-op nếu entry không còn (race với `winner_selected`).
  void applyVoteResultRaw(String dishId, Map<String, dynamic> raw) {
    final current = _activeSessions[dishId];
    if (current == null) return;
    runInAction(() {
      _activeSessions[dishId] = current.mergeVoteResult(raw);
    });
  }

  /// Gọi `GET vote/result` + merge — dùng cho refresh sau WS gián đoạn / case
  /// degraded rỗng.
  Future<void> refreshSession(String slotId, String dishId) async {
    final planId = _currentPlanId.value;
    if (planId == null) return;
    final raw = await _voteApi.getResult(planId, slotId, dishId);
    applyVoteResultRaw(dishId, raw);
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

  void _setDishStatusLocal(
      String slotId, String dishId, DishUiStatus status) {
    final key = slotKeyOf(slotId);
    if (key == null) return;
    final slot = _slots[key];
    if (slot == null) return;
    final dish = slot.dishes
        // ignore: always_specify_types
        .where((MealPlanDish d) => d.id == dishId)
        .firstOrNull;
    if (dish != null) _replaceDish(key, dish.copyWith(status: status));
  }

  /// Dùng bởi `SuggestionStore.acceptSuggestion()` — optimistic write.
  ///
  /// **Quan trọng (Finding #1 HIGH — review pass 1):** `applyManualAssign` xoá
  /// `activeSessions[dishId]` khi `dishSnapshot.recipe != null`. Caller nào
  /// cần rollback (như `SuggestionStore` accept fail) PHẢI snapshot session
  /// trước và khôi phục qua [restoreActiveSession] — không khôi phục =
  /// session thực bị mất, user quay lại vote session sẽ rơi vào nhánh degraded
  /// (fallback `getResult`) và mất suggestions giàu field chỉ vì 1 lần PUT lỗi.
  void applyManualAssign(String slotKey, MealPlanDish dishSnapshot) {
    _replaceDish(slotKey, dishSnapshot);
    if (dishSnapshot.recipe != null) {
      runInAction(() => _activeSessions.remove(dishSnapshot.id));
    }
  }

  /// Khôi phục `activeSessions[dishId]` đã snapshot trước [applyManualAssign].
  /// Dùng bởi `SuggestionStore.acceptSuggestion()` nhánh rollback. `null` an
  /// toàn (no-op) — phù hợp case dish chưa từng có session (race hiếm).
  void restoreActiveSession(
      String dishId, VoteSessionSummary? snapshot) {
    if (snapshot == null) return;
    runInAction(() => _activeSessions[dishId] = snapshot);
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
  Future<void> addDish(String slotId) async {
    final planId = _currentPlanId.value;
    final key = slotKeyOf(slotId);
    if (key == null || planId == null) return;
    try {
      final dish = await _api.addDish(planId, slotId);
      final slot = _slots[key];
      if (slot == null) return;
      // Đi qua _setDishes (Guard §15.15) thay vì inline slots[key]= trực tiếp.
      _setDishes(key, <MealPlanDish>[...slot.dishes, dish]);
    } on ApiException catch (e) {
      runInAction(() => _loadError.value = e);
    }
  }

  /// Xoá 1 dish (chỉ gọi sau người dùng confirm). KHÔNG optimistic — chờ 204.
  Future<void> removeDish(String slotId, String dishId) async {
    final planId = _currentPlanId.value;
    final key = slotKeyOf(slotId);
    if (key == null || planId == null) return;
    try {
      await _api.removeDish(planId, slotId, dishId);
      final slot = _slots[key];
      if (slot == null) return;
      _setDishes(
        key,
        slot.dishes
            .where((MealPlanDish d) => d.id != dishId)
            .toList(growable: false),
      );
      runInAction(() => _activeSessions.remove(dishId));
    } on ApiException catch (e) {
      runInAction(() => _loadError.value = e);
    }
  }

  // ── WebSocket ────────────────────────────────────────────────────────────

  Future<void> _subscribeWs() async {
    final householdId = _sessionStore.householdId;
    if (householdId == null) return;
    await _wsSub?.cancel();
    _wsSub = _realtimeStore.events.listen(handleVoteEvent);
  }

  /// Parse `raw['type']` THẲNG — destination `/vote` JSON phẳng, không bọc
  /// envelope `{eventId,eventType,data}` như destination `/inventory`.
  void handleVoteEvent(WsEventEnvelope envelope) {
    final raw = envelope.data as Map<String, dynamic>? ?? const <String, dynamic>{};
    final householdId = _sessionStore.householdId;
    if (envelope.householdId != householdId) return;

    final type = raw['type'] as String?;
    if (type == null) return;
    switch (type) {
      case 'session_opened':
        final slotId = raw['slotId'] as String?;
        final dishId = raw['dishId'] as String?;
        if (slotId == null || dishId == null) return;
        runInAction(() {
          _activeSessions[dishId] =
              VoteSessionSummary.fromOpenResponse(slotId, dishId, raw);
        });
        _setDishStatusLocal(slotId, dishId, DishUiStatus.voting);
      case 'member_voted':
        final dishId = raw['dishId'] as String?;
        if (dishId == null) return;
        final entry = _activeSessions[dishId];
        if (entry != null) {
          runInAction(() {
            _activeSessions[dishId] = entry.withTally(raw);
          });
        }
      case 'session_closed':
        final slotId = raw['slotId'] as String?;
        final dishId = raw['dishId'] as String?;
        if (dishId == null) return;
        runInAction(() => _activeSessions.remove(dishId));
        if (slotId != null) {
          _setDishStatusLocal(slotId, dishId, DishUiStatus.suggested);
        }
      case 'winner_selected':
        final slotId = raw['slotId'] as String?;
        final dishId = raw['dishId'] as String?;
        if (slotId == null || dishId == null) return;
        runInAction(() => _activeSessions.remove(dishId));
        final key = slotKeyOf(slotId);
        if (key != null) {
          final slot = _slots[key];
          if (slot == null) return;
          final dish = slot.dishes
              // ignore: always_specify_types
              .where((MealPlanDish d) => d.id == dishId)
              .firstOrNull;
          if (dish != null) {
            applyManualAssign(
              key,
              dish.copyWith(
                status: DishUiStatus.confirmed,
                recipe: AssignedRecipeSummary(
                  recipeId: raw['winnerRecipeId'] as String,
                  recipeName: raw['winnerRecipeName'] as String,
                  source: 'AI',
                ),
              ),
            );
          }
        }
      default:
        developer.log('MealPlanStore.handleVoteEvent: unknown type "$type"',
            name: 'MealPlanStore');
    }
  }

  void dispose() {
    _wsSub?.cancel();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _mondayOf(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
