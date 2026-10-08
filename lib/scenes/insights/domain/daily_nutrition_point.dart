/// Điểm dinh dưỡng theo NGÀY LỊCH — client-only, KHÔNG có DTO BE tương ứng
/// (nutrition-trend-history.md §5.1).
///
/// 4 field số NULL cùng lúc hoặc CÓ giá trị cùng lúc (bất biến kế thừa
/// `calories_kcal IS NULL ⟺ requires_confirmation TRUE` của #77 + guard "đủ điều
/// kiện" tại `NutritionAggregator`).
class DailyNutritionPoint {
  const DailyNutritionPoint({
    required this.date,
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  /// Ngày lịch Asia/Ho_Chi_Minh (00:00, không giờ) — KHÔNG phải ngày theo
  /// timezone thiết bị.
  final DateTime date;
  final double? caloriesKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  bool get hasData => caloriesKcal != null;
}