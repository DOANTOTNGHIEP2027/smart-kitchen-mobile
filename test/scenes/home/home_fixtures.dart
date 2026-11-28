import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';

final DateTime _t = DateTime(2026, 11, 1);

InventoryItemModel stock(String name, double quantity, String unit) =>
    InventoryItemModel(
      id: 'inv-$name-$unit',
      householdId: 'h1',
      name: name,
      quantity: quantity,
      unit: unit,
      version: 0,
      isLowStock: false,
      isExpiringSoon: false,
      createdBy: 'u1',
      createdAt: _t,
      updatedAt: _t,
    );

MealPlanDish dish(String id, {String? recipeId, int sortOrder = 0}) =>
    MealPlanDish(
      id: id,
      slotId: 's',
      sortOrder: sortOrder,
      status: recipeId == null ? DishUiStatus.empty : DishUiStatus.confirmed,
      recipe: recipeId == null
          ? null
          : AssignedRecipeSummary(
              recipeId: recipeId,
              recipeName: 'Món $recipeId',
              source: 'MANUAL',
            ),
    );

MealPlanSlot slot(
  String id,
  DateTime date,
  String mealTime,
  List<MealPlanDish> dishes,
) =>
    MealPlanSlot(id: id, slotDate: date, mealTime: mealTime, dishes: dishes);

MealPlanDto plan(List<MealPlanSlot> slots, {String id = 'mp-1'}) => MealPlanDto(
      id: id,
      householdId: 'h1',
      weekStart: DateTime(2026, 11, 23),
      slots: slots,
    );
