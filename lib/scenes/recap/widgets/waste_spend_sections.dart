import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../domain/shared/budget_period.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/waste_spend.dart';
import '../domain/weekly_recap_summary.dart';
import '../stores/weekly_recap_store.dart';

/// Khối "Lãng phí & Chi tiêu" của Weekly Recap (weekly-recap-screen.md §17.4).
/// Mọi widget là Stateless nhận dữ liệu qua constructor (Guard #8) và nằm
/// NGOÀI RepaintBoundary chia sẻ — số tiền không lọt vào ảnh share (Guard #19).

/// Thứ Hai dd/MM – Chủ Nhật dd/MM — CHỈ dùng bên trong khối waste/spend
/// (lịch tuần thật), không cho HouseholdStatsStrip (Guard #18).
String recapWeekRange(AppLocalizations l10n, DateTime weekStart) {
  final f = DateFormat('dd/MM');
  final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
  return l10n.recapWeekRange(f.format(weekStart), f.format(end));
}

class RecapSectionTitle extends StatelessWidget {
  const RecapSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.md, AppDimens.lg, AppDimens.md, AppDimens.xs),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
}

class _Block extends StatelessWidget {
  const _Block({required this.title, this.subtitle, required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.xs),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 3),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              ...children,
            ],
          ),
        ),
      );
}

/// Thanh tỉ lệ ngang dùng chung cho breakdown lãng phí và nhóm chi tiêu.
class _RatioRow extends StatelessWidget {
  const _RatioRow({
    required this.label,
    required this.value,
    required this.ratio,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color == AppColors.warning ? AppColors.textPrimary : color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.surfaceSubtle,
                color: color,
              ),
            ),
          ],
        ),
      );
}

class WasteSection extends StatelessWidget {
  const WasteSection({
    super.key,
    required this.count,
    required this.breakdown,
    required this.weekStart,
  });

  /// Con số hiển thị luôn là field của BE — không cộng lại từ breakdown (Guard #15).
  final int count;
  final WasteCauseBreakdown breakdown;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (count == 0) {
      return _Block(
        title: l10n.recapWasteTitle,
        subtitle: recapWeekRange(l10n, weekStart),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.recapWasteNone,
                    key: const ValueKey<String>('waste-none'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final total = breakdown.barTotal;
    double r(int v) => total == 0 ? 0 : v / total;
    final rows = <(String, int)>[
      (l10n.recapWasteOverbought, breakdown.overbought),
      (l10n.recapWasteForgotten, breakdown.forgotten),
      (l10n.recapWasteSpoiledEarly, breakdown.spoiledEarly),
      (l10n.recapWasteUntagged, breakdown.untagged),
      if (breakdown.other > 0) (l10n.recapWasteOther, breakdown.other),
    ];
    return _Block(
      title: l10n.recapWasteTitle,
      subtitle: recapWeekRange(l10n, weekStart),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.delete_sweep_outlined, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.recapWasteCount(count),
                key: const ValueKey<String>('waste-count'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.md),
        for (final (label, v) in rows)
          _RatioRow(
            label: label,
            value: '$v món',
            ratio: r(v),
            color: AppColors.warning,
          ),
      ],
    );
  }
}

class SpendSection extends StatelessWidget {
  const SpendSection({
    super.key,
    required this.summary,
    required this.canSetBudget,
    required this.onSetBudget,
  });

  final WeeklyRecapSummary summary;
  final bool canSetBudget;
  final VoidCallback onSetBudget;

  /// Ngưỡng màu là lựa chọn hiển thị của FE (decision D14).
  static Color colorFor(double ratio) => ratio > 1
      ? AppColors.error
      : (ratio > 0.8 ? AppColors.warning : AppColors.success);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = summary;
    final spend = s.spendTotal;
    final budget = s.budgetWeeklyAmount;
    final ratio = s.spendRatio;
    final children = <Widget>[];

