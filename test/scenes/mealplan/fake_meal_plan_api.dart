import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_suggestion_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';

class FakeMealPlanApi implements MealPlanApi {
  Future<MealPlanDto> Function()? onGetCurrent;
  Future<MealPlanDto> Function(String id)? onGetById;
  Future<MealPlanDto> Function(DateTime weekStart)? onCreate;
  Future<MealPlanDish> Function(String planId, String slotId)? onAddDish;
  Future<void> Function(String planId, String slotId, String dishId)?
      onRemoveDish;
  Future<MealPlanDish> Function(String planId, String slotId, String dishId,
      {required String recipeId,
      required String recipeName})? onAssignDishRecipe;

  Object? onGetCurrentError;

  Future<MealPlanDto> Function(DateTime week)? onGetWeek;
  Future<void> Function(String id)? onConfirm;
  @override
  Future<MealPlanDto> getWeek(DateTime week) =>
      onGetWeek != null ? onGetWeek!(week) : getCurrent();
  @override
  Future<void> confirm(String id) async {
    if (onConfirm != null) await onConfirm!(id);
  }

  @override
  Future<MealPlanDto> getCurrent() async {
    if (onGetCurrentError != null) throw onGetCurrentError!;
    if (onGetCurrent != null) return onGetCurrent!();
    throw UnimplementedError();
  }

  @override
  Future<MealPlanDto> getById(String id) async {
    if (onGetById != null) return onGetById!(id);
    throw UnimplementedError();
  }

  @override
  Future<MealPlanDto> create(DateTime weekStart) async {
    if (onCreate != null) return onCreate!(weekStart);
    throw UnimplementedError();
  }

  @override
  Future<MealPlanDish> addDish(String planId, String slotId) async {
    if (onAddDish != null) return onAddDish!(planId, slotId);
    throw UnimplementedError();
  }

  @override
  Future<void> removeDish(String planId, String slotId, String dishId) async {
    if (onRemoveDish != null) {
      await onRemoveDish!(planId, slotId, dishId);
      return;
    }
    throw UnimplementedError();
  }

  @override
  Future<MealPlanDish> assignDishRecipe(
    String planId,
    String slotId,
    String dishId, {
    required String recipeId,
    required String recipeName,
  }) async {
    if (onAssignDishRecipe != null) {
      return onAssignDishRecipe!(planId, slotId, dishId,
          recipeId: recipeId, recipeName: recipeName);
    }
    throw UnimplementedError();
  }
}

class FakeMealSuggestionApi implements MealSuggestionApi {
  Future<List<MealSuggestion>> Function()? onList, onGenerate;
  Future<MealPlanDish> Function(String id)? onSelect;
  @override
  Future<List<MealSuggestion>> list(String p, String s, String d) async =>
      onList == null ? <MealSuggestion>[] : onList!();
  @override
  Future<List<MealSuggestion>> generate(String p, String s, String d) async =>
      onGenerate == null ? <MealSuggestion>[] : onGenerate!();
  @override
  Future<MealPlanDish> select(String p, String s, String d, String id) async =>
      onSelect!(id);
}
