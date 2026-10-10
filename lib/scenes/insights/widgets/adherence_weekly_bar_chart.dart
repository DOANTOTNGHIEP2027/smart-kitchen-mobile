import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../utils/l10n_x.dart';
import '../domain/weekly_adherence_point.dart';

/// 1 cột/tuần lịch trong tháng đang xem (tab Mức Độ Tuân Thủ, issue #87).
///
/// `BarChart` không có khái niệm "gap" (1 cột luôn có chiều cao) — tuần chưa có
/// snapshot (`adherencePercent == null`) dùng MÀU XÁM NHẠT cao 0, phân biệt với
/// "0% tuân thủ thật" (đỏ đậm) bằng MÀU (decision §8.4).
class AdherenceWeeklyBarChart extends StatelessWidget {
  const AdherenceWeeklyBarChart({super.key, required this.data});

  final List<WeeklyAdherencePoint> data;

  static const _goodColor = Color(0xFF2E7D32);
  static const _badColor = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BarChart(
      BarChartData(
        maxY: 100,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].adherencePercent ?? 0,
                // Ngưỡng 70% khớp ĐÚNG ngưỡng streak +1 (#84) — không đặt
                // ngưỡng màu khác không liên quan ngữ nghĩa streak.
                color: data[i].adherencePercent == null
                    ? Colors.grey.shade300
                    : (data[i].adherencePercent! >= 70
                        ? _goodColor
                        : _badColor),
                width: 18,
                borderRadius: BorderRadius.zero,
              ),
            ]),
        ],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= data.length) return null;
              final p = data[groupIndex];
              if (p.adherencePercent == null) {
                return BarTooltipItem(
                  l10n.insightsNoWeekData,
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }
              return BarTooltipItem(
                l10n.insightsAdherenceStart(
                  p.adherencePercent!.round(),
                  p.weekStart.day,
                  p.weekStart.month,
                ),
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}