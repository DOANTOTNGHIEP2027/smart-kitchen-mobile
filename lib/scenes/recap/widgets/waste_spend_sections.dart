import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../constants/app_text_styles.dart';
import '../../../domain/shared/budget_period.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/cards/app_card.dart';
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
  // Cộng theo NGÀY lịch, không `add(Duration(days: 6))` — máy ở múi giờ có DST
  // lùi giờ trong tuần sẽ ra Thứ Bảy 23:00 → nhãn lệch 1 ngày.
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
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
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
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle != null)
                Text(subtitle!,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppDimens.sm),
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
    this.color = AppColors.sage,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.xs),
        child: Row(
          children: <Widget>[
            SizedBox(
                width: 130,
                child: Text(label, style: AppTextStyles.bodyMedium)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.secondaryFill,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Text(value, style: AppTextStyles.label),
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
          Text(l10n.recapWasteNone,
              key: const ValueKey<String>('waste-none'),
              style: AppTextStyles.bodyMedium),
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
        Text(l10n.recapWasteCount(count),
            key: const ValueKey<String>('waste-count'),
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppDimens.sm),
        for (final (label, v) in rows)
          _RatioRow(
              label: label,
              value: '$v',
              ratio: r(v),
              color: AppColors.warning),
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
      // Guard #13: null ≠ 0 — KHÔNG hiển thị "0 ₫".
      children.addAll(<Widget>[
        Text(l10n.recapSpendNone,
            key: const ValueKey<String>('spend-none'),
            style: AppTextStyles.bodyMedium),
        Text(l10n.recapSpendNoneHint,
            style:
                AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
      ]);
    } else if (budget != null) {
      children.add(Text(
        l10n.recapSpendOfBudget(formatVnd(spend), formatVnd(budget)),
        key: const ValueKey<String>('spend-of-budget'),
        style: Theme.of(context).textTheme.titleMedium,
      ));
      if (ratio != null) {
        // % là giá trị GỐC (có thể > 100%, §17.4); "Vượt" chỉ khi phần vượt
        // làm tròn còn >= 1 ₫ — tránh "Vượt 0 ₫" với ngân sách quy đổi lẻ.
        // Màu đỏ đi cùng nhãn "Vượt" — không đỏ khi câu chữ nói chưa vượt.
        final over = (spend - budget).round() > 0;
        final color = over ? AppColors.error : colorFor(ratio.clamp(0.0, 1.0));
        children.addAll(<Widget>[
          const SizedBox(height: AppDimens.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: LinearProgressIndicator(
              key: const ValueKey<String>('spend-progress'),
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.secondaryFill,
              color: color,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
          Text(
            over
                ? l10n.recapSpendOver(
                    (ratio * 100).round(), formatVnd(spend - budget))
                : l10n.recapSpendPercent((ratio * 100).round()),
            key: const ValueKey<String>('spend-percent'),
            style: AppTextStyles.label.copyWith(color: color),
          ),
        ]);
      }
    } else {
      children.add(Text(formatVnd(spend),
          key: const ValueKey<String>('spend-total'),
          style: Theme.of(context).textTheme.titleMedium));
    }

    // Guard #17: mẫu số 0 → ẩn hẳn, không "0/0".
    if (s.shoppingCompletedItemCount > 0) {
      children.addAll(<Widget>[
        const SizedBox(height: AppDimens.xs),
        Text(
          l10n.recapSpendCoverage(
              s.spendItemCount, s.shoppingCompletedItemCount),
          key: const ValueKey<String>('spend-coverage'),
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
      ]);
    }

    final budgetAmount = s.budgetAmount;
    if (budgetAmount != null && s.budgetPeriod != BudgetPeriod.weekly) {
      // Neo theo con số, không đoán tên chu kỳ FE chưa biết (FIX LOW-A9).
      children.addAll(<Widget>[
        const SizedBox(height: AppDimens.xs),
        Text(
          s.budgetPeriod == BudgetPeriod.monthly
              ? l10n.recapBudgetConvertedMonthly(formatVnd(budgetAmount))
              : l10n.recapBudgetConvertedOther(formatVnd(budgetAmount)),
          key: const ValueKey<String>('spend-converted'),
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
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
          : Text(l10n.recapNoBudgetMember,
              key: const ValueKey<String>('spend-no-budget-member'),
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary)));
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
                const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                    child: Text(l10n.recapSpendUpsell,
                        style: AppTextStyles.bodyMedium)),
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              key: const ValueKey<String>('spend-upsell-cta'),
              label: l10n.recapUpgradePremium,
              onPressed: onUpgrade,
            ),
          ],
        );
      case SpendDetailGate.lockedNeutral:
        // Claim nói PREMIUM mà BE không trả — KHÔNG mời nâng cấp.
        return _Block(
          title: l10n.recapSpendByCategory,
          children: <Widget>[
            Text(l10n.recapSpendDetailNeutral,
                key: const ValueKey<String>('spend-detail-neutral'),
                style: AppTextStyles.bodyMedium),
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
              Text(l10n.recapSpendCategoryEmpty,
                  key: const ValueKey<String>('spend-category-empty'),
                  style: AppTextStyles.bodyMedium)
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
                    ),
                ],
              ),
            // FIX LOW-A6: trend null/[] → bỏ hẳn sparkline, không vẽ khung rỗng.
            if (trend != null && trend.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppDimens.md),
              Text(l10n.recapSpendTrend,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppDimens.sm),
              SizedBox(
                height: 140,
                child: SpendTrendSparkline(points: trend),
              ),
            ],
          ],
        );
    }
  }
}

/// Cột chi tiêu tối đa 8 tuần + đường ngân sách tuần gần nhất. Tuần
/// `spendTotal == null` vẽ cột rỗng viền đứt — KHÔNG vẽ cột 0 (Guard #13).
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
    // peak 0 (mọi tuần chi 0 ₫, chưa có ngân sách) → maxY 0 làm cột rỗng của
    // tuần null cao 0, biến mất — mất phân biệt null ≠ 0 (Guard #13).
    final maxY = peak > 0 ? peak * 1.15 : 1.0;
    final budgetLine = shown.reversed
        .map((p) => p.budgetWeeklyAmount)
        .whereType<double>()
        .firstOrNull;
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        // Nhãn tuần d/M dưới mỗi cột (mock-up state 10) — không có thì không
        // biết cột nào là tuần nào, kể cả cột rỗng của tuần chưa nhập giá.
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= shown.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d/M').format(shown[i].weekStart),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        extraLinesData: budgetLine == null
            ? null
            : ExtraLinesData(horizontalLines: <HorizontalLine>[
                HorizontalLine(
                  y: budgetLine,
                  color: AppColors.textSecondary,
                  strokeWidth: 1,
                  dashArray: const <int>[4, 3],
                ),
              ]),
        barGroups: <BarChartGroupData>[
          for (var i = 0; i < shown.length; i++)
            BarChartGroupData(x: i, barRods: <BarChartRodData>[
              shown[i].spendTotal == null
                  ? BarChartRodData(
                      toY: maxY * 0.3,
                      width: 14,
                      color: Colors.transparent,
                      borderSide: const BorderSide(color: AppColors.border),
                      borderDashArray: const <int>[3, 3],
                      borderRadius: BorderRadius.zero,
                    )
                  : BarChartRodData(
                      toY: shown[i].spendTotal!,
                      width: 14,
                      color: AppColors.sage,
                      borderRadius: BorderRadius.zero,
                    ),
            ]),
        ],
      ),
    );
  }
}
