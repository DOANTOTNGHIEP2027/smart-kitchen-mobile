import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/shopping_list_sink.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/suggestion_store.dart';
import 'fake_meal_plan_api.dart';

class Sink implements ShoppingListSink {
  @override
  Future<int> addItems(List<IngredientItem> items) async => items.length;
}

void main() {
  test(
      'selection uses persisted suggestion UUID, commits source AI only after server succeeds',
      () async {
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
    final suggestions = FakeMealSuggestionApi()
      ..onList = () async => [
            const MealSuggestion(
                id: 'uuid', recipeId: 'kb-raw', mealName: 'Soup')
          ];
    final plan = MealPlanStore(api: api, suggestionApi: suggestions);
    await plan.loadWeekPlan();
    final store = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: plan, shoppingSink: Sink());
    await store.load();
    suggestions.onSelect = (id) async {
      expect(id, 'uuid');
      throw BusinessException('ERR_MEAL_OPTION_BLOCKED', 'blocked');
    };
    expect(await store.acceptSuggestion(), false);
    expect(plan.slots.values.first.dishes.first.recipe, isNull);
    expect(store.suggestionsUnavailable, false);
    expect(store.currentSuggestion?.id, 'uuid');
    suggestions.onSelect = (id) async => const MealPlanDish(
        id: 'd',
        slotId: 's',
        sortOrder: 0,
        status: DishUiStatus.confirmed,
        recipe: AssignedRecipeSummary(
            recipeId: 'real-uuid', recipeName: 'Soup', source: 'AI'));
    expect(await store.acceptSuggestion(), true);
    expect(plan.slots.values.first.dishes.first.recipe?.source, 'AI');
  });
  test('failed regeneration keeps saved suggestions available for selection',
      () async {
    final api = FakeMealSuggestionApi()
      ..onGenerate =
          () async => throw ServerException('ERR_AI_TIMEOUT', 'timeout');
    final plan = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    plan.currentPlanIdForTesting = 'p';
    plan.suggestions['d'] = [
      const MealSuggestion(id: 'uuid', recipeId: 'r', mealName: 'Soup'),
    ];
    final store = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: plan, shoppingSink: Sink());
    await store.refreshSuggestions();
    expect(store.actionError?.code, 'ERR_AI_TIMEOUT');
    expect(store.suggestionsUnavailable, false);
    expect(store.currentSuggestion?.id, 'uuid');
    expect(store.actionStatus, SuggestionActionStatus.idle);
  });

  test('blocked suggestion never reaches selection API', () async {
    final plan = MealPlanStore(
        api: FakeMealPlanApi(), suggestionApi: FakeMealSuggestionApi());
    plan.currentPlanIdForTesting = 'p';
    plan.suggestions['d'] = [
      const MealSuggestion(
          id: 'uuid', recipeId: 'r', mealName: 'Soup', isBlocked: true)
    ];
    final store = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: plan, shoppingSink: Sink());
    expect(await store.acceptSuggestion(), false);
  });
}
