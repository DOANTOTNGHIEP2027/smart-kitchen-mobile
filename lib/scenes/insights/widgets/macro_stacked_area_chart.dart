import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/daily_nutrition_point.dart';
import 'chart_gap_utils.dart';

/// 3 lớp cumulative protein/carbs/fat theo ngày (Macro tab, issue #87).
///
/// Kỹ thuật (Decision D5): tính 3 series cumulative, vẽ theo thứ tự TỔNG LỚN
/// NHẤT TRƯỚC (dưới cùng z-order trong `lineBarsData`), NHỎ NHẤT SAU (trên
/// cùng, che phần dưới bằng màu đặc/opaque) — series vẽ sau che đúng phần dưới
/// của series vẽ trước, tạo hiệu ứng dải màu chồng đúng như stacked-area.
class MacroStackedAreaChart extends StatelessWidget {
  const MacroStackedAreaChart({super.key, required this.data});

  final List<DailyNutritionPoint> data;

  static const _proteinColor = Color(0xFF2E7D32);
  static const _carbsColor = Color(0xFFF9A825);
  static const _fatColor = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    // "Không có dữ liệu ngày đó" luôn gate theo proteinG (bất biến §5.1: 4
    // field null cùng lúc) — dùng 1 điều kiện null-check cho cả 3 cumulative
    // series, không lệch nhau giữa protein/carbs/fat.
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

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // 1) TỔNG — vẽ trước, dưới cùng z-order.
          for (final s in totalSegments)
            LineChartBarData(
              spots: s,
              isCurved: false,
              dotData: const FlDotData(show: false),
              color: _fatColor,
              belowBarData: BarAreaData(show: true, color: _fatColor),
            ),
          // 2) protein+carbs — vẽ sau (1), che phần dưới → dải fat lộ phần chênh.
          for (final s in proteinCarbsSegments)
            LineChartBarData(
              spots: s,
              isCurved: false,
              dotData: const FlDotData(show: false),
              color: _carbsColor,
              belowBarData: BarAreaData(show: true, color: _carbsColor),
            ),
          // 3) protein — vẽ sau cùng, che phần dưới → dải carbs lộ phần chênh.
          for (final s in proteinSegments)
            LineChartBarData(
              spots: s,
              isCurved: false,
              dotData: const FlDotData(show: false),
              color: _proteinColor,
              belowBarData: BarAreaData(show: true, color: _proteinColor),
            ),
        ],
      ),
    );
  }
}