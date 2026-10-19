import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/l10n_x.dart';
import '../domain/repetition_summary.dart';

/// Top món lặp theo `occurrenceCount` (thiết kế §8.5) — cùng khuôn
/// `AdherenceWeeklyBarChart` (#87). BE chỉ trả món ≥ 2 lần: ≥ 3 lần = đỏ
/// (lặp cao), 2 lần = cam (đáng chú ý).
class RepetitionBarChart extends StatelessWidget {
  const RepetitionBarChart({super.key, required this.dishes});

  /// Đã sort giảm dần ở `RepetitionSummary.fromJson`.
  final List<RepeatedDish> dishes;

  static const int maxBars = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = dishes.take(maxBars).toList();
    final maxCount =
        top.fold<int>(0, (a, d) => d.occurrenceCount > a ? d.occurrenceCount : a);
    return BarChart(
      BarChartData(
        maxY: (maxCount + 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= top.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: 64,
                    child: Text(
                      top[i].recipeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (var i = 0; i < top.length; i++)
            BarChartGroupData(x: i, barRods: <BarChartRodData>[
              BarChartRodData(
                toY: top[i].occurrenceCount.toDouble(),
                color: top[i].occurrenceCount >= 3
                    ? AppColors.error
                    : AppColors.warning,
                width: 18,
                borderRadius: BorderRadius.zero,
              ),
            ]),
        ],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= top.length) return null;
              final d = top[groupIndex];
              return BarTooltipItem(
                '${d.recipeName}\n${l10n.planningRepetitionCount(d.occurrenceCount)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}
