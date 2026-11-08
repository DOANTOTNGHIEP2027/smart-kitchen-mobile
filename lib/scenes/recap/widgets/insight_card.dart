import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/recap_badge.dart';
import '../domain/weekly_recap_summary.dart';
import 'recap_badge_colors.dart';

/// Card insight per-member — StatelessWidget THUẦN nhận dữ liệu qua
/// constructor, KHÔNG đọc store / Observer (Guard #8) để compliance-ring
/// animation (800ms) không bị retrigger bởi rebuild ngoài ý muốn.
/// weekly-recap-screen.md §9.6.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final MemberWeeklyInsight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              key: ValueKey(insight.memberId),
              tween: Tween<double>(begin: 0, end: insight.ringRatio),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => CustomPaint(
                painter: _ComplianceRingPainter(
                  ratio: value,
                  badge: insight.badge,
                ),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Center(
                    child: Text(
                      '${insight.compliancePct.round()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    insight.highlight,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.tip,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 13,
                          color: AppColors.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.recapNutrientGap(insight.topNutrientGap),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Danh sách InsightCard toàn household — khi rỗng (isStale=true) hiện
/// empty-state riêng (Guard #3). Đặt NGOÀI RepaintBoundary (Guard #12).
class InsightCardList extends StatelessWidget {
  const InsightCardList({
    super.key,
    required this.insights,
    required this.emptyText,
  });

  final List<MemberWeeklyInsight> insights;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Text(
          emptyText,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return Column(
      children: <Widget>[
        for (final insight in insights) InsightCard(insight: insight),
      ],
    );
  }
}

/// Vòng cung `ratio * 360°`, màu theo badge — nền vòng tròn xám nhạt phần còn
/// lại. `ratio` đã clamp [0,1] (`ringRatio`), số giữa là `compliancePct` GỐC
/// (html không clamp, có thể >100%, hiển thị ở InsightCard).
class _ComplianceRingPainter extends CustomPainter {
  const _ComplianceRingPainter({required this.ratio, required this.badge});

  final double ratio;
  final RecapBadge badge;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.5;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceSubtle;
    canvas.drawCircle(center, radius, background);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = RecapBadgeColors.of(badge);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ratio,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_ComplianceRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio || oldDelegate.badge != badge;
}
