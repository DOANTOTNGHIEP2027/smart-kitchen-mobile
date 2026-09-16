import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/vote_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/vote_session_summary.dart';

class FakeMealPlanApi implements MealPlanApi {
  Future<MealPlanDto> Function()? onGetCurrent;
  Future<MealPlanDto> Function(String id)? onGetById;
  Future<MealPlanDto> Function(DateTime weekStart)? onCreate;
  Future<MealPlanDish> Function(String planId, String slotId)? onAddDish;
  Future<void> Function(String planId, String slotId, String dishId)?
      onRemoveDish;
  Future<MealPlanDish> Function(
      String planId,
      String slotId,
      String dishId,
      {required String recipeId,
      required String recipeName})? onAssignDishRecipe;

  Object? onGetCurrentError;

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
  Future<void> removeDish(
      String planId, String slotId, String dishId) async {
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

class FakeVoteApi implements VoteApi {
  Future<VoteSessionSummary> Function(
      String planId, String slotId, String dishId,
      {required int deadlineHours})? onOpen;
  Future<Map<String, dynamic>> Function(String planId, String slotId,
          String dishId,
          {required String recipeId})? onCast;
  Future<Map<String, dynamic>> Function(
      String planId, String slotId, String dishId)? onGetResult;
  Future<void> Function(String planId, String slotId, String dishId)?
      onClose;

  Object? onOpenError;

  @override
  Future<VoteSessionSummary> open(
    String planId,
    String slotId,
    String dishId, {
    required int deadlineHours,
  }) async {
    if (onOpenError != null) throw onOpenError!;
    if (onOpen != null) {
      return onOpen!(planId, slotId, dishId, deadlineHours: deadlineHours);
    }
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> cast(
    String planId,
    String slotId,
    String dishId, {
    required String recipeId,
  }) async {
    if (onCast != null) {
      return onCast!(planId, slotId, dishId, recipeId: recipeId);
    }
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getResult(
      String planId, String slotId, String dishId) async {
    if (onGetResult != null) return onGetResult!(planId, slotId, dishId);
    throw UnimplementedError();
  }

  @override
  Future<void> close(String planId, String slotId, String dishId) async {
    if (onClose != null) {
      await onClose!(planId, slotId, dishId);
      return;
    }
    throw UnimplementedError();
  }
}
