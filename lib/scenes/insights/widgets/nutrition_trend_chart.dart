import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/l10n_x.dart';
import '../domain/daily_nutrition_point.dart';
import 'chart_gap_utils.dart';

/// Đường calo/ngày + đường mục tiêu dashed (Calo tab, issue #87).
///
/// 2 đường là 2 series riêng biệt trong `fl_chart`; gap ở ngày không có dữ liệu
/// được tách thành nhiều segment (Guard §12.2).
class NutritionTrendChart extends StatelessWidget {
  const NutritionTrendChart({
    super.key,
    required this.data,
    required this.targetDailyCalories,
  });

  /// Đã sort tăng dần theo date, đủ N phần tử / N ngày của tháng.
  final List<DailyNutritionPoint> data;
  final int? targetDailyCalories;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final segments = buildGapSegments(data.length, (i) => data[i].caloriesKcal);
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withValues(alpha: 0.6),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) =>
                  Text('${value.round()}', style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: _dayInterval(data.length),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(
                  '${data[i].date.day}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) {
            return spots.map((s) {
              final i = s.x.toInt();
              if (i < 0 || i >= data.length) {
                return const LineTooltipItem('', TextStyle());
              }
              return LineTooltipItem(
                l10n.insightsCalorieTooltip(
                  data[i].date.day,
                  data[i].date.month,
                  s.y.round(),
                ),
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList();
          }),
        ),
        lineBarsData: [
          for (final segment in segments)
            LineChartBarData(
              spots: segment,
              isCurved: false,
              barWidth: 2,
              color: AppColors.primary,
              dotData: const FlDotData(show: true),
            ),
          // Đường mục tiêu dashed — chỉ vẽ nếu target != null (không tự suy
          // đoán mặc định).
          if (targetDailyCalories != null && data.isNotEmpty)
            LineChartBarData(
              spots: [
                FlSpot(0, targetDailyCalories!.toDouble()),
                FlSpot((data.length - 1).toDouble(), targetDailyCalories!.toDouble()),
              ],
              isCurved: false,
              dotData: const FlDotData(show: false),
              dashArray: const [6, 4],
              color: Colors.grey,
              barWidth: 1.5,
            ),
        ],
      ),
    );
  }

  static double _dayInterval(int length) {
    if (length <= 0) return 1;
    final steps = <int>[1, 2, 3, 5, 7, 10, 14];
    for (final s in steps) {
      if (length ~/ s <= 6) return s.toDouble();
    }
    return 28;
  }
}