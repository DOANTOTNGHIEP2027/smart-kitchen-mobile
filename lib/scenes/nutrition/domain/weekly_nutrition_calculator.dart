import '../../cooking/domain/meal_log_entry.dart';
import '../../cooking/domain/meal_type.dart';
import '../../recipe/domain/recipe.dart';
import 'compliance.dart';
import 'nutrition_models.dart';

/// Ngày lịch (y/m/d) dạng UTC để so sánh — không phụ thuộc giờ mùa hè.
DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

String _mealTime(MealType type) => switch (type) {
      MealType.breakfast => 'BREAKFAST',
      MealType.lunch => 'LUNCH',
      MealType.dinner => 'DINNER',
      MealType.snack => 'SNACK',
    };

/// Tổng hợp dinh dưỡng 1 tuần (Thứ Hai → Chủ Nhật) từ NHẬT KÝ ĂN của 1 người.
/// Hàm thuần — không I/O.
///
/// - Chỉ log của [memberId] (phòng thủ nếu nguồn trả cả hộ).
/// - Ngày theo `loggedAt` giờ máy — cùng cách màn nhật ký xếp "hôm nay".
/// - Log chưa có calo hoặc đang chờ xác nhận: không cộng, đếm là "chưa có
///   dữ liệu" (cùng rule `countsTowardDailyTotal` của BE).
/// - Log đang gửi/lỗi (chưa lưu ở BE) bị bỏ qua.
NutritionWeekSummary computeWeeklyNutritionFromLogs({
  required DateTime weekStart,
  required Iterable<MealLogEntry> logs,
  required String memberId,
  required int? targetDailyCalories,
}) {
  final start = _day(weekStart);
  final mine = logs
      .where((e) => e.memberId == memberId && e.status == MealEntryStatus.saved)
      .toList()
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  final days = List<DailyNutrition>.generate(7, (i) {
    final date = start.add(Duration(days: i));
    final lines = <MealNutritionLine>[
      for (final entry in mine)
        if (_day(entry.loggedAt.toLocal()) == date)
          MealNutritionLine(
            mealTime: _mealTime(entry.mealGroup),
            recipeId: entry.id,
            recipeName: stripMealTypePrefix(entry.description ?? ''),
            nutrition: entry.countsTowardDailyTotal
                ? RecipeNutrition(
                    calories: entry.caloriesKcal,
                    proteinG: entry.nutrition?.proteinG,
                    carbsG: entry.nutrition?.carbsG,
                    fatG: entry.nutrition?.fatG,
                  )
                : null,
          ),
    ];
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

/// Thứ Hai của tuần chứa [now] (giờ máy), 00:00.
DateTime mondayOf(DateTime now) {
  final d = DateTime(now.year, now.month, now.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}
