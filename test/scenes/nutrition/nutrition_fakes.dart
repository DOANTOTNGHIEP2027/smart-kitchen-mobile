import 'dart:async';

import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';

import '../recipe/fake_recipe_catalog_api.dart';

/// Fake recipe API cho nutrition: map `recipeId → nutrition`, có thể treo
/// (Completer) hoặc ném lỗi từng recipe.
class NutritionRecipeApi extends FakeRecipeCatalogApi {
  NutritionRecipeApi(this.nutrition) {
    onGetById = (id) async {
      final pending = hold[id];
      if (pending != null) await pending.future;
      final error = errors[id];
      if (error != null) throw error;
      return withNutrition(id, nutrition[id]);
    };
  }

  final Map<String, RecipeNutrition?> nutrition;
  final Map<String, Object> errors = <String, Object>{};
  final Map<String, Completer<void>> hold = <String, Completer<void>>{};
}

Recipe withNutrition(String id, RecipeNutrition? n) => Recipe(
      id: id,
      name: 'Món $id',
      dietTypes: const <String>[],
      source: 'MANUAL',
      createdAt: fixedTime,
      updatedAt: fixedTime,
      nutrition: n,
    );

class NutritionHealthApi implements HealthApi {
  NutritionHealthApi({this.target});

  int? target;
  Object? error;
  int calls = 0;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    calls++;
    if (error != null) throw error!;
    return HealthProfile(userId: 'u1', targetDailyCalories: target, allergens: const <Allergen>[]);
  }

  @override
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload) => throw UnimplementedError();
  @override
  Future<List<Allergen>> getAllergenCatalog() => throw UnimplementedError();
  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) => throw UnimplementedError();
  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) => throw UnimplementedError();
}

RecipeNutrition kcal(double calories, {double p = 20, double c = 50, double f = 10}) =>
    RecipeNutrition(calories: calories, proteinG: p, carbsG: c, fatG: f);

MealPlanSlot plannedSlot(DateTime weekStart, int day, String mealTime, List<String> recipeIds,
        {DishUiStatus status = DishUiStatus.confirmed}) =>
    MealPlanSlot(
      id: 'slot-$day-$mealTime',
      slotDate: weekStart.add(Duration(days: day)),
      mealTime: mealTime,
      dishes: <MealPlanDish>[
        for (var i = 0; i < recipeIds.length; i++)
          MealPlanDish(
            id: 'dish-$day-$mealTime-$i',
            slotId: 'slot-$day-$mealTime',
            sortOrder: i,
            status: status,
            recipe: AssignedRecipeSummary(
                recipeId: recipeIds[i], recipeName: 'Món ${recipeIds[i]}', source: 'MANUAL'),
          ),
      ],
    );

MealPlanDto planOf(DateTime weekStart, List<MealPlanSlot> slots) => MealPlanDto(
      id: 'plan-1',
      householdId: 'h1',
      weekStart: weekStart,
      slots: slots,
    );

BusinessException notFound() => BusinessException('ERR_RECIPE_NOT_FOUND', 'not found');
