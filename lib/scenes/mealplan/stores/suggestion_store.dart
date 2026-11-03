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
        _shoppingSink = shoppingSink;
  final String slotId, dishId;
  final MealPlanStore _mealPlanStore;
  final ShoppingListSink _shoppingSink;
  final Observable<int> _index = Observable(0);
  final Observable<SuggestionActionStatus> _actionStatus =
      Observable(SuggestionActionStatus.idle);
  final Observable<ApiException?> _actionError = Observable(null);
  final Observable<bool> _loading = Observable(false);
  bool get loading => _loading.value;
  int get index => _index.value;
  List<MealSuggestion> get _suggestions =>
      _mealPlanStore.suggestions[dishId] ?? [];
  int get suggestionCount => _suggestions.length;
  MealSuggestion? get currentSuggestion =>
      index < _suggestions.length ? _suggestions[index] : null;
  SuggestionActionStatus get actionStatus => _actionStatus.value;
  ApiException? get actionError => _actionError.value;
  bool get suggestionsUnavailable =>
      suggestionCount == 0 && _actionError.value != null;
  bool get hasNext => index + 1 < suggestionCount;
  bool get hasPrevious => index > 0;
  void viewNext() {
    if (hasNext) runInAction(() => _index.value++);
  }

  void viewPrevious() {
    if (hasPrevious) runInAction(() => _index.value--);
  }

  Future<void> load() async {
    runInAction(() {
      _loading.value = true;
      _actionError.value = null;
    });
    try {
      await _mealPlanStore.loadSuggestions(slotId, dishId);
    } on ApiException catch (e) {
      runInAction(() => _actionError.value = e);
    } finally {
      runInAction(() => _loading.value = false);
    }
  }

  Future<void> refreshSuggestions() async {
    if (actionStatus != SuggestionActionStatus.idle) return;
    runInAction(() {
      _actionStatus.value = SuggestionActionStatus.rerolling;
      _actionError.value = null;
    });
    try {
      await _mealPlanStore.loadSuggestions(slotId, dishId, regenerate: true);
      runInAction(() => _index.value = 0);
    } on ApiException catch (e) {
      runInAction(() => _actionError.value = e);
    } finally {
      runInAction(() => _actionStatus.value = SuggestionActionStatus.idle);
    }
  }

  Future<bool> acceptSuggestion() async {
    final s = currentSuggestion;
    if (s == null ||
        s.id == null ||
        s.isBlocked ||
        actionStatus != SuggestionActionStatus.idle) {
      return false;
    }
    runInAction(() {
      _actionStatus.value = SuggestionActionStatus.accepting;
      _actionError.value = null;
    });
    try {
      await _mealPlanStore.selectSuggestion(slotId, dishId, s.id!);
      return true;
    } on ApiException catch (e) {
      runInAction(() => _actionError.value = e);
      return false;
    } finally {
      runInAction(() => _actionStatus.value = SuggestionActionStatus.idle);
    }
  }

  void rejectSuggestion() => viewNext();
  Future<int> addMissingToShoppingList() async {
    final target = currentSuggestion;
    if (target == null || target.missingIngredients.isEmpty) return 0;
    return _shoppingSink.addItems(target.missingIngredients);
  }

  void clearError() => runInAction(() => _actionError.value = null);
}
