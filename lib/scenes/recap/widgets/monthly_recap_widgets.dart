import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/monthly_recap_summary.dart';
import '../domain/weekly_recap_summary.dart';
import 'insight_card.dart';
import 'shareable_recap_card.dart';
import 'streak_counter_widget.dart';

/// Thanh chuyển tháng: ‹ tháng trước · Tháng MM/yyyy · tháng sau ›.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    super.key,
    required this.month,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  static const previousKey = Key('monthlyRecapPrevious');
  static const nextKey = Key('monthlyRecapNext');

  final DateTime month;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.md,
        AppDimens.sm,
        AppDimens.md,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              key: previousKey,
              tooltip: l10n.monthlyRecapPreviousMonth,
              color: AppColors.primary,
              disabledColor: AppColors.textDisabled,
              onPressed: canGoPrevious ? onPrevious : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                l10n.insightsMonthLabel(month.month, month.year),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              key: nextKey,
              tooltip: l10n.monthlyRecapNextMonth,
              color: AppColors.primary,
              disabledColor: AppColors.textDisabled,
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ chia sẻ của Tổng kết tháng — cùng khung với `ShareableRecapCard` của
/// tuần, tái dùng `RecapHeroSection`, `RecapStatCard`, `StreakCounterWidget`.
/// Chỉ nhận dữ liệu qua constructor, không đọc store.
class MonthlyRecapShareCard extends StatelessWidget {
  const MonthlyRecapShareCard({
    super.key,
    required this.summary,
    required this.ownInsight,
  });

  final MonthlyRecapSummary summary;
  final MemberWeeklyInsight? ownInsight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final avg = summary.avgCaloriesKcal;
    final adherence = summary.adherencePercent;
    return Container(
      margin: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.ambientShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RecapHeroSection(
              ownInsight: ownInsight,
              householdSummary: summary.householdSummary,
              fallbackText: l10n.monthlyRecapHeroFallback,
            ),
            const SizedBox(height: AppDimens.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: RecapStatCard(
                    icon: Icons.restaurant_rounded,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primaryContainer,
                    value: summary.mealsLoggedCount.toString(),
                    label: l10n.recapMealsLogged(summary.mealsLoggedCount),
                  ),
                ),
                const SizedBox(width: AppDimens.xs),
                Expanded(
                  child: RecapStatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.warning,
                    iconBgColor: AppColors.warningSurface,
                    value: avg != null ? avg.round().toString() : '—',
                    label: l10n.monthlyRecapAvgCalories,
                  ),
                ),
                const SizedBox(width: AppDimens.xs),
                Expanded(
                  child: RecapStatCard(
                    icon: Icons.verified_rounded,
                    iconColor: AppColors.success,
                    iconBgColor: AppColors.successSurface,
                    value: adherence != null ? '${adherence.round()}%' : '—',
                    label: l10n.monthlyRecapAdherenceCaption,
                    valueColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.lg),
            // FittedBox: máy hẹp thì thu nhỏ thay vì tràn dòng.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: StreakCounterWidget(
                loading: false,
                error: false,
                onRetry: () {},
                retryLabel: l10n.recapStreakRetry,
                streakLabel: l10n.monthlyRecapStreak(summary.bestStreakWeeks),
                bestLabel: l10n.monthlyRecapStreakCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Insight tháng của 1 thành viên: `InsightCard` cả tháng + danh sách tuần
/// mở/đóng được (mỗi tuần cũng là 1 `InsightCard`).
class MonthlyMemberInsightCard extends StatefulWidget {
  const MonthlyMemberInsightCard({super.key, required this.member});

  final MonthlyMemberInsight member;

  @override
  State<MonthlyMemberInsightCard> createState() =>
      _MonthlyMemberInsightCardState();
}

class _MonthlyMemberInsightCardState extends State<MonthlyMemberInsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weeks = widget.member.weeks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InsightCard(insight: widget.member.summary),
        if (weeks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
            child: TextButton.icon(
              key: ValueKey<String>('monthly-weeks-${widget.member.memberId}'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
              label: Text(
                _expanded
                    ? l10n.monthlyRecapHideWeeks
                    : l10n.monthlyRecapShowWeeks(weeks.length),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (_expanded)
          for (final week in weeks) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.xs,
                AppDimens.md,
                0,
              ),
              child: Text(
                l10n.monthlyRecapWeekLabel(
                  DateFormat('dd/MM').format(week.weekStart),
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            InsightCard(insight: week.insight),
          ],
      ],
    );
  }
}

/// Danh sách insight tháng — rỗng (isStale=true) thì hiện câu trống.
class MonthlyInsightList extends StatelessWidget {
  const MonthlyInsightList({
    super.key,
    required this.members,
    required this.emptyText,
  });

  final List<MonthlyMemberInsight> members;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Text(
          emptyText,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return Column(
      children: <Widget>[
        for (final m in members)
          MonthlyMemberInsightCard(
            key: ValueKey<String>(m.memberId),
            member: m,
          ),
      ],
    );
  }
}

/// "Từ 01/11 đến 30/11" — phụ đề cho khối lãng phí/chi tiêu của tháng.
String monthlyRecapRange(BuildContext context, DateTime month) {
  final f = DateFormat('dd/MM');
  final end = DateTime(month.year, month.month + 1, 0);
  return context.l10n.monthlyRecapMonthRange(f.format(month), f.format(end));
}
