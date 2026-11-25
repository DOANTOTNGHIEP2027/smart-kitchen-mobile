import '../../mealplan/domain/meal_plan_slot.dart';
import '../../recipe/domain/recipe.dart';
import 'compliance.dart';
import 'nutrition_models.dart';

const List<String> _mealOrder = <String>['BREAKFAST', 'LUNCH', 'DINNER'];

/// Ngày lịch (y/m/d) dạng UTC — so sánh không phụ thuộc múi giờ/giờ mùa hè
/// của máy; đọc thẳng field của DateTime mapper trả về, không `toLocal()`.
DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Recipe đã xác nhận trong tuần — dùng để biết cần fetch nutrition nào.
Set<String> confirmedRecipeIds(Iterable<MealPlanSlot> slots, DateTime weekStart) =>
    <String>{
      for (final slot in _slotsInWeek(slots, weekStart))
        for (final dish in slot.dishes)
          if (_isCounted(dish)) dish.recipe!.recipeId,
    };

bool _isCounted(MealPlanDish dish) =>
    dish.status == DishUiStatus.confirmed && dish.recipe != null;

Iterable<MealPlanSlot> _slotsInWeek(
    Iterable<MealPlanSlot> slots, DateTime weekStart) {
  final start = _day(weekStart);
  final end = start.add(const Duration(days: 7));
  return slots.where((s) {
    final d = _day(s.slotDate);
    return !d.isBefore(start) && d.isBefore(end);
  });
}

int _mealRank(String mealTime) {
  final i = _mealOrder.indexOf(mealTime);
  return i < 0 ? _mealOrder.length : i;
}

/// Tổng hợp dinh dưỡng 1 tuần từ slots kế hoạch (nutrition-summary-widget.md
/// §6). Hàm thuần — không I/O.
///
/// - Chỉ tính món CONFIRMED có recipe (Guard 1).
/// - Món không có nutrition: không cộng, đếm vào missing (Guard 2).
/// - Không giả định 3 bữa/ngày — duyệt mọi slot của ngày (#101).
/// - Mỗi món = 1 khẩu phần recipe (D17).
NutritionWeekSummary computeWeeklyNutrition({
  required DateTime weekStart,
  required Iterable<MealPlanSlot> slots,
  required Map<String, RecipeNutrition?> nutritionByRecipe,
  required int? targetDailyCalories,
}) {
  final start = _day(weekStart);
  final weekSlots = _slotsInWeek(slots, start).toList()
    ..sort((a, b) {
      final byRank = _mealRank(a.mealTime).compareTo(_mealRank(b.mealTime));
      return byRank != 0 ? byRank : a.mealTime.compareTo(b.mealTime);
    });

  final days = List<DailyNutrition>.generate(7, (i) {
    final date = start.add(Duration(days: i));
    final lines = <MealNutritionLine>[];
    for (final slot in weekSlots.where((s) => _day(s.slotDate) == date)) {
      final dishes = slot.dishes.where(_isCounted).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final dish in dishes) {
        final recipe = dish.recipe!;
        lines.add(MealNutritionLine(
          mealTime: slot.mealTime,
          recipeId: recipe.recipeId,
          recipeName: recipe.recipeName,
          nutrition: nutritionByRecipe[recipe.recipeId],
        ));
      }
    }
    var calories = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
    for (final line in lines.where((l) => l.hasData)) {
      final n = line.nutrition!;
      calories += n.calories ?? 0;
      protein += n.proteinG ?? 0;
      carbs += n.carbsG ?? 0;
      fat += n.fatG ?? 0;
    }
    return DailyNutrition(
      date: date,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      lines: List.unmodifiable(lines),
    );
  });

  final score = computeComplianceScore(
    days: days.map((d) => (
          hasData: d.hasNutritionData,
          calories: d.calories,
          hasMissingData: d.missingNutritionCount > 0,
        )),
    targetDailyCalories: targetDailyCalories,
  );
  return NutritionWeekSummary(
    weekStart: start,
    days: List.unmodifiable(days),
    targetDailyCalories: targetDailyCalories,
    complianceScore: score,
    level: levelForScore(score),
  );
}
