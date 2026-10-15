import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/meal_log_entry.dart';
import '../domain/meal_type.dart';
import 'confidence_badge.dart';

/// 1 item trong danh sách `todayLogs` (meal-log-screen §11.1 MealLogCard).
///
/// Render theo `entry.status` + `entry.confidenceBadge`; tap mở CalorieConfirmSheet
/// khi badge != confident (hoá giải bởi caller qua `onTap`).
class MealLogCard extends StatelessWidget {
  const MealLogCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onRetry,
    this.onDelete,
  });

  final MealLogEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.xs),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        onTap: _tappable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: _content(context),
        ),
      ),
    );
  }

  bool get _tappable =>
      entry.status == MealEntryStatus.saved &&
      entry.confidenceBadge != MealConfidenceBadge.confident;

  Widget _content(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (entry.mealType != null) ...<Widget>[
                    Text(
                      entry.mealType!.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppDimens.xs),
                  ],
                  if (entry.status == MealEntryStatus.saved) ...[
                    const Spacer(),
                    ConfidenceBadge(badge: entry.confidenceBadge),
                  ],
                ],
              ),
              if (entry.description?.isNotEmpty ?? false) ...<Widget>[
                const SizedBox(height: AppDimens.xs),
                Text(
                  entry.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppDimens.xs),
              _bottomLine(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomLine(BuildContext context) {
    final l10n = context.l10n;
    return switch (entry.status) {
      MealEntryStatus.pending => Row(
          children: <Widget>[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppDimens.sm),
            Text(
              l10n.mealLogSaving,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      MealEntryStatus.saved => Text(
          entry.caloriesKcal == null
              ? (entry.confirmedByUser ? l10n.mealLogConfirmed : '—')
              : l10n.mealLogCalories(entry.caloriesKcal!),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark),
        ),
      MealEntryStatus.failed => Row(
          children: <Widget>[
            const Icon(Icons.error_outline,
                size: 16, color: AppColors.error),
            const SizedBox(width: AppDimens.xs),
            Expanded(
              child: Text(
                l10n.mealLogSaveFailed,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(l10n.mealLogRetry)),
            if (onDelete != null)
              TextButton(
                  onPressed: onDelete, child: Text(l10n.mealLogDelete)),
          ],
        ),
    };
  }
}