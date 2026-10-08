import '../../cooking/domain/meal_log_entry.dart';
import 'daily_nutrition_point.dart';

/// Tim hàm thuần chứa logic gộp log theo ngày — trái tim của toàn bộ tab
/// Calo/Macro (nutrition-trend-history.md §5.3).
class NutritionAggregator {
  const NutritionAggregator._();

  /// Gộp [logs] theo NGÀY LỊCH Asia/Ho_Chi_Minh trong khung [from, to] (cả 2
  /// ngày, inclusive). Trả về ĐÚNG `(to.difference(from).inDays + 1)` phần tử,
  /// thứ tự tăng dần theo ngày — giữ trục X đều đặn cho chart kể cả những ngày
  /// không có log nào.
  ///
  /// Chỉ cộng dồn entry thoả `MealLogEntry.countsTowardDailyTotal` (mirror Guard
  /// #4 gốc của `meal-log-nutrition.md`) — KHÔNG viết lại predicate ở đây.
  static List<DailyNutritionPoint> aggregateByDay({
    required List<MealLogEntry> logs,
    required DateTime from,
    required DateTime to,
  }) {
    final buckets = <DateTime, _DayAccumulator>{};
    for (final log in logs) {
      if (!log.countsTowardDailyTotal) continue;
      final day = _toVnCalendarDay(log.loggedAt);
      buckets.putIfAbsent(day, _DayAccumulator.new).add(log);
    }
    final result = <DailyNutritionPoint>[];
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      final acc = buckets[d];
      result.add(acc == null
          ? DailyNutritionPoint(date: d)
          : DailyNutritionPoint(
              date: d,
              caloriesKcal: acc.calories,
              proteinG: acc.protein,
              carbsG: acc.carbs,
              fatG: acc.fat,
            ));
    }
    return result;
  }

  /// `MealLogEntry.loggedAt` là UTC — cộng offset CỐ ĐỊNH +7h rồi lấy ngày lịch,
  /// KHÔNG dùng `.toLocal()` (phụ thuộc timezone thiết bị — sai nếu người dùng
  /// ở múi giờ khác VN). Cùng convention `Asia/Ho_Chi_Minh` toàn dự án.
  static DateTime _toVnCalendarDay(DateTime utc) {
    final vn = utc.toUtc().add(const Duration(hours: 7));
    return DateTime(vn.year, vn.month, vn.day);
  }
}

class _DayAccumulator {
  double calories = 0, protein = 0, carbs = 0, fat = 0;
  void add(MealLogEntry log) {
    // non-null đảm bảo bởi guard countsTowardDailyTotal (caloriesKcal == null
    // thì countsTowardDailyTotal == false).
    calories += log.caloriesKcal!;
    protein += log.nutrition?.proteinG ?? 0;
    carbs += log.nutrition?.carbsG ?? 0;
    fat += log.nutrition?.fatG ?? 0;
    // fiber KHÔNG được cộng — v1 không visualize fiber.
  }
}