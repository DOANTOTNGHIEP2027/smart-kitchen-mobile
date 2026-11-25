import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/compliance.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/weekly_nutrition_calculator.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';

final DateTime monday = DateTime(2026, 11, 16);

MealPlanSlot slot(
  int dayOffset,
  String mealTime,
  List<(String recipeId, DishUiStatus status)> dishes,
) =>
    MealPlanSlot(
      id: 's-$dayOffset-$mealTime',
      slotDate: monday.add(Duration(days: dayOffset)),
      mealTime: mealTime,
      dishes: <MealPlanDish>[
        for (var i = 0; i < dishes.length; i++)
          MealPlanDish(
            id: 'd-$dayOffset-$mealTime-$i',
            slotId: 's-$dayOffset-$mealTime',
            sortOrder: i,
            status: dishes[i].$2,
            recipe: AssignedRecipeSummary(
              recipeId: dishes[i].$1,
              recipeName: 'Món ${dishes[i].$1}',
              source: 'MANUAL',
            ),
          ),
      ],
    );

List<({bool hasData, double calories, bool hasMissingData})> days(List<double?> kcal,
        {bool missing = false}) =>
    <({bool hasData, double calories, bool hasMissingData})>[
      for (final k in kcal) (hasData: k != null, calories: k ?? 0, hasMissingData: missing),
    ];

