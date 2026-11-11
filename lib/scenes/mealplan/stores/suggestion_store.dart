import 'package:mobx/mobx.dart';
import '../../../data/network/api_exception.dart';
import '../domain/meal_suggestion.dart';
import '../domain/shopping_list_sink.dart';
import 'meal_plan_store.dart';

enum SuggestionActionStatus { idle, accepting, rejecting, rerolling }

class SuggestionStore {
  SuggestionStore(
      {required this.slotId,
      required this.dishId,
      required MealPlanStore mealPlanStore,
      required ShoppingListSink shoppingSink})
      : _mealPlanStore = mealPlanStore,
        _shoppingSink = shoppingSink,
        _state = mealPlanStore.suggestionState(dishId);
  final String slotId, dishId;
  final MealPlanStore _mealPlanStore;
  final ShoppingListSink _shoppingSink;
  final Observable<int> _index = Observable(0);
  bool _disposed = false;
  final DishSuggestionState _state;
  bool get loading => _state.reading && suggestionCount == 0;
  int get index => _index.value < suggestionCount ? _index.value : 0;
  List<MealSuggestion> get _suggestions =>
      _state.active ? _mealPlanStore.suggestions[dishId] ?? [] : [];
  int get suggestionCount => _suggestions.length;
  MealSuggestion? get currentSuggestion =>
      suggestionCount == 0 ? null : _suggestions[index];
  SuggestionActionStatus get actionStatus => switch (_state.pending) {
        DishMutation.generate => SuggestionActionStatus.rerolling,
        DishMutation.select => SuggestionActionStatus.accepting,
        null => SuggestionActionStatus.idle,
      };
  ApiException? get actionError => _state.mutationError ?? _state.readError;
  ApiException? get readError => _state.readError;
  bool get outcomeUnknown => _state.outcomeUnknown;
  bool get isReading => _state.reading;
  bool get canContinue =>
      !_disposed && !_mealPlanStore.isConfirmed && _state.canContinue;
  bool get canWrite =>
      !_disposed && _state.active && _mealPlanStore.canEditDish(dishId);
  bool get suggestionsUnavailable =>
      suggestionCount == 0 && actionError != null;
  bool get hasNext => index + 1 < suggestionCount;
  bool get hasPrevious => index > 0;
  void viewNext() {
    if (hasNext) runInAction(() => _index.value = index + 1);
  }

  void viewPrevious() {
    if (hasPrevious) runInAction(() => _index.value = index - 1);
  }

  Future<void> load() async {
    if (_disposed || !_state.active) return;
    if (outcomeUnknown || _state.pending == DishMutation.select) {
      await _mealPlanStore.recheckSuggestion(slotId, dishId);
    } else {
      await _mealPlanStore.loadSuggestions(slotId, dishId);
    }
  }

  Future<void> recheck() async {
    if (_disposed || !_state.active) return;
    await _mealPlanStore.recheckSuggestion(slotId, dishId);
  }

  void continueFromSnapshot() {
    if (canContinue) _mealPlanStore.acknowledgeSuggestion(dishId);
  }

  Future<void> refreshSuggestions() async {
    if (!canWrite) return;
    final result =
        await _mealPlanStore.loadSuggestions(slotId, dishId, regenerate: true);
    if (!_disposed && result == DishRequestResult.applied) {
      runInAction(() => _index.value = 0);
    }
  }

  Future<bool> acceptSuggestion() async {
    final s = currentSuggestion;
    if (s == null || s.id == null || s.isBlocked || !canWrite) return false;
    final result = await _mealPlanStore.selectSuggestion(slotId, dishId, s.id!);
    return !_disposed && result == DishRequestResult.applied;
  }

  void dispose() {
    _disposed = true;
  }

  void rejectSuggestion() => viewNext();
  Future<int> addMissingToShoppingList() async {
    final target = currentSuggestion;
    if (target == null || target.missingIngredients.isEmpty) return 0;
    return _shoppingSink.addItems(target.missingIngredients);
  }
}
