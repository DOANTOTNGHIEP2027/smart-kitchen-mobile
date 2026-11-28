import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_mapper.dart';

void main() {
  test('dish gán tay đọc missingIngredients camelCase, đổi đơn vị chuẩn', () {
    final dish = MealPlanMapper.dishFromJson(<String, dynamic>{
      'id': 'd',
      'slotId': 's',
      'sortOrder': 0,
      'status': 'CONFIRMED',
      'recipe': <String, dynamic>{
        'recipeId': 'r',
        'recipeName': 'Trứng chiên',
        'source': 'MANUAL',
      },
      'missingIngredients': <Map<String, dynamic>>[
        <String, dynamic>{
          'ingredientName': 'Trứng gà',
          'requiredQuantity': 3,
          'availableQuantity': 1,
          'shortfallQuantity': 2,
          'unit': 'PIECE',
        },
        <String, dynamic>{
          'ingredientName': 'Đậu phộng',
          'requiredQuantity': 100,
          'availableQuantity': 0,
          'shortfallQuantity': 100,
          'unit': 'GRAM',
        },
      ],
    });
    expect(dish.missingIngredients!.map((i) => (i.name, i.quantity, i.unit)), [
      ('Trứng gà', 2.0, 'quả'),
      ('Đậu phộng', 100.0, 'g'),
    ]);
  });

  test('response không có field ⇒ null, không suy ra "đủ"', () {
    final dish = MealPlanMapper.dishFromJson(<String, dynamic>{
      'id': 'd',
      'slotId': 's',
      'status': 'EMPTY',
    });
    expect(dish.missingIngredients, isNull);
  });
}
