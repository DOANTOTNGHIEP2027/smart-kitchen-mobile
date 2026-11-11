import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../domain/daily_nutrition_point.dart';
import 'chart_gap_utils.dart';

/// Đường calo/ngày + đường mục tiêu dashed (Calo tab, issue #87).
/// Thiết kế chuẩn UI/UX Pro Max & DESIGN_SYSTEM.md:
/// Trực quan, có giải thích rõ ràng trục Calo (kcal), chú thích Legend và tương tác Tooltip.
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
    final segments = buildGapSegments(data.length, (i) => data[i].caloriesKcal);

    // Tìm max Y để căn tỷ lệ hợp lý
    final calories = data.map((d) => d.caloriesKcal).whereType<double>();
    final maxCal = calories.isEmpty ? 0.0 : calories.reduce((a, b) => a > b ? a : b);
    final target = targetDailyCalories?.toDouble() ?? 0.0;
    final peak = maxCal > target ? maxCal : target;
    final maxY = peak > 0 ? (peak * 1.2).ceilToDouble() : 2500.0;

    return Container(
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
          // Header tiêu đề & ý nghĩa biểu đồ
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Lượng Calo Nạp Vào Hàng Ngày',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      targetDailyCalories != null
                          ? 'So sánh mức calo thực tế với mục tiêu $targetDailyCalories kcal/ngày'
                          : 'Theo dõi lượng calo tiêu thụ qua từng ngày trong tháng',
                      style: const TextStyle(
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
          // Legend chú thích các đường
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Calo thực tế',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (targetDailyCalories != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 14,
                      height: 2,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Mục tiêu ($targetDailyCalories kcal)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Không có log (Gap)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '💡 Chạm vào điểm trên đường biểu đồ để xem chi tiết ngày và lượng calo',
            style: TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          // Khu vực vẽ LineChart
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 500,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.7),
                    strokeWidth: 1,
                    dashArray: const <int>[4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: maxY > 0 ? maxY / 4 : 500,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.round()}k',
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
                      interval: _dayInterval(data.length),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${data[i].date.day}',
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
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tooltipMargin: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final i = s.x.toInt();
                        if (i < 0 || i >= data.length) {
                          return const LineTooltipItem('', TextStyle());
                        }
                        final day = data[i].date.day;
                        final month = data[i].date.month;
                        final cal = s.y.round();
                        final lines = <String>[
                          'Ngày $day/$month',
                          'Nạp: $cal kcal',
                        ];
                        if (targetDailyCalories != null) {
                          final diff = cal - targetDailyCalories!;
                          if (diff > 0) {
                            lines.add('⚠ Vượt mục tiêu: +$diff kcal');
                          } else {
                            lines.add('✓ Trong hạn mức: ${diff.abs()} kcal còn lại');
                          }
                        }
                        return LineTooltipItem(
                          lines.join('\n'),
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  for (final segment in segments)
                    LineChartBarData(
                      spots: segment,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      barWidth: 2.5,
                      color: AppColors.primary,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.primary,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  // Đường mục tiêu dashed
                  if (targetDailyCalories != null && data.isNotEmpty)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, targetDailyCalories!.toDouble()),
                        FlSpot((data.length - 1).toDouble(),
                            targetDailyCalories!.toDouble()),
                      ],
                      isCurved: false,
                      dotData: const FlDotData(show: false),
                      dashArray: const [6, 4],
                      color: const Color(0xFF10B981),
                      barWidth: 1.8,
                    ),
                ],
              ),
            ),
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
