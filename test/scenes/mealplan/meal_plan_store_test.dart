import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'fake_meal_plan_api.dart';

MealPlanDto plan(String id, {String status = 'DRAFT'}) => MealPlanDto(
        id: id,
        householdId: 'h',
        weekStart: DateTime(2026, 11, 2),
        status: status,
        slots: [
          MealPlanSlot(
              id: 'slot',
              slotDate: DateTime(2026, 11, 3),
              mealTime: 'LUNCH',
              dishes: const [])
        ]);
void main() {
  test('loads existing week without creating a new plan', () async {
    final api = FakeMealPlanApi()..onGetWeek = (_) => Future.value(plan('p'));
    api.onCreate = (_) => throw StateError('must not create');
    final store =
        MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
    await store.loadWeekPlan();
    expect(store.currentPlanId, 'p');
    expect(store.slots.length, 1);
    expect(store.status, MealPlanLoadStatus.ready);
  });
  test('missing week creates; concurrent create conflict refetches', () async {
    var calls = 0;
    final api = FakeMealPlanApi()
      ..onGetWeek = (_) async {
        if (calls++ == 0) {
          throw BusinessException('ERR_PLAN_NOT_FOUND', 'missing');
        }
        return plan('existing');
      };
    api.onCreate =
        (_) async => throw BusinessException('ERR_PLAN_001', 'exists');
    final store =
        MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
    await store.loadWeekPlan();
    expect(store.currentPlanId, 'existing');
  });
  test('late week response cannot replace newer navigation', () async {
    final first = Completer<MealPlanDto>();
    var calls = 0;
    final api = FakeMealPlanApi()
      ..onGetWeek =
          (_) => calls++ == 0 ? first.future : Future.value(plan('new'));
    final store =
        MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
    final pending = store.loadWeekPlan();
    await store.navigateWeek(1);
    first.complete(plan('old'));
    await pending;
    expect(store.currentPlanId, 'new');
  });
  test('confirm failure retains editable state; success freezes menu',
      () async {
    final api = FakeMealPlanApi()..onGetWeek = (_) async => plan('p');
    final store =
        MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
    await store.loadWeekPlan();
    api.onConfirm = (_) async =>
        throw BusinessException('ERR_PLAN_INCOMPLETE', 'incomplete');
    expect(await store.confirm(), false);
    expect(store.isConfirmed, false);
    api.onConfirm = (_) async {};
    expect(await store.confirm(), true);
    expect(store.isConfirmed, true);
  });
  test('manual recipe choice works without invoking AI', () async {
    final api = FakeMealPlanApi()
      ..onGetWeek = (_) async => MealPlanDto(
              id: 'p',
              householdId: 'h',
              weekStart: DateTime(2026, 11, 2),
              slots: [
                MealPlanSlot(
                    id: 's',
                    slotDate: DateTime(2026, 11, 3),
                    mealTime: 'LUNCH',
                    dishes: [
                      const MealPlanDish(
                          id: 'd',
                          slotId: 's',
                          sortOrder: 0,
                          status: DishUiStatus.empty)
                    ])
              ]);
    api.onAssignDishRecipe = (p, s, d,
            {required recipeId, required recipeName}) async =>
        MealPlanDish(
            id: d,
            slotId: s,
            sortOrder: 0,
            status: DishUiStatus.confirmed,
            recipe: AssignedRecipeSummary(
                recipeId: recipeId, recipeName: recipeName, source: 'MANUAL'));
    final suggestions = FakeMealSuggestionApi()
      ..onGenerate = () => throw StateError('AI unavailable');
    final store = MealPlanStore(api: api, suggestionApi: suggestions);
    await store.loadWeekPlan();
    expect(await store.assignManual('s', 'd', 'catalog-id', 'Soup'), true);
    expect(store.slots.values.first.dishes.first.recipe?.source, 'MANUAL');
  });

  test('late suggestion read cannot replace a newer generation', () async {
    final old = Completer<List<MealSuggestion>>();
    final suggestions = FakeMealSuggestionApi()
      ..onList = () => old.future;
    suggestions.onGenerate = () async =>
            [const MealSuggestion(id: 'new', recipeId: 'raw', mealName: 'New')];
    final store =
        MealPlanStore(api: FakeMealPlanApi(), suggestionApi: suggestions);
    store.currentPlanIdForTesting = 'p';
    final pending = store.loadSuggestions('s', 'd');
    await store.loadSuggestions('s', 'd', regenerate: true);
    old.complete([
      const MealSuggestion(id: 'old', recipeId: 'raw-old', mealName: 'Old')
    ]);
    await pending;
    expect(store.suggestions['d']?.single.id, 'new');
  });
}
