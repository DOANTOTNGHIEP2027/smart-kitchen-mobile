import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../constants/app_text_styles.dart';
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
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
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
                  width: 56,
                  height: 56,
                  child: Center(
                    child: Text(
                      '${insight.compliancePct.round()}%',
                      style: AppTextStyles.label,
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xs),
                  Text(insight.tip, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    l10n.recapNutrientGap(insight.topNutrientGap),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
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
        child: Text(emptyText, style: AppTextStyles.bodyMedium),
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
    const stroke = 5.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
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