import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../domain/weekly_adherence_point.dart';

/// 1 cột/tuần lịch trong tháng đang xem (tab Mức Độ Tuân Thủ, issue #87).
/// Thiết kế chuẩn UI/UX Pro Max & DESIGN_SYSTEM.md:
/// Rõ ràng các mốc phần trăm (%), đường mục tiêu 70% duy trì streak, bo góc mềm mại
/// và giải thích đầy đủ ý nghĩa cho người dùng di động.
class AdherenceWeeklyBarChart extends StatelessWidget {
  const AdherenceWeeklyBarChart({super.key, required this.data});

  final List<WeeklyAdherencePoint> data;

  static const _goodColor = Color(0xFF10B981); // Emerald / Đạt chuẩn streak
  static const _badColor = Color(0xFFEF4444);  // Coral Red / Chưa đạt

  @override
  Widget build(BuildContext context) {
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
                  Icons.verified_rounded,
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
                      'Tỷ Lệ Tuân Thủ Thực Đơn Tuần',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Mức độ ăn theo thực đơn đã lên (đạt ≥ 70% để tích lũy chuỗi)',
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
          // Legend
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
                      color: _goodColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Đạt chuẩn (≥ 70%)',
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
                      color: _badColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Chưa đạt (< 70%)',
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
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '💡 Chạm vào cột để xem tỷ lệ phần trăm cụ thể của từng tuần',
            style: TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          // BarChart
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 105,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
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
                      reservedSize: 38,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        if (value > 100) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.round()}%',
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
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        final weekNum = i + 1;
                        final dateStr = DateFormat('d/M').format(data[i].weekStart);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Tuần $weekNum',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: <HorizontalLine>[
                    HorizontalLine(
                      y: 70,
                      color: _goodColor,
                      strokeWidth: 1.5,
                      dashArray: const <int>[6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(bottom: 2, right: 4),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: _goodColor,
                        ),
                        labelResolver: (_) => 'Mục tiêu: 70%',
                      ),
                    ),
                  ],
                ),
                barGroups: [
                  for (var i = 0; i < data.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: data[i].adherencePercent ?? 4,
                        color: data[i].adherencePercent == null
                            ? const Color(0xFFE2E8F0)
                            : (data[i].adherencePercent! >= 70
                                ? _goodColor
                                : _badColor),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ]),
                ],
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    tooltipMargin: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= data.length) return null;
                      final p = data[groupIndex];
                      final start = DateFormat('d/M').format(p.weekStart);
                      final end = DateFormat('d/M').format(p.weekStart.add(const Duration(days: 6)));
                      final weekNum = groupIndex + 1;

                      if (p.adherencePercent == null) {
                        return BarTooltipItem(
                          'Tuần $weekNum ($start - $end)\nChưa có dữ liệu tuân thủ',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        );
                      }

                      final pct = p.adherencePercent!.round();
                      final isPassed = pct >= 70;
                      final status = isPassed
                          ? '✓ Đạt chuẩn duy trì chuỗi'
                          : '⚠ Chưa đạt chỉ tiêu 70%';

                      return BarTooltipItem(
                        'Tuần $weekNum ($start - $end)\n'
                        'Tuân thủ: $pct%\n$status',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
