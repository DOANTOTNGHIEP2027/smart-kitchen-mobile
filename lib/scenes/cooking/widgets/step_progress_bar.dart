import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';

/// Thanh tiến trình bước hiện tại / tổng số bước (FE-6 §7.3).
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.viewedStep,
    required this.currentStep,
    required this.totalSteps,
  });

  final int viewedStep;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps <= 0 ? 0.0 : (viewedStep / totalSteps);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Bước $viewedStep/$totalSteps',
                style: theme.textTheme.titleSmall,
              ),
              if (viewedStep != currentStep)
                Text(
                  'Đang xem lại (hiện tại: bước $currentStep)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.warning),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.xs),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
