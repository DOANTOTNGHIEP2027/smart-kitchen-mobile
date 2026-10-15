import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';

/// Thanh tiến trình bước nấu ăn (FE-6 §7.3) — phong cách Tasty:
/// Segmented pill bars cho từng bước, màu sage-green hiện đại, trực quan.
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.md),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                context.l10n.cookingStepProgress(viewedStep, totalSteps),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (viewedStep != currentStep)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    context.l10n.cookingStepReviewing(currentStep),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          // Segmented progress pills
          Row(
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isCompletedOrCurrent = stepNum <= viewedStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompletedOrCurrent
                        ? AppColors.sage
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
