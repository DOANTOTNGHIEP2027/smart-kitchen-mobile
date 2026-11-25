import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_colors_extension.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/nutrition_models.dart';
import 'nutrition_format.dart';

/// Doughnut tỷ lệ protein/carbs/fat cả tuần, theo gram (§9.4, D19, D22).
/// Legend luôn có tên + % nên màu không phải tín hiệu duy nhất.
class MacroDoughnutChart extends StatelessWidget {
  const MacroDoughnutChart({super.key, required this.summary});

  final NutritionWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ratios = summary.macroRatios;
    final center = ratios == null
        ? l10n.nutritionNoMacroData
        : l10n.nutritionKcal(context.kcalNumber(summary.totalCalories));
    final entries = ratios == null
        ? const <(String, double, Color)>[]
        : <(String, double, Color)>[
            (l10n.nutritionProtein, ratios.protein, AppColors.macroProtein),
            (l10n.nutritionCarbs, ratios.carbs, AppColors.macroCarbs),
            (l10n.nutritionFat, ratios.fat, AppColors.macroFat),
          ];

    return Column(
      children: <Widget>[
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ExcludeSemantics(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 46,
                    sectionsSpace: 2,
                    sections: ratios == null
                        ? <PieChartSectionData>[
                            PieChartSectionData(
                              value: 1,
                              color: context.appColors.border,
                              radius: 18,
                              showTitle: false,
                            ),
                          ]
                        : <PieChartSectionData>[
                            for (final e in entries)
                              PieChartSectionData(
                                value: e.$2,
                                color: e.$3,
                                radius: 18,
                                showTitle: false,
                              ),
                          ],
                  ),
                ),
              ),
              SizedBox(
                width: 84,
                child: Text(
                  center,
                  key: const ValueKey<String>('nutrition-macro-center'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (entries.isNotEmpty)
          Wrap(
            spacing: AppDimens.md,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final e in entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: e.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: AppDimens.xs),
                    Text(
                      l10n.nutritionMacroPercent(e.$1, context.percent(e.$2)),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}
