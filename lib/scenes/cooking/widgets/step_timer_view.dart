import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';

/// Hiển thị đồng hồ đếm ngược hoặc thời lượng gợi ý tĩnh (FE-6 §7.3).
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
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.sm),
        child: Text(
          'Thời lượng gợi ý: $minutes phút',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Đang ở currentStep + có timer chạy: hiển thị countdown + nút điều khiển.
    final remaining = remainingSeconds ?? durationSeconds!;
    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.sm),
      child: Row(
        children: <Widget>[
          Icon(timerRunning ? Icons.timer : Icons.timer_off,
              size: 28),
          const SizedBox(width: AppDimens.sm),
          Text(
            '$mm:$ss',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures()
              ],
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          if (onToggle != null)
            IconButton(
              icon: Icon(timerRunning
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline),
              onPressed: onToggle,
              tooltip: timerRunning ? 'Tạm dừng' : 'Tiếp tục',
            ),
          if (onReset != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onReset,
              tooltip: 'Đặt lại',
            ),
        ],
      ),
    );
  }
}