void main() {
  group('computeComplianceScore (AC issue #64)', () {
    test('7 ngày đều đạt target → 100', () {
      expect(
        computeComplianceScore(days: days(List.filled(7, 2000)), targetDailyCalories: 2000),
        100,
      );
    });

    test('1 ngày vượt 15% → 90', () {
      expect(
        computeComplianceScore(
            days: days(<double>[2300, 2000, 2000, 2000, 2000, 2000, 2000]),
            targetDailyCalories: 2000),
        90,
      );
    });

    test('biên 110% / 80% không trừ; vượt chặt thì trừ', () {
      expect(computeComplianceScore(days: days(<double?>[2200, 1600]), targetDailyCalories: 2000), 100);
      expect(computeComplianceScore(days: days(<double?>[2201]), targetDailyCalories: 2000), 90);
      expect(computeComplianceScore(days: days(<double?>[1599]), targetDailyCalories: 2000), 95);
    });

    test('ngày không có dữ liệu không bị trừ; kẹp tại 0', () {
      expect(computeComplianceScore(days: days(<double?>[null, null, 1000]), targetDailyCalories: 2000), 95);
      expect(
        computeComplianceScore(
            days: days(List<double>.filled(11, 5000)), targetDailyCalories: 2000),
        0,
      );
    });

    test('ngày có món thiếu dữ liệu: không trừ "thiếu", vẫn trừ "vượt"', () {
      expect(computeComplianceScore(days: days(<double?>[1000], missing: true), targetDailyCalories: 2000), 100);
      expect(computeComplianceScore(days: days(<double?>[2500], missing: true), targetDailyCalories: 2000), 90);
    });

    test('không có target / target ≤ 0 / không ngày nào có dữ liệu → null', () {
      expect(computeComplianceScore(days: days(<double>[2000]), targetDailyCalories: null), isNull);
      expect(computeComplianceScore(days: days(<double>[2000]), targetDailyCalories: 0), isNull);
      expect(computeComplianceScore(days: days(<double?>[null, null]), targetDailyCalories: 2000), isNull);
    });
  });

  test('levelForScore ở các ngưỡng', () {
    expect(levelForScore(100), ComplianceLevel.excellent);
    expect(levelForScore(90), ComplianceLevel.excellent);
    expect(levelForScore(89), ComplianceLevel.good);
    expect(levelForScore(70), ComplianceLevel.good);
    expect(levelForScore(69), ComplianceLevel.needsImprovement);
    expect(levelForScore(50), ComplianceLevel.needsImprovement);
    expect(levelForScore(49), ComplianceLevel.poor);
    expect(levelForScore(0), ComplianceLevel.poor);
    expect(levelForScore(null), ComplianceLevel.unknown);
  });

  group('computeWeeklyNutrition', () {
    const full = RecipeNutrition(calories: 500, proteinG: 30, carbsG: 60, fatG: 15);

    test('luôn 7 ngày; chỉ tính món CONFIRMED; nhiều món/slot cộng dồn', () {
      final summary = computeWeeklyNutrition(
        weekStart: monday,
        slots: <MealPlanSlot>[
          slot(0, 'LUNCH', <(String, DishUiStatus)>[
            ('r1', DishUiStatus.confirmed),
            ('r2', DishUiStatus.confirmed),
            ('r3', DishUiStatus.suggested),
          ]),
        ],
        nutritionByRecipe: <String, RecipeNutrition?>{'r1': full, 'r2': full, 'r3': full},
        targetDailyCalories: 2000,
      );
      expect(summary.days, hasLength(7));
      expect(summary.days.first.calories, 1000);
      expect(summary.days.first.plannedDishCount, 2);
      expect(summary.days[1].hasPlannedMeals, isFalse);
      expect(summary.totalProtein, 60);
    });

    test('món thiếu dữ liệu không cộng, được đếm; chỉ có calories thì macro = 0', () {
      final summary = computeWeeklyNutrition(
        weekStart: monday,
        slots: <MealPlanSlot>[
          slot(0, 'DINNER', <(String, DishUiStatus)>[('missing', DishUiStatus.confirmed), ('kcalOnly', DishUiStatus.confirmed)]),
          slot(1, 'DINNER', <(String, DishUiStatus)>[('missing', DishUiStatus.confirmed)]),
        ],
        nutritionByRecipe: <String, RecipeNutrition?>{
          'missing': null,
          'kcalOnly': const RecipeNutrition(calories: 300),
        },
        targetDailyCalories: 2000,
      );
      expect(summary.days[0].calories, 300);
      expect(summary.days[0].missingNutritionCount, 1);
      expect(summary.days[0].hasNutritionData, isTrue);
      expect(summary.days[1].hasNutritionData, isFalse, reason: 'chỉ có món thiếu dữ liệu');
      expect(summary.missingNutritionCount, 2);
      expect(summary.macroRatios, isNull);
      expect(summary.daysWithData, 1);
      expect(summary.avgDailyCalories, 300);
    });

    test('slot ngoài tuần bị bỏ; bữa không chuẩn vẫn được tính, xếp sau', () {
      final summary = computeWeeklyNutrition(
        weekStart: monday,
        slots: <MealPlanSlot>[
          slot(-1, 'LUNCH', <(String, DishUiStatus)>[('r1', DishUiStatus.confirmed)]),
          slot(7, 'LUNCH', <(String, DishUiStatus)>[('r1', DishUiStatus.confirmed)]),
          slot(2, 'SNACK', <(String, DishUiStatus)>[('r1', DishUiStatus.confirmed)]),
          slot(2, 'BREAKFAST', <(String, DishUiStatus)>[('r2', DishUiStatus.confirmed)]),
        ],
        nutritionByRecipe: <String, RecipeNutrition?>{'r1': full, 'r2': full},
        targetDailyCalories: 2000,
      );
      expect(summary.plannedDishCount, 2);
      expect(summary.days[2].lines.map((l) => l.mealTime), <String>['BREAKFAST', 'SNACK']);
      expect(confirmedRecipeIds(<MealPlanSlot>[
        slot(-1, 'LUNCH', <(String, DishUiStatus)>[('outside', DishUiStatus.confirmed)]),
        slot(0, 'LUNCH', <(String, DishUiStatus)>[('in', DishUiStatus.confirmed), ('sug', DishUiStatus.suggested)]),
      ], monday), <String>{'in'});
    });

    test('macroRatios theo gram — ví dụ AC 100/200/50 → 28.6% / 57.1%', () {
      final summary = computeWeeklyNutrition(
        weekStart: monday,
        slots: <MealPlanSlot>[slot(0, 'LUNCH', <(String, DishUiStatus)>[('m', DishUiStatus.confirmed)])],
        nutritionByRecipe: <String, RecipeNutrition?>{
          'm': const RecipeNutrition(calories: 1650, proteinG: 100, carbsG: 200, fatG: 50),
        },
        targetDailyCalories: 2000,
      );
      final ratios = summary.macroRatios!;
      expect(ratios.protein, closeTo(28.6, 0.05));
      expect(ratios.carbs, closeTo(57.1, 0.05));
      expect(ratios.fat, closeTo(14.3, 0.05));
    });

    test('score + level gắn vào summary; tuần trống → unknown', () {
      final empty = computeWeeklyNutrition(
        weekStart: monday,
        slots: const <MealPlanSlot>[],
        nutritionByRecipe: const <String, RecipeNutrition?>{},
        targetDailyCalories: 2000,
      );
      expect(empty.complianceScore, isNull);
      expect(empty.level, ComplianceLevel.unknown);
      expect(empty.avgDailyCalories, isNull);
      expect(empty.targetForDaysWithData, isNull);
    });
  });

  test('slotDate dạng UTC nửa đêm (như mapper) vẫn vào đúng ngày', () {
    final utcMonday = DateTime.utc(2026, 11, 16);
    final summary = computeWeeklyNutrition(
      weekStart: utcMonday,
      slots: <MealPlanSlot>[
        MealPlanSlot(
          id: 's',
          slotDate: DateTime.utc(2026, 11, 22),
          mealTime: 'DINNER',
          dishes: const <MealPlanDish>[
            MealPlanDish(
              id: 'd', slotId: 's', sortOrder: 0, status: DishUiStatus.confirmed,
              recipe: AssignedRecipeSummary(recipeId: 'r', recipeName: 'R', source: 'AI'),
            ),
          ],
        ),
      ],
      nutritionByRecipe: const <String, RecipeNutrition?>{'r': RecipeNutrition(calories: 400)},
      targetDailyCalories: 2000,
    );
    expect(summary.days[6].calories, 400, reason: 'Chủ Nhật');
    expect(summary.targetForDaysWithData, 2000);
  });

  test('dayTargetStatus', () {
    expect(dayTargetStatus(hasData: false, calories: 0, targetDailyCalories: 2000), DayTargetStatus.noData);
    expect(dayTargetStatus(hasData: true, calories: 2300, targetDailyCalories: 2000), DayTargetStatus.over);
    expect(dayTargetStatus(hasData: true, calories: 1500, targetDailyCalories: 2000), DayTargetStatus.under);
    expect(dayTargetStatus(hasData: true, calories: 2000, targetDailyCalories: null), DayTargetStatus.onTarget);
  });
}
