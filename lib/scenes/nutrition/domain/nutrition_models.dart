import '../../recipe/domain/recipe.dart';
import 'compliance.dart';

/// 1 món đã xác nhận trong 1 bữa (nutrition-summary-widget.md §5).
class MealNutritionLine {
  const MealNutritionLine({
    required this.mealTime,
    required this.recipeId,
    required this.recipeName,
    required this.nutrition,
  });

  final String mealTime;
  final String recipeId;
  final String recipeName;

  /// `null` hoặc `calories == null` = món chưa có dữ liệu dinh dưỡng —
  /// KHÔNG đoán số (Guard 2).
  final RecipeNutrition? nutrition;

  bool get hasData => nutrition?.calories != null;
  double? get calories => nutrition?.calories;
}

/// Tổng dinh dưỡng của 1 ngày — chỉ cộng các món CÓ dữ liệu.
class DailyNutrition {
  const DailyNutrition({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.lines,
  });

  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<MealNutritionLine> lines;

  int get plannedDishCount => lines.length;
  int get missingNutritionCount => lines.where((l) => !l.hasData).length;
  bool get hasPlannedMeals => lines.isNotEmpty;
  bool get hasNutritionData => plannedDishCount > missingNutritionCount;
}

class MacroRatios {
  const MacroRatios({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Phần trăm 0–100 theo NĂNG LƯỢNG (đạm/tinh bột 4 kcal/g, béo 9 kcal/g).
  final double protein;
  final double carbs;
  final double fat;
}

/// Tổng hợp dinh dưỡng 1 tuần đã ăn của 1 người (Thứ Hai → Chủ Nhật).
class NutritionWeekSummary {
  const NutritionWeekSummary({
    required this.weekStart,
    required this.days,
    required this.targetDailyCalories,
    required this.complianceScore,
    required this.level,
  });

  final DateTime weekStart;

  /// Luôn đúng 7 phần tử.
  final List<DailyNutrition> days;
  final int? targetDailyCalories;

  /// `null` khi không có target hoặc không có ngày nào có dữ liệu (D21).
  final int? complianceScore;
  final ComplianceLevel level;

  double get totalCalories => _sum((d) => d.calories);
  double get totalProtein => _sum((d) => d.protein);
  double get totalCarbs => _sum((d) => d.carbs);
  double get totalFat => _sum((d) => d.fat);

  int get daysWithData => days.where((d) => d.hasNutritionData).length;
  int get missingNutritionCount =>
      days.fold(0, (sum, d) => sum + d.missingNutritionCount);
  int get plannedDishCount =>
      days.fold(0, (sum, d) => sum + d.plannedDishCount);

  /// Tổng / số ngày có dữ liệu (D18); `null` khi chưa có ngày nào.
  double? get avgDailyCalories =>
      daysWithData == 0 ? null : totalCalories / daysWithData;

  /// Mục tiêu cho các ngày có dữ liệu (§9.2) — `null` khi chưa có target
  /// hoặc chưa có ngày nào có dữ liệu.
  int? get targetForDaysWithData {
    final target = targetDailyCalories;
    if (target == null || target <= 0 || daysWithData == 0) return null;
    return target * daysWithData;
  }

  /// Tỷ lệ năng lượng từ macro (thay D19 theo gram — gram làm béo trông nhỏ
  /// dù 1 g béo gấp ~2,25 lần năng lượng); `null` khi chưa có macro.
  MacroRatios? get macroRatios {
    final p = totalProtein * 4, c = totalCarbs * 4, f = totalFat * 9;
    final total = p + c + f;
    if (total <= 0) return null;
    return MacroRatios(
      protein: p / total * 100,
      carbs: c / total * 100,
      fat: f / total * 100,
    );
  }

  double _sum(double Function(DailyNutrition) pick) =>
      days.fold(0, (sum, d) => sum + pick(d));
}
