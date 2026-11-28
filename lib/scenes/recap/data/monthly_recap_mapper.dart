import '../../../domain/shared/budget_period.dart';
import '../domain/monthly_recap_summary.dart';
import '../domain/recap_badge.dart';
import '../domain/waste_spend.dart';
import '../domain/weekly_recap_summary.dart';

/// JSON → domain cho Tổng kết tháng. Mọi số đều ép `(x as num).toDouble()`
/// vì `jsonDecode` trả `int` cho số nguyên (cùng quy tắc `RecapMapper`).
class MonthlyRecapMapper {
  /// `yyyy-MM` → ngày 1 của tháng. Ném [FormatException] nếu sai định dạng.
  static DateTime parseMonth(String raw) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw);
    if (match == null) throw FormatException('month không hợp lệ: $raw');
    return DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  /// Ngày 1 của tháng → `yyyy-MM` (tham số query của BE).
  static String formatMonth(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';

  static MonthlyRecapSummary summaryFromJson(Map<String, dynamic> json) =>
      MonthlyRecapSummary(
        householdId: json['householdId'] as String,
        month: parseMonth(json['month'] as String),
        mealsLoggedCount: (json['mealsLoggedCount'] as num?)?.toInt() ?? 0,
        avgCaloriesKcal: (json['avgCaloriesKcal'] as num?)?.toDouble(),
        adherencePercent: (json['adherencePercent'] as num?)?.toDouble(),
        bestStreakWeeks: (json['bestStreakWeeks'] as num?)?.toInt() ?? 0,
        memberInsights:
            ((json['memberInsights'] as List<dynamic>?) ?? const <dynamic>[])
                .map((m) => _memberFromJson(m as Map<String, dynamic>))
                .toList(),
        householdSummary: json['householdSummary'] as String?,
        suggestedFocus: json['suggestedFocus'] as String?,
        isStale: json['isStale'] as bool? ?? false,
        computedAt: DateTime.parse(json['computedAt'] as String),
        hasPrevious: json['hasPrevious'] as bool? ?? false,
        wasteItemCount: (json['wasteItemCount'] as num?)?.toInt() ?? 0,
        wasteCauseBreakdown: WasteCauseBreakdown.fromJson(
          json['wasteCauseBreakdown'] as Map<String, dynamic>?,
        ),
        spendTotal: (json['spendTotal'] as num?)?.toDouble(),
        spendItemCount: (json['spendItemCount'] as num?)?.toInt() ?? 0,
        shoppingCompletedItemCount:
            (json['shoppingCompletedItemCount'] as num?)?.toInt() ?? 0,
        budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
        budgetPeriod: BudgetPeriod.fromApi(json['budgetPeriod'] as String?),
        budgetMonthlyAmount: (json['budgetMonthlyAmount'] as num?)?.toDouble(),
        // Phân biệt null (gói FREE bị gate) với {} (rỗng thật).
        spendByCategory: json['spendByCategory'] == null
            ? null
            : (json['spendByCategory'] as Map<String, dynamic>).map(
                (k, v) => MapEntry<String, double>(k, (v as num).toDouble()),
              ),
        spendTrend: json['spendTrend'] == null
            ? null
            : (json['spendTrend'] as List<dynamic>)
                .map((e) => SpendTrendPoint.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  static MonthlyMemberInsight _memberFromJson(Map<String, dynamic> json) {
    final memberId = json['memberId'] as String;
    return MonthlyMemberInsight(
      summary: _insightFromJson(memberId, json),
      weeks: ((json['weeks'] as List<dynamic>?) ?? const <dynamic>[]).map((w) {
        final week = w as Map<String, dynamic>;
        return MemberWeekInsight(
          weekStart: DateTime.parse(week['weekStart'] as String),
          insight: _insightFromJson(memberId, week),
        );
      }).toList(),
    );
  }

  static MemberWeeklyInsight _insightFromJson(
    String memberId,
    Map<String, dynamic> json,
  ) =>
      MemberWeeklyInsight(
        memberId: memberId,
        calorieAvg: (json['calorieAvg'] as num?)?.toDouble() ?? 0,
        calorieGoal: (json['calorieGoal'] as num?)?.toDouble() ?? 0,
        compliancePct: (json['compliancePct'] as num?)?.toDouble() ?? 0,
        badge: RecapBadgeParsing.fromApi(json['badge'] as String?),
        topNutrientGap: json['topNutrientGap'] as String? ?? '',
        highlight: json['highlight'] as String? ?? '',
        tip: json['tip'] as String? ?? '',
      );
}
