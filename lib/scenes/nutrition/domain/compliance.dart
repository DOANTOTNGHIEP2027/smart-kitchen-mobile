/// Mức tuân thủ kế hoạch ăn (nutrition-summary-widget.md §6.1, §9.1).
enum ComplianceLevel { excellent, good, needsImprovement, poor, unknown }

/// Ngưỡng ngày bị coi là vượt / thiếu so với target (lớn hơn chặt — Guard 5).
const double complianceOverRatio = 1.10;
const double complianceUnderRatio = 0.80;

enum DayTargetStatus { noData, onTarget, over, under }

/// Trạng thái 1 ngày so với target. Không có target → [DayTargetStatus.onTarget]
/// khi có dữ liệu (không đánh giá được thì không tô đỏ).
DayTargetStatus dayTargetStatus({
  required bool hasData,
  required double calories,
  required int? targetDailyCalories,
  bool hasMissingData = false,
}) {
  if (!hasData) return DayTargetStatus.noData;
  final target = targetDailyCalories;
  if (target == null || target <= 0) return DayTargetStatus.onTarget;
  final ratio = calories / target;
  if (ratio > complianceOverRatio) return DayTargetStatus.over;
  // Có món thiếu dữ liệu thì tổng đang bị đếm thấp — không kết luận "thiếu"
  // (review v3 MEDIUM-4); "vượt" vẫn chắc chắn đúng.
  if (ratio < complianceUnderRatio && !hasMissingData) {
    return DayTargetStatus.under;
  }
  return DayTargetStatus.onTarget;
}

/// Điểm tuân thủ 0–100 (D20): bắt đầu 100, −10 mỗi ngày vượt > 10%, −5 mỗi
/// ngày thiếu > 20%, chỉ xét ngày có dữ liệu. Khoản −20 dị ứng chưa áp dụng
/// (D16 — chưa có dữ liệu dị ứng của món đã gán).
///
/// Trả `null` khi không có target hoặc không có ngày nào có dữ liệu (D21).
int? computeComplianceScore({
  required Iterable<({bool hasData, double calories, bool hasMissingData})> days,
  required int? targetDailyCalories,
}) {
  final target = targetDailyCalories;
  if (target == null || target <= 0) return null;
  var score = 100;
  var evaluated = 0;
  for (final day in days) {
    final status = dayTargetStatus(
      hasData: day.hasData,
      calories: day.calories,
      targetDailyCalories: target,
      hasMissingData: day.hasMissingData,
    );
    if (status == DayTargetStatus.noData) continue;
    evaluated++;
    if (status == DayTargetStatus.over) score -= 10;
    if (status == DayTargetStatus.under) score -= 5;
  }
  if (evaluated == 0) return null;
  return score.clamp(0, 100);
}

ComplianceLevel levelForScore(int? score) {
  if (score == null) return ComplianceLevel.unknown;
  if (score >= 90) return ComplianceLevel.excellent;
  if (score >= 70) return ComplianceLevel.good;
  if (score >= 50) return ComplianceLevel.needsImprovement;
  return ComplianceLevel.poor;
}
