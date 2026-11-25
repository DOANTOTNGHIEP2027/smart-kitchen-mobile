import 'package:flutter/material.dart';

import '../../../constants/app_colors_extension.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/nutrition_models.dart';
import 'nutrition_format.dart';

/// Tổng kcal tuần so với mục tiêu (nutrition-summary-widget.md §9.2).
///
/// Mục tiêu = target × số ngày có dữ liệu — không dùng ×7, tránh hiểu lầm khi
/// tuần mới lên kế hoạch vài ngày.
class WeeklyCalorieOverviewCard extends StatelessWidget {
  const WeeklyCalorieOverviewCard({super.key, required this.summary});

  final NutritionWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final secondary =
        textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary);
    final target = summary.targetDailyCalories;
    final days = summary.daysWithData;
    final avg = summary.avgDailyCalories;
    final targetForDays = summary.targetForDaysWithData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.nutritionWeeklyTotal, style: secondary),
        Text(
          l10n.nutritionKcal(context.kcalNumber(summary.totalCalories)),
          key: const ValueKey<String>('nutrition-weekly-total'),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (target == null || target <= 0)
          Text(l10n.nutritionNoTarget, style: secondary)
        else if (targetForDays != null) ...<Widget>[
          Text(
            l10n.nutritionTargetForDays(days, context.kcalNumber(targetForDays)),
            style: secondary,
          ),
          Text(
            l10n.nutritionWeeklyDelta(_signed(
                context, summary.totalCalories - targetForDays)),
            key: const ValueKey<String>('nutrition-weekly-delta'),
            style: secondary,
          ),
        ],
        Text(
          avg == null
              ? l10n.nutritionNoDataDays
              : l10n.nutritionAvgPerDay(context.kcalNumber(avg), days),
          style: secondary,
        ),
        if (summary.missingNutritionCount > 0) ...<Widget>[
          const SizedBox(height: AppDimens.xs),
          DecoratedBox(
            key: const ValueKey<String>('nutrition-missing-chip'),
            decoration: BoxDecoration(
              color: context.appColors.warningSurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.sm, vertical: 2),
              child: Text(
                l10n.nutritionMissingData(summary.missingNutritionCount),
                style: textTheme.labelSmall
                    ?.copyWith(color: context.appColors.warning),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _signed(BuildContext context, double value) {
    final text = context.kcalNumber(value.abs());
    if (value.round() == 0) return text;
    return value > 0 ? '+$text' : '−$text';
  }
}