    if (spend == null) {
      children.addAll(<Widget>[
        Text(
          l10n.recapSpendNone,
          key: const ValueKey<String>('spend-none'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.recapSpendNoneHint,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ]);
    } else if (budget != null) {
      children.add(Text(
        l10n.recapSpendOfBudget(formatVnd(spend), formatVnd(budget)),
        key: const ValueKey<String>('spend-of-budget'),
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ));
      if (ratio != null) {
        final over = (spend - budget).round() > 0;
        final color = over ? AppColors.error : colorFor(ratio.clamp(0.0, 1.0));
        children.addAll(<Widget>[
          const SizedBox(height: AppDimens.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            child: LinearProgressIndicator(
              key: const ValueKey<String>('spend-progress'),
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.surfaceSubtle,
              color: color,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: over
                      ? AppColors.errorSurface
                      : (ratio > 0.8 ? AppColors.warningSurface : AppColors.successSurface),
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                ),
                child: Text(
                  over
                      ? l10n.recapSpendOver(
                          (ratio * 100).round(), formatVnd(spend - budget))
                      : l10n.recapSpendPercent((ratio * 100).round()),
                  key: const ValueKey<String>('spend-percent'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (s.shoppingCompletedItemCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.receipt_long_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        l10n.recapSpendCoverage(
                            s.spendItemCount, s.shoppingCompletedItemCount),
                        key: const ValueKey<String>('spend-coverage'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ]);
      }
    } else {
      children.add(Text(
        formatVnd(spend),
        key: const ValueKey<String>('spend-total'),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ));
    }

    final budgetAmount = s.budgetAmount;
    if (budgetAmount != null && s.budgetPeriod != BudgetPeriod.weekly) {
      children.addAll(<Widget>[
        const SizedBox(height: AppDimens.xs),
        Text(
          s.budgetPeriod == BudgetPeriod.monthly
              ? l10n.recapBudgetConvertedMonthly(formatVnd(budgetAmount))
              : l10n.recapBudgetConvertedOther(formatVnd(budgetAmount)),
          key: const ValueKey<String>('spend-converted'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ]);
    }

    if (budget == null) {
      children.add(const SizedBox(height: AppDimens.sm));
      children.add(canSetBudget
          ? Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                key: const ValueKey<String>('spend-set-budget'),
                label: l10n.recapSetBudget,
                variant: AppButtonVariant.secondary,
                expanded: false,
                onPressed: onSetBudget,
              ),
            )
          : Text(
              l10n.recapNoBudgetMember,
              key: const ValueKey<String>('spend-no-budget-member'),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ));
    }

    return _Block(
      title: l10n.recapSpendTitle,
      subtitle: recapWeekRange(l10n, s.weekStart),
      children: children,
    );
  }
}

class SpendDetailSection extends StatelessWidget {
  const SpendDetailSection({
    super.key,
    required this.gate,
    required this.summary,
    required this.onUpgrade,
  });

  final SpendDetailGate gate;
  final WeeklyRecapSummary summary;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    switch (gate) {
      case SpendDetailGate.lockedUpsell:
        return _Block(
          title: l10n.recapSpendByCategory,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    l10n.recapSpendUpsell,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            AppButton(
              key: const ValueKey<String>('spend-upsell-cta'),
              label: l10n.recapUpgradePremium,
              onPressed: onUpgrade,
            ),
          ],
        );
      case SpendDetailGate.lockedNeutral:
        return _Block(
          title: l10n.recapSpendByCategory,
          children: <Widget>[
            Text(
              l10n.recapSpendDetailNeutral,
              key: const ValueKey<String>('spend-detail-neutral'),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        );
      case SpendDetailGate.unlocked:
        final categories = summary.spendByCategory ?? const <String, double>{};
        final trend = summary.spendTrend;
        final total = categories.values.fold<double>(0, (a, b) => a + b);
        final sorted = categories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return _Block(
          title: l10n.recapSpendByCategory,
          children: <Widget>[
            if (sorted.isEmpty)
              Text(
                l10n.recapSpendCategoryEmpty,
                key: const ValueKey<String>('spend-category-empty'),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              )
            else
              Column(
                key: const ValueKey<String>('spend-category-list'),
                children: <Widget>[
                  for (final e in sorted)
                    _RatioRow(
                      label: e.key == 'UNCATEGORIZED'
                          ? l10n.recapUncategorized
                          : e.key,
                      value: formatVnd(e.value),
                      ratio: total <= 0 ? 0 : e.value / total,
                      color: AppColors.primary,
                    ),
                ],
              ),
            if (trend != null && trend.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppDimens.lg),
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${l10n.recapSpendTrend} (VNĐ)',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'So sánh chi tiêu thực tế với ngân sách tuần',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.sm),
                    // Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Chi tiêu',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Vượt ngân sách',
                              style: TextStyle(fontSize: 11, color: AppColors.error),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 14,
                              height: 2,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Ngân sách',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: AppColors.border),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Chưa có giá',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '💡 Chạm vào từng cột để xem chi tiết tiền chi và chênh lệch',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),
                    SizedBox(
                      height: 190,
                      child: SpendTrendSparkline(points: trend),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
    }
  }
}

String formatVndCompact(double value) {
  if (value <= 0) return '0';
  if (value >= 1000000) {
    final m = value / 1000000;
    return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}tr';
  }
  if (value >= 1000) {
    final k = value / 1000;
    return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 0)}k';
  }
  return '${value.round()}';
}

/// Cột chi tiêu tối đa 8 tuần + đường ngân sách tuần gần nhất.
class SpendTrendSparkline extends StatelessWidget {
  const SpendTrendSparkline({super.key, required this.points});

  final List<SpendTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final shown = points.length > 8
        ? points.sublist(points.length - 8)
        : points;
    final values = <double>[
      for (final p in shown) ...<double?>[p.spendTotal, p.budgetWeeklyAmount]
          .whereType<double>(),
    ];
    final peak = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = peak > 0 ? peak * 1.25 : 1.0;
    final budgetLine = shown.reversed
        .map((p) => p.budgetWeeklyAmount)
        .whereType<double>()
        .firstOrNull;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: maxY > 0 ? maxY / 3 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withValues(alpha: 0.8),
            strokeWidth: 1,
            dashArray: const <int>[4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: maxY > 0 ? maxY / 3 : 1,
              getTitlesWidget: (value, meta) {
                if (value <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    formatVndCompact(value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= shown.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('d/M').format(shown[i].weekStart),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tooltipMargin: 6,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => const Color(0xFF1E293B),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= shown.length) return null;
              final p = shown[groupIndex];
              final weekStart = p.weekStart;
              final weekEnd = weekStart.add(const Duration(days: 6));
              final dateStr = 'Tuần ${DateFormat('d/M').format(weekStart)} - ${DateFormat('d/M').format(weekEnd)}';

              final spend = p.spendTotal;
              final budget = p.budgetWeeklyAmount ?? budgetLine;

              final lines = <String>[dateStr];
              if (spend != null) {
                lines.add('Chi tiêu: ${formatVnd(spend)}');
                if (budget != null) {
                  lines.add('Ngân sách: ${formatVnd(budget)}');
                  final diff = budget - spend;
                  if (diff >= 0) {
                    lines.add('✓ Tiết kiệm: ${formatVnd(diff)}');
                  } else {
                    lines.add('⚠ Vượt: +${formatVnd(-diff)}');
                  }
                }
              } else {
                lines.add('Chưa có dữ liệu giá');
                if (budget != null) {
                  lines.add('Ngân sách: ${formatVnd(budget)}');
                }
              }
              return BarTooltipItem(
                lines.join('\n'),
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              );
            },
          ),
        ),
        extraLinesData: budgetLine == null
            ? null
            : ExtraLinesData(
                horizontalLines: <HorizontalLine>[
                  HorizontalLine(
                    y: budgetLine,
                    color: const Color(0xFF10B981),
                    strokeWidth: 1.5,
                    dashArray: const <int>[6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(bottom: 2, right: 4),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                      labelResolver: (_) => 'Mục tiêu: ${formatVndCompact(budgetLine)}',
                    ),
                  ),
                ],
              ),
        barGroups: <BarChartGroupData>[
          for (var i = 0; i < shown.length; i++)
            BarChartGroupData(x: i, barRods: <BarChartRodData>[
              shown[i].spendTotal == null
                  ? BarChartRodData(
                      toY: maxY * 0.25,
                      width: 16,
                      color: Colors.transparent,
                      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      borderDashArray: const <int>[3, 3],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    )
                  : BarChartRodData(
                      toY: shown[i].spendTotal!,
                      width: 16,
                      color: (budgetLine != null && shown[i].spendTotal! > budgetLine)
                          ? AppColors.error
                          : AppColors.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
            ]),
        ],
      ),
    );
  }
}
