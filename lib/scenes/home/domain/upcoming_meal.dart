import '../../mealplan/domain/meal_plan_slot.dart';

/// Bữa sắp tới gần nhất hiển thị ở Trang chủ: 1 slot + các món đã gán recipe.
class UpcomingMeal {
  const UpcomingMeal({
    required this.planId,
    required this.slot,
    required this.dishes,
  });

  final String planId;
  final MealPlanSlot slot;

  /// Chỉ các dish đã có `recipe` — dish trống không nấu được.
  final List<MealPlanDish> dishes;

  /// Cả bữa đã nấu xong — Trang chủ hiện nhãn "Đã nấu xong", không mở nấu.
  bool get allCooked => slot.isAllCooked;
}

/// Giờ bắt đầu mặc định của từng `mealTime` — chỉ dùng khi server chưa trả
/// `scheduledTime` của slot.
/// Slot được coi là "đã qua" khi hiện tại vượt giờ này [graceHours] giờ.
const Map<String, int> _mealStartHour = <String, int>{
  'BREAKFAST': 7,
  'LUNCH': 11,
  'SNACK': 15,
  'DINNER': 18,
};

const int _graceHours = 2;

DateTime _slotStart(MealPlanSlot slot) {
  final d = slot.slotDate;
  final minutes = slot.scheduledMinutes;
  if (minutes != null) {
    return DateTime(d.year, d.month, d.day, minutes ~/ 60, minutes % 60);
  }
  return DateTime(d.year, d.month, d.day, _mealStartHour[slot.mealTime] ?? 12);
}

/// Chọn slot gần nhất chưa qua (theo [now]) có ít nhất 1 món đã gán recipe.
/// Bữa đã nấu xong hết vẫn được chọn (hiện nhãn "Đã nấu xong") tới giờ bắt
/// đầu của nó; qua giờ thì nhường cho bữa kế chưa nấu.
/// Trả `null` khi không còn slot nào phù hợp trong [plan].
UpcomingMeal? selectUpcomingMeal(MealPlanDto plan, DateTime now) {
  UpcomingMeal? best;
  DateTime? bestStart;
  for (final slot in plan.slots) {
    final start = _slotStart(slot);
    if (start.add(const Duration(hours: _graceHours)).isBefore(now)) continue;
    if (slot.isAllCooked && !now.isBefore(start)) continue;
    final dishes = slot.dishes.where((d) => d.recipe != null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (dishes.isEmpty) continue;
    if (bestStart == null || start.isBefore(bestStart)) {
      bestStart = start;
      best = UpcomingMeal(planId: plan.id, slot: slot, dishes: dishes);
    }
  }
  return best;
}
