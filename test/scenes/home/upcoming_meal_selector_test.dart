import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/home/domain/upcoming_meal.dart';

import 'home_fixtures.dart';

void main() {
  final day = DateTime(2026, 11, 28);

  test('chọn slot gần nhất chưa qua, bỏ slot đã qua', () {
    final p = plan([
      slot('breakfast', day, 'BREAKFAST', [dish('d1', recipeId: 'r1')]),
      slot('dinner', day, 'DINNER', [dish('d2', recipeId: 'r2')]),
      slot('lunch', day, 'LUNCH', [dish('d3', recipeId: 'r3')]),
    ]);

    final meal = selectUpcomingMeal(p, DateTime(2026, 11, 28, 10));

    expect(meal?.slot.id, 'lunch');
  });

  test('slot đang diễn ra trong 2 giờ vẫn được chọn', () {
    final p = plan([
      slot('lunch', day, 'LUNCH', [dish('d1', recipeId: 'r1')]),
    ]);

    expect(selectUpcomingMeal(p, DateTime(2026, 11, 28, 12, 30))?.slot.id,
        'lunch');
    expect(selectUpcomingMeal(p, DateTime(2026, 11, 28, 13, 30)), isNull);
  });

  test('bỏ slot không có món đã gán recipe, chỉ giữ dish có recipe', () {
    final p = plan([
      slot('lunch', day, 'LUNCH', [dish('empty')]),
      slot('dinner', day, 'DINNER', [
        dish('d2', recipeId: 'r2', sortOrder: 1),
        dish('empty2'),
        dish('d1', recipeId: 'r1', sortOrder: 0),
      ]),
    ]);

    final meal = selectUpcomingMeal(p, DateTime(2026, 11, 28, 10));

    expect(meal?.slot.id, 'dinner');
    expect(meal?.dishes.map((d) => d.id), ['d1', 'd2']);
  });

  test('hết slot → null', () {
    final p = plan([
      slot('dinner', day, 'DINNER', [dish('d1', recipeId: 'r1')]),
    ]);

    expect(selectUpcomingMeal(p, DateTime(2026, 11, 29, 8)), isNull);
  });
}
