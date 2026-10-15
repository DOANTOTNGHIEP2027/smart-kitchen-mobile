import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';

/// Hiển thị đồng hồ đếm ngược hoặc thời lượng gợi ý tĩnh (FE-6 §7.3) — phong cách Tasty:
/// Tông màu sage-green thanh nhã, đồng hồ to rõ ràng, nút bấm lớn dễ thao tác khi nấu ăn.
class StepTimerView extends StatelessWidget {
  const StepTimerView({
    super.key,
    required this.remainingSeconds,
    required this.durationSeconds,
    required this.isViewingCurrentStep,
    required this.timerRunning,
    this.onToggle,
    this.onReset,
  });

  final int? remainingSeconds;
  final int? durationSeconds;
  final bool isViewingCurrentStep;
  final bool timerRunning;
  final VoidCallback? onToggle;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Không có duration → ẩn hoàn toàn.
    if (durationSeconds == null) return const SizedBox.shrink();

    // Không đang ở bước hiện tại → hiển thị tĩnh.
    if (!isViewingCurrentStep) {
      final minutes = (durationSeconds! / 60).ceil();
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.timer_outlined,
              size: 20,
              color: AppColors.sage,
            ),
            const SizedBox(width: AppDimens.sm),
            Text(
              context.l10n.cookingSuggestedDuration(minutes),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Đang ở currentStep: hiển thị countdown + nút điều khiển.
    final remaining = remainingSeconds ?? durationSeconds!;
    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.sageLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.sageBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            timerRunning ? Icons.timer_rounded : Icons.timer_off_rounded,
            size: 28,
            color: AppColors.sageDark,
          ),
          const SizedBox(width: AppDimens.sm),
          Text(
            '$mm:$ss',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.sageDark,
              fontWeight: FontWeight.w800,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          if (onToggle != null)
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.sage,
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                timerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              onPressed: onToggle,
              tooltip: timerRunning
                  ? context.l10n.cookingPause
                  : context.l10n.cookingResume,
            ),
          if (onReset != null) ...<Widget>[
            const SizedBox(width: AppDimens.xs),
            IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: onReset,
              tooltip: context.l10n.cookingReset,
            ),
          ],
        ],
      ),
    );
  }
}
