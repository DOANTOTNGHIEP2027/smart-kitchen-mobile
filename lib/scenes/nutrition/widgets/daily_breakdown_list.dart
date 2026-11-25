import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_colors_extension.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/compliance.dart';
import '../domain/nutrition_models.dart';
import 'nutrition_format.dart';

/// 7 ngày mở/đóng được, mỗi ngày liệt kê từng bữa + món (§9.5).
class DailyBreakdownList extends StatelessWidget {
  const DailyBreakdownList({super.key, required this.summary});

  final NutritionWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.nutritionDailyBreakdown,
            style: Theme.of(context).textTheme.titleMedium),
        for (final day in summary.days)
          _DayTile(day: day, target: summary.targetDailyCalories),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.target});

  final DailyNutrition day;
  final int? target;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final secondary =
        textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary);
    final status = dayTargetStatus(
      hasData: day.hasNutritionData,
      calories: day.calories,
      targetDailyCalories: target,
      hasMissingData: day.missingNutritionCount > 0,
    );
    final hasTarget = target != null && target! > 0;
    final (String? chip, Color? chipColor) = !hasTarget
        ? (null, null)
        : switch (status) {
            DayTargetStatus.over => (l10n.nutritionDayOver, AppColors.nutritionPoor),
            DayTargetStatus.under => (
                l10n.nutritionDayUnder,
                context.appColors.warning
              ),
            DayTargetStatus.onTarget => (
                l10n.nutritionDayOnTarget,
                context.appColors.success
              ),
            DayTargetStatus.noData => (null, null),
          };

    return ExpansionTile(
      key: ValueKey<String>('nutrition-day-${day.date.weekday}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: AppDimens.md, bottom: AppDimens.sm),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(context.fullDay(day.date), style: textTheme.bodyLarge),
      subtitle: Text(
        day.hasPlannedMeals
            ? l10n.nutritionKcal(context.kcalNumber(day.calories))
            : l10n.nutritionNoMealsDay,
        style: secondary,
      ),
      trailing: chip == null
          ? null
          : Text(chip,
              style: textTheme.labelSmall
                  ?.copyWith(color: chipColor, fontWeight: FontWeight.w700)),
      children: <Widget>[
        if (!day.hasPlannedMeals)
          Text(l10n.nutritionNoMealsDay, style: secondary)
        else
          for (final line in day.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.xs),
              child: Text(
                l10n.nutritionDishLine(
                  context.mealLabel(line.mealTime),
                  line.recipeName,
                  line.hasData
                      ? l10n.nutritionKcal(context.kcalNumber(line.calories!))
                      : l10n.nutritionDishNoData,
                ),
                style: secondary,
              ),
            ),
      ],
    );
  }
}
