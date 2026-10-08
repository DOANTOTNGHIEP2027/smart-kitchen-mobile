import 'recap_badge.dart';

/// Insight cá nhân hoá theo từng thành viên đủ điều kiện AI tuần đó
/// (weekly-insight-chain.md #85 §2.3 — pass-through VERBATIM từ AI, BE không
/// tính lại).
class MemberWeeklyInsight {
  const MemberWeeklyInsight({
    required this.memberId,
    required this.calorieAvg,
    required this.calorieGoal,
    required this.compliancePct,
    required this.badge,
    required this.topNutrientGap,
    required this.highlight,
    required this.tip,
  });

  final String memberId;

  /// Calo trung bình/ngày (per-member).
  final double calorieAvg;

  /// Mục tiêu calo hợp lệ của member (điều kiện để member vào danh sách).
  final double calorieGoal;

  /// % tuân thủ calo cá nhân — CÓ THỂ > 100. KHÁC `adherencePercent`
  /// (household-level). Không chộn/gộp (Guard #1, #2).
  final double compliancePct;

  final RecapBadge badge;
  final String topNutrientGap;

  /// Quote cá nhân hoá do AI sinh — render nguyên văn, không dịch.
  final String highlight;

  /// Gợi ý hành động do AI sinh — render nguyên văn, không dịch.
  final String tip;

  /// Ratio dùng để vẽ vòng tròn — clamp [0,1], KHÔNG đổi giá trị hiển thị số
  /// (`compliancePct` gốc vẫn hiển thị nguyên, có thể >100%). `.toDouble()`
  /// bắt buộc: `num.clamp` trả về `num` (fix-log v1 finding #1).
  double get ringRatio => (compliancePct / 100).clamp(0, 1).toDouble();
}

/// Snapshot tuần/1 household, đọc nguyên trạng từ `weekly_insights` — không
/// tính toán gì tại request-time (weekly-recap-aggregation.yaml).
class WeeklyRecapSummary {
  const WeeklyRecapSummary({
    required this.householdId,
    required this.weekStart,
    required this.mealsLoggedCount,
    required this.avgCaloriesKcal,
    required this.adherencePercent,
    required this.memberInsights,
    required this.householdSummary,
    required this.suggestedFocus,
    required this.isStale,
    required this.computedAt,
  });

  final String householdId;

  /// Luôn là Monday (convention meal_plans.week_start).
  final DateTime weekStart;

  /// Luôn >= 0, không bao giờ null (DB DEFAULT 0).
  final int mealsLoggedCount;

  /// `null` khi 0 log tuần đó — không phải lỗi.
  final double? avgCaloriesKcal;

  /// Household-level. `null` CHỈ khi cực hiếm (cả #84 snapshot lẫn self-heal
  /// đều lỗi).
  final double? adherencePercent;

  /// `[]` khi isStale=true (bất biến cứng #83).
  final List<MemberWeeklyInsight> memberInsights;

  /// `null` khi isStale=true.
  final String? householdSummary;

  /// `null` khi isStale=true.
  final String? suggestedFocus;

  /// `true` = AI relay thất bại thật HOẶC 0 member đủ điều kiện — state HỢP LỆ,
  /// không phải lỗi.
  final bool isStale;

  final DateTime computedAt;
}