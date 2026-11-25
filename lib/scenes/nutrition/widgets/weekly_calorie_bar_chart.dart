import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_colors_extension.dart';
import '../../../utils/l10n_x.dart';
import '../domain/compliance.dart';
import '../domain/nutrition_models.dart';
import 'nutrition_format.dart';

/// 7 cột kcal/ngày (nutrition-summary-widget.md §9.3): xanh khi ≤ 110% target,
/// đỏ khi vượt > 10%, xám khi ngày chưa có dữ liệu, primary khi chưa có target.
class WeeklyCalorieBarChart extends StatelessWidget {
  const WeeklyCalorieBarChart({super.key, required this.summary});

  final NutritionWeekSummary summary;

  static Color barColor(DailyNutrition day, int? target, BuildContext context) {
    final status = dayTargetStatus(
      hasData: day.hasNutritionData,
      calories: day.calories,
      targetDailyCalories: target,
      hasMissingData: day.missingNutritionCount > 0,
    );
    if (status == DayTargetStatus.noData) return context.appColors.border;
    if (target == null || target <= 0) {
      return Theme.of(context).colorScheme.primary;
    }
    return status == DayTargetStatus.over
        ? AppColors.nutritionPoor
        : context.appColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = summary.days;
    final target = summary.targetDailyCalories;
    final hasTarget = target != null && target > 0;
    final peak = days.fold<double>(0, (m, d) => math.max(m, d.calories));
    final maxY = math.max(peak, hasTarget ? target.toDouble() : 0) * 1.15 + 1;
    final chartSemantics = l10n.nutritionChartSemantics(days
        .map((d) => l10n.nutritionBarSemantics(
            context.fullDay(d.date), context.kcalNumber(d.calories)))
        .join('; '));

    return Semantics(
      label: chartSemantics,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          context.shortWeekday(days[i].date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: <HorizontalLine>[
                  if (hasTarget)
                    HorizontalLine(
                      y: target.toDouble(),
                      color: context.appColors.textSecondary,
                      strokeWidth: 1.5,
                      dashArray: const <int>[6, 4],
                    ),
                ],
              ),
              barTouchData: BarTouchData(
                enabled: true,
                // Ngày trống cột cao 0 vẫn chạm được (review v3 LOW-3).
                allowTouchBarBackDraw: true,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) =>
                      Theme.of(context).colorScheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    _tooltip(context, days[group.x]),
                    TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              barGroups: <BarChartGroupData>[
                for (var i = 0; i < days.length; i++)
                  BarChartGroupData(x: i, barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: days[i].calories,
                      width: 18,
                      color: barColor(days[i], target, context),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Colors.transparent,
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nội dung tooltip — public để test kiểm trực tiếp.
  static String tooltipText(BuildContext context, DailyNutrition day) =>
      _tooltip(context, day);

  static String _tooltip(BuildContext context, DailyNutrition day) {
    final l10n = context.l10n;
    final lines = <String>[context.fullDay(day.date)];
    if (!day.hasPlannedMeals) {
      lines.add(l10n.nutritionNoMealsDay);
    } else {
      lines
        ..add(l10n.nutritionKcal(context.kcalNumber(day.calories)))
        ..add(l10n.nutritionMacroLine(context.grams(day.protein),
            context.grams(day.carbs), context.grams(day.fat)));
      if (day.missingNutritionCount > 0) {
        lines.add(l10n.nutritionMissingData(day.missingNutritionCount));
      }
    }
    return lines.join('\n');
  }
}
