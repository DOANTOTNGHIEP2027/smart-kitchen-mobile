import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../data/meal_plan_api.dart';
import '../domain/meal_plan_slot.dart';
import '../domain/meal_suggestion.dart';
import '../domain/shopping_list_sink.dart';
import 'meal_plan_store.dart';

enum SuggestionActionStatus { idle, accepting, rejecting, rerolling }

/// Store cho `MealSuggestionDetailScene` (FE-7 §9). Đọc source suggestions
/// LUÔN qua `MealPlanStore.activeSessions[dishId]` — không tự fetch giữ bản sao.
class SuggestionStore {
  SuggestionStore({
    required this.slotId,
    required this.dishId,
    required MealPlanStore mealPlanStore,
    required MealPlanApi api,
    required ShoppingListSink shoppingSink,
    this.householdCalorieGoal,
  })  : _mealPlanStore = mealPlanStore,
        _api = api,
        _shoppingSink = shoppingSink;

  final String slotId;
  final String dishId;
  final MealPlanStore _mealPlanStore;
  final MealPlanApi _api;
  final ShoppingListSink _shoppingSink;
  final double? householdCalorieGoal;

  final Observable<int> _index = Observable<int>(0);
  final Observable<SuggestionActionStatus> _actionStatus =
      Observable<SuggestionActionStatus>(SuggestionActionStatus.idle);
  final Observable<ApiException?> _actionError =
      Observable<ApiException?>(null);

  int get index => _index.value;
  int get suggestionCount => _suggestions.length;
  SuggestionActionStatus get actionStatus => _actionStatus.value;
  ApiException? get actionError => _actionError.value;

  List<MealSuggestion> get _suggestions =>
      _mealPlanStore.activeSessions[dishId]?.suggestions ??
      const <MealSuggestion>[];

  MealSuggestion? get currentSuggestion =>
      _index.value < _suggestions.length
          ? _suggestions[_index.value]
          : null;

  bool get hasNext => _index.value + 1 < _suggestions.length;
  bool get hasPrevious => _index.value > 0;

  /// Di chuyển giữa các candidate chỉ đổi view state cục bộ, không vote hay
  /// thay đổi dish. Đây là hành vi của nút/swap trái-phải trên màn gợi ý.
  void viewNext() {
    if (hasNext) runInAction(() => _index.value++);
  }

  void viewPrevious() {
    if (hasPrevious) runInAction(() => _index.value--);
  }

  /// `true` khi session join-degraded (CRITICAL-4) VÀ suggestions rỗng — UI
  /// PHẢI hiển thị state riêng, không lẫn với "đã xem hết".
  bool get suggestionsUnavailable =>
      (_mealPlanStore.activeSessions[dishId]?.suggestionsSourceDegraded ??
          false) &&
      _suggestions.isEmpty;

  MealPlanDish? _currentDish() {
    final key = _mealPlanStore.slotKeyOf(slotId);
    if (key == null) return null;
    final slot = _mealPlanStore.slots[key];
    if (slot == null) return null;
    return slot.dishes
        // ignore: always_specify_types
        .where((MealPlanDish d) => d.id == dishId)
        .firstOrNull;
  }

  /// Accept — **optimistic write** (D6). Trước khi gọi API, ghi đè dish thành
  /// CONFIRMED; nếu API lỗi, rollback về ĐÚNG snapshot `previous` (đầy đủ, giữ
  /// đúng `status` gốc — thường là `voting`, không phải `empty`).
  ///
  /// **Quan trọng (Finding #1 HIGH — review pass 1):** `applyManualAssign` xoá
  /// `activeSessions[dishId]` khi optimistic gán recipe. Cần snapshot session
  /// TRƯỚC và khôi phục trong rollback — nếu không, sau khi accept lỗi, user
  /// quay lại vote session sẽ rơi vào degraded fallback và mất suggestions.
  Future<bool> acceptSuggestion() async {
    final target = currentSuggestion;
    if (target == null) return false;
    final key = _mealPlanStore.slotKeyOf(slotId);
    final previous = _currentDish();
    if (key == null || previous == null) return false;

    final planId = _mealPlanStore.currentPlanId;
    if (planId == null) return false;

    // Snapshot session hiện tại trước optimistic write — có thể null nếu dish
    // chưa từng mở vote (race hiếm), nhưng thường phải có vì accept chỉ khả
    // dụng khi dish đang có session mở.
    final previousSession = _mealPlanStore.activeSessions[dishId];

    runInAction(() {
      _actionStatus.value = SuggestionActionStatus.accepting;
      _actionError.value = null;
    });

    _mealPlanStore.applyManualAssign(
      key,
      previous.copyWith(
        status: DishUiStatus.confirmed,
        recipe: AssignedRecipeSummary(
          recipeId: target.recipeId,
          recipeName: target.mealName,
          source: 'MANUAL',
        ),
      ),
    );

    try {
      final updated = await _api.assignDishRecipe(
        planId,
        slotId,
        dishId,
        recipeId: target.recipeId,
        recipeName: target.mealName,
      );
      _mealPlanStore.applyServerDish(updated);
      runInAction(() => _actionStatus.value = SuggestionActionStatus.idle);
      return true;
    } on ApiException catch (e) {
      // Rollback cả dish VÀ activeSessions — giữ đúng state trước optimistic.
      _mealPlanStore.applyManualAssign(key, previous);
      if (previousSession != null) {
        _mealPlanStore.restoreActiveSession(dishId, previousSession);
      }
      runInAction(() {
        _actionError.value = e;
        _actionStatus.value = SuggestionActionStatus.idle;
      });
      return false;
    }
  }

  /// Reject — local-only, không gọi API.
  void rejectSuggestion() {
    viewNext();
  }

  /// Re-roll — KHÔNG optimistic (AC). Gần như luôn nhận 409 cho đúng dish này
  /// (Gap #2 sau amendment #43 — `UNIQUE(dish_id)`).
  Future<bool> reRollSuggestion() async {
    runInAction(() {
      _actionStatus.value = SuggestionActionStatus.rerolling;
      _actionError.value = null;
    });
    try {
      final session =
          await _mealPlanStore.openVoteSession(slotId, dishId);
      if (session.suggestions.isNotEmpty) {
        runInAction(() => _index.value = 0);
      }
      runInAction(() => _actionStatus.value = SuggestionActionStatus.idle);
      return true;
    } catch (e) {
      runInAction(() {
        _actionStatus.value = SuggestionActionStatus.idle;
        if (e is ApiException) {
          _actionError.value = e;
        }
      });
      return false;
    }
  }

  /// Thêm nguyên liệu thiếu vào shopping list (FE-7 §9.4). Sẽ no-op cho tới
  /// khi Epic 5 ship.
  Future<void> addMissingToShoppingList() async {
    final target = currentSuggestion;
    if (target == null || target.missingIngredients.isEmpty) return;
    await _shoppingSink.addItems(target.missingIngredients);
  }

  /// Refresh degraded (CRITICAL-4) — thử lại phòng đã có người vote từ lúc join.
  Future<void> refreshSuggestions() async {
    runInAction(() => _actionError.value = null);
    try {
      await _mealPlanStore.refreshSession(slotId, dishId);
    } on ApiException catch (e) {
      runInAction(() => _actionError.value = e);
    }
  }

  void clearError() => runInAction(() => _actionError.value = null);
}
