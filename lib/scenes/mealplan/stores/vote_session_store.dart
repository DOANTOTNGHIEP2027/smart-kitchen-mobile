import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../data/vote_api.dart';
import '../domain/vote_session_summary.dart';
import 'meal_plan_store.dart';

/// Store cho `VoteSessionScene` (FE-7 §8). Gắn theo `dishId` (khoá thật của
/// session sau amendment #43).
///
/// **Quan trọng DI (D7):** nhận `MealPlanStore` qua `Get.find`, không tạo mới.
/// `MealPlanStore` phải sống trong nav stack để share state giữa weekly scene
/// và vote scene.
class VoteSessionStore {
  VoteSessionStore({
    required this.slotId,
    required this.dishId,
    required MealPlanStore mealPlanStore,
    required VoteApi voteApi,
  })  : _mealPlanStore = mealPlanStore,
        _voteApi = voteApi;

  final String slotId;
  final String dishId;
  final MealPlanStore _mealPlanStore;
  final VoteApi _voteApi;

  final Observable<bool> _isCasting = Observable<bool>(false);
  final Observable<ApiException?> _castError =
      Observable<ApiException?>(null);

  bool get isCasting => _isCasting.value;
  ApiException? get castError => _castError.value;

  /// Computed lookup `activeSessions[dishId]` — `null` khi `session_closed` /
  /// `winner_selected` tới hoặc dish bị `removeDish()`.
  VoteSessionSummary? get session =>
      _mealPlanStore.activeSessions[dishId];

  String? get currentPlanId => _mealPlanStore.currentPlanId;

  Future<void> init() async {
    if (_mealPlanStore.activeSessions[dishId] == null) {
      try {
        await _mealPlanStore.openVoteSession(slotId, dishId);
      } on ApiException catch (e) {
        runInAction(() => _castError.value = e);
        return;
      }
    }
    // MealPlanStore là owner duy nhất của subscription vote WebSocket. Session
    // store chỉ đọc `activeSessions` dùng chung, nên không được subscribe lần
    // hai khi mở bottom-sheet (tránh tally bị apply hai lần).
  }

  /// Cast — trả raw `{votes, totalMembers, myVote}`, merge qua
  /// `MealPlanStore.applyVoteResultRaw` để GIỮ suggestions đã có.
  Future<void> castVote(String recipeId) async {
    final planId = _mealPlanStore.currentPlanId;
    if (planId == null) return;
    runInAction(() {
      _isCasting.value = true;
      _castError.value = null;
    });
    try {
      final raw = await _voteApi.cast(
        planId,
        slotId,
        dishId,
        recipeId: recipeId,
      );
      _mealPlanStore.applyVoteResultRaw(dishId, raw);
    } on ApiException catch (e) {
      runInAction(() => _castError.value = e);
    } finally {
      runInAction(() => _isCasting.value = false);
    }
  }

  Future<void> refreshTally() async {
    runInAction(() => _castError.value = null);
    try {
      await _mealPlanStore.refreshSession(slotId, dishId);
    } on ApiException catch (e) {
      runInAction(() => _castError.value = e);
    }
  }

  Future<void> closeManually() async {
    final planId = _mealPlanStore.currentPlanId;
    if (planId == null) return;
    try {
      await _voteApi.close(planId, slotId, dishId);
      // winner tới qua WS (nếu kết nối) — nếu không, GET vote/result khi quay
      // lại lưới không tự update (D10) → user tự pull-to-refresh.
    } on ApiException catch (e) {
      runInAction(() => _castError.value = e);
    }
  }

  void clearError() => runInAction(() => _castError.value = null);

}
