import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/l10n_x.dart';
import '../../cooking/domain/meal_log_entry.dart';

/// Badge NỊ phân cho 1 meal log — dựa trên [MealConfidenceBadge] (Guard #1:
/// KHÔNG có field confidence số; derive từ `requiresConfirmation`/`caloriesKcal`).
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.badge});

  final MealConfidenceBadge badge;

  @override
  Widget build(BuildContext context) {
    return switch (badge) {
      MealConfidenceBadge.confident => const _GreenDot(),
      MealConfidenceBadge.needsReview => _Pill(
          color: AppColors.warning,
          outlined: false,
          label: context.l10n.mealLogNeedsReview,
        ),
      MealConfidenceBadge.noEstimate => _Pill(
          color: AppColors.textSecondary,
          outlined: true,
          label: context.l10n.mealLogNoEstimate,
        ),
    };
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.outlined,
    required this.label,
  });

  final Color color;
  final bool outlined;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
        border: outlined ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: outlined ? color : color,
        ),
      ),
    );
  }
}