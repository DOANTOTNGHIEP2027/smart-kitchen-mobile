import '../../../domain/shared/budget_period.dart';
import '../domain/household_streak.dart';
import '../domain/waste_spend.dart';
import '../domain/recap_badge.dart';
import '../domain/weekly_recap_summary.dart';

/// JSON <-> domain, coercion số bắt buộc.
///
/// ⚠️ Contract `WeeklyRecapResponse` chuyển sang **camelCase** desde v1.1
/// (2026-09-04, `docs/contracts/naming-convention.md` thắng quy ước cục bộ) —
/// `householdId`, `weekStart`, `mealsLoggedCount`, `memberInsights`,
/// `compliancePct`, ... Các đoạn code mẫu snake_case trong tài liệu thiết kế
/// là bản ĐỜI CŨ, đã hết hiệu lực.
class RecapMapper {
  /// Coercion `(x as num).toDouble()`/`(x as num?)?.toDouble()` cho MỌI field
  /// NUMERIC — `jsonDecode()` parse số nguyên JSON thành `int`, `as double?`
  /// trên giá trị sai kiểu sẽ throw runtime (Guard #5, cùng lớp bug Fix
  /// MEDIUM-1 của nutrition-summary-widget.md).
  static WeeklyRecapSummary summaryFromJson(Map<String, dynamic> json) =>
      WeeklyRecapSummary(
        householdId: json['householdId'] as String,
        weekStart: DateTime.parse(json['weekStart'] as String),
        mealsLoggedCount: json['mealsLoggedCount'] as int,
        avgCaloriesKcal: (json['avgCaloriesKcal'] as num?)?.toDouble(),
        adherencePercent: (json['adherencePercent'] as num?)?.toDouble(),
        memberInsights: (json['memberInsights'] as List<dynamic>)
            .map((m) => _memberFromJson(m as Map<String, dynamic>))
            .toList(),
        householdSummary: json['householdSummary'] as String?,
        suggestedFocus: json['suggestedFocus'] as String?,
        isStale: json['isStale'] as bool,
        computedAt: DateTime.parse(json['computedAt'] as String),
        // #133 — `?? 0` cho INTEGER: payload cũ chưa có key vẫn rơi đúng
        // empty-state thay vì lỗi parse cả màn hình.
        wasteItemCount: (json['wasteItemCount'] as num?)?.toInt() ?? 0,
        wasteCauseBreakdown: WasteCauseBreakdown.fromJson(
            json['wasteCauseBreakdown'] as Map<String, dynamic>?),
        spendTotal: (json['spendTotal'] as num?)?.toDouble(),
        spendItemCount: (json['spendItemCount'] as num?)?.toInt() ?? 0,
        shoppingCompletedItemCount:
            (json['shoppingCompletedItemCount'] as num?)?.toInt() ?? 0,
        budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
        budgetPeriod: BudgetPeriod.fromApi(json['budgetPeriod'] as String?),
        budgetWeeklyAmount: (json['budgetWeeklyAmount'] as num?)?.toDouble(),
        // PHÂN BIỆT null (BE gate / key vắng) với {} (rỗng thật) — Guard #14.
        spendByCategory: json['spendByCategory'] == null
            ? null
            : (json['spendByCategory'] as Map<String, dynamic>).map(
                (k, v) => MapEntry<String, double>(k, (v as num).toDouble())),
        spendTrend: json['spendTrend'] == null
            ? null
            : (json['spendTrend'] as List<dynamic>)
                .map((e) => SpendTrendPoint.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  static MemberWeeklyInsight _memberFromJson(Map<String, dynamic> json) =>
      MemberWeeklyInsight(
        memberId: json['memberId'] as String,
        calorieAvg: (json['calorieAvg'] as num).toDouble(),
        calorieGoal: (json['calorieGoal'] as num).toDouble(),
        compliancePct: (json['compliancePct'] as num).toDouble(),
        badge: RecapBadgeParsing.fromApi(json['badge'] as String?),
        topNutrientGap: json['topNutrientGap'] as String,
        highlight: json['highlight'] as String,
        tip: json['tip'] as String,
      );

  static HouseholdStreak streakFromJson(Map<String, dynamic> json) =>
      HouseholdStreak(
        householdId: json['householdId'] as String,
        currentStreak: json['currentStreak'] as int,
        bestStreak: json['bestStreak'] as int,
        lastComputedWeekStart: json['lastComputedWeekStart'] != null
            ? DateTime.parse(json['lastComputedWeekStart'] as String)
            : null,
      );
}