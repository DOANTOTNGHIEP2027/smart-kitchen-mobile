import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../domain/daily_nutrition_point.dart';
import 'chart_gap_utils.dart';

/// 3 lớp cumulative protein/carbs/fat theo ngày (Macro tab, issue #87).
/// Thiết kế chuẩn UI/UX Pro Max & DESIGN_SYSTEM.md:
/// Trực quan, có giải thích rõ ràng trục đơn vị (gam - g), chú thích từng chất dinh dưỡng
/// và hỗ trợ chạm (touch tooltip) xem phân bổ cụ thể.
class MacroStackedAreaChart extends StatelessWidget {
  const MacroStackedAreaChart({super.key, required this.data});

  final List<DailyNutritionPoint> data;

  static const _proteinColor = Color(0xFF10B981); // Emerald Teal tươi mới
  static const _carbsColor = Color(0xFFF59E0B);   // Vàng cam ấm
  static const _fatColor = Color(0xFFEF4444);     // Đỏ san hô mềm mại

  @override
  Widget build(BuildContext context) {
    bool noData(int i) => data[i].proteinG == null;

    final proteinSegments =
        buildGapSegments(data.length, (i) => noData(i) ? null : data[i].proteinG);
    final proteinCarbsSegments = buildGapSegments(
      data.length,
      (i) => noData(i)
          ? null
          : data[i].proteinG! + (data[i].carbsG ?? 0),
    );
    final totalSegments = buildGapSegments(
      data.length,
      (i) => noData(i)
          ? null
          : data[i].proteinG! + (data[i].carbsG ?? 0) + (data[i].fatG ?? 0),
    );

    // Tính max gram để căn trục Y
    final totals = data.map((d) => (d.proteinG ?? 0) + (d.carbsG ?? 0) + (d.fatG ?? 0));
    final peakTotal = totals.isEmpty ? 0.0 : totals.reduce((a, b) => a > b ? a : b);
    final maxY = peakTotal > 0 ? (peakTotal * 1.2).ceilToDouble() : 200.0;

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
          // Header tiêu đề
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Cơ Cấu Dinh Dưỡng Hàng Ngày (Macro)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Lượng Đạm (Protein), Tinh bột (Carbs) và Béo (Fat) tính theo gam (g)',
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
          // Legend các chất dinh dưỡng
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
                      color: _proteinColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Đạm (Protein)',
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
                      color: _carbsColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Tinh bột (Carbs)',
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
                      color: _fatColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Chất béo (Fat)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                    'Không có log',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '💡 Chạm vào biểu đồ để xem chi tiết khối lượng từng chất theo ngày',
            style: TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.7),
                    strokeWidth: 1,
                    dashArray: const <int>[4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY > 0 ? maxY / 4 : 50,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.round()}g',
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
                      if (spots.isEmpty) return [];
                      final i = spots.first.x.toInt();
                      if (i < 0 || i >= data.length || noData(i)) {
                        return [const LineTooltipItem('', TextStyle())];
                      }
                      final day = data[i].date.day;
                      final month = data[i].date.month;
                      final p = (data[i].proteinG ?? 0).toStringAsFixed(1);
                      final c = (data[i].carbsG ?? 0).toStringAsFixed(1);
                      final f = (data[i].fatG ?? 0).toStringAsFixed(1);
                      final total = ((data[i].proteinG ?? 0) + (data[i].carbsG ?? 0) + (data[i].fatG ?? 0)).toStringAsFixed(1);

                      final text = 'Ngày $day/$month\n'
                          '• Đạm: $p g\n'
                          '• Carbs: $c g\n'
                          '• Béo: $f g\n'
                          'Tổng: $total g';

                      return [
                        LineTooltipItem(
                          text,
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ];
                    },
                  ),
                ),
                lineBarsData: [
                  // 1) TỔNG (gồm cả fat) — vẽ trước, dưới cùng z-order.
                  for (final s in totalSegments)
                    LineChartBarData(
                      spots: s,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      dotData: const FlDotData(show: false),
                      barWidth: 2,
                      color: _fatColor,
                      belowBarData: BarAreaData(show: true, color: _fatColor),
                    ),
                  // 2) protein+carbs — vẽ sau (1), che phần dưới → dải fat lộ phần chênh.
                  for (final s in proteinCarbsSegments)
                    LineChartBarData(
                      spots: s,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      dotData: const FlDotData(show: false),
                      barWidth: 2,
                      color: _carbsColor,
                      belowBarData: BarAreaData(show: true, color: _carbsColor),
                    ),
                  // 3) protein — vẽ sau cùng, che phần dưới → dải carbs lộ phần chênh.
                  for (final s in proteinSegments)
                    LineChartBarData(
                      spots: s,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      dotData: const FlDotData(show: false),
                      barWidth: 2,
                      color: _proteinColor,
                      belowBarData: BarAreaData(show: true, color: _proteinColor),
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
