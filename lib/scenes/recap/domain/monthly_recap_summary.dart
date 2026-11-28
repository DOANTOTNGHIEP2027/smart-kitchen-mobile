import '../../../domain/shared/budget_period.dart';
import 'waste_spend.dart';
import 'weekly_recap_summary.dart';

/// 1 tuần trong tổng kết tháng của 1 thành viên — cùng shape insight tuần,
/// thêm [weekStart] (Thứ Hai).
class MemberWeekInsight {
  const MemberWeekInsight({required this.weekStart, required this.insight});

  final DateTime weekStart;

  /// Tái dùng model tuần để vẽ bằng đúng `InsightCard` của Tổng kết tuần.
  final MemberWeeklyInsight insight;
}

/// Insight tháng của 1 thành viên: phần tổng hợp cả tháng + danh sách tuần.
class MonthlyMemberInsight {
  const MonthlyMemberInsight({required this.summary, required this.weeks});

  /// Số liệu cả tháng (calo trung bình, % tuân thủ, badge, nhận xét AI).
  final MemberWeeklyInsight summary;

  final List<MemberWeekInsight> weeks;

  String get memberId => summary.memberId;
}

/// Tổng kết tháng của 1 hộ (`GET /api/v1/insights/monthly`) — FE không tính
/// lại con số nào, chỉ hiển thị.
class MonthlyRecapSummary {
  const MonthlyRecapSummary({
    required this.householdId,
    required this.month,
    required this.mealsLoggedCount,
    required this.avgCaloriesKcal,
    required this.adherencePercent,
    required this.bestStreakWeeks,
    required this.memberInsights,
    required this.householdSummary,
    required this.suggestedFocus,
    required this.isStale,
    required this.computedAt,
    required this.hasPrevious,
    this.wasteItemCount = 0,
    this.wasteCauseBreakdown = const WasteCauseBreakdown(),
    this.spendTotal,
    this.spendItemCount = 0,
    this.shoppingCompletedItemCount = 0,
    this.budgetAmount,
    this.budgetPeriod = BudgetPeriod.unknown,
    this.budgetMonthlyAmount,
    this.spendByCategory,
    this.spendTrend,
  });

  final String householdId;

  /// Ngày 1 của tháng (từ chuỗi `yyyy-MM`).
  final DateTime month;

  final int mealsLoggedCount;

  /// Trung bình theo (thành viên, ngày có ghi nhật ký) — KHÁC số "mỗi bữa"
  /// của tuần. `null` khi tháng chưa có nhật ký.
  final double? avgCaloriesKcal;

  final double? adherencePercent;

  /// Chuỗi tuần đạt mục tiêu dài nhất trong tháng (đơn vị TUẦN).
  final int bestStreakWeeks;

  /// `[]` khi isStale=true.
  final List<MonthlyMemberInsight> memberInsights;
  final String? householdSummary;
  final String? suggestedFocus;
  final bool isStale;
  final DateTime computedAt;

  /// `false` ⟹ không có tháng trước để xem — tắt nút "tháng trước".
  final bool hasPrevious;

  final int wasteItemCount;
  final WasteCauseBreakdown wasteCauseBreakdown;

  /// `null` = không món nào được nhập giá (khác `0`).
  final double? spendTotal;
  final int spendItemCount;
  final int shoppingCompletedItemCount;

  /// Ngân sách gốc chủ hộ đặt; `null` = chưa đặt.
  final double? budgetAmount;
  final BudgetPeriod budgetPeriod;

  /// Ngân sách BE đã QUY ĐỔI THÁNG — số dùng để so với [spendTotal].
  final double? budgetMonthlyAmount;

  /// `null` = BE đã gate (gói FREE); `{}` = rỗng thật.
  final Map<String, double>? spendByCategory;

  /// `null` = BE đã gate.
  final List<SpendTrendPoint>? spendTrend;

  /// Bản "khối chi tiêu" dạng [WeeklyRecapSummary] để tái dùng nguyên các
  /// widget `SpendSection`/`SpendDetailSection` của Tổng kết tuần. Ngân sách
  /// so sánh là ngân sách THÁNG ([budgetMonthlyAmount]) đặt vào ô ngân sách
  /// của widget; widget chọn câu chữ theo `RecapPeriod.month`.
  WeeklyRecapSummary toSpendSummary() => WeeklyRecapSummary(
        householdId: householdId,
        weekStart: month,
        mealsLoggedCount: mealsLoggedCount,
        avgCaloriesKcal: avgCaloriesKcal,
        adherencePercent: adherencePercent,
        memberInsights: const <MemberWeeklyInsight>[],
        householdSummary: householdSummary,
        suggestedFocus: suggestedFocus,
        isStale: isStale,
        computedAt: computedAt,
        wasteItemCount: wasteItemCount,
        wasteCauseBreakdown: wasteCauseBreakdown,
        spendTotal: spendTotal,
        spendItemCount: spendItemCount,
        shoppingCompletedItemCount: shoppingCompletedItemCount,
        budgetAmount: budgetAmount,
        budgetPeriod: budgetPeriod,
        budgetWeeklyAmount: budgetMonthlyAmount,
        spendByCategory: spendByCategory,
        spendTrend: spendTrend,
      );
}
