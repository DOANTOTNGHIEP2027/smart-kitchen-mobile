import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_colors_extension.dart';
import '../../../constants/app_dimens.dart';
import '../../../constants/app_icons.dart';
import '../../../utils/l10n_x.dart';
import '../domain/compliance.dart';

/// Badge điểm tuân thủ kế hoạch (nutrition-summary-widget.md §9.1).
///
/// Dòng "Chưa kiểm tra dị ứng" LUÔN hiện (D16, Guard 3) — điểm chỉ dựa trên
/// calo, không bao giờ được hiểu là "an toàn dị ứng".
class DietComplianceBadge extends StatelessWidget {
  const DietComplianceBadge({
    super.key,
    required this.score,
    required this.level,
    this.onSetTarget,
  });

  final int? score;
  final ComplianceLevel level;

  /// Có giá trị khi chưa đặt target → hiện nút "Đặt mục tiêu calo".
  final VoidCallback? onSetTarget;

  static Color colorFor(ComplianceLevel level, BuildContext context) =>
      switch (level) {
        ComplianceLevel.excellent => AppColors.nutritionExcellent,
        ComplianceLevel.good => AppColors.nutritionGood,
        ComplianceLevel.needsImprovement => AppColors.nutritionNeedsImprovement,
        ComplianceLevel.poor => AppColors.nutritionPoor,
        ComplianceLevel.unknown => context.appColors.textDisabled,
      };

  /// Màu chữ trên nền badge — chữ tối cho nền sáng (vàng/xám) để đạt
  /// tương phản ≥ 4.5:1 (code review #64 MEDIUM-1).
  static Color foregroundFor(ComplianceLevel level, BuildContext context) =>
      switch (level) {
        ComplianceLevel.needsImprovement => AppColors.textPrimary,
        // Theo theme: dark mode nền xám tối cần chữ sáng (review v2 NEW-1).
        ComplianceLevel.unknown => context.appColors.textPrimary,
        _ => Theme.of(context).colorScheme.onPrimary,
      };

  static String labelFor(ComplianceLevel level, BuildContext context) {
    final l10n = context.l10n;
    return switch (level) {
      ComplianceLevel.excellent => l10n.nutritionComplianceExcellent,
      ComplianceLevel.good => l10n.nutritionComplianceGood,
      ComplianceLevel.needsImprovement =>
        l10n.nutritionComplianceNeedsImprovement,
      ComplianceLevel.poor => l10n.nutritionCompliancePoor,
      ComplianceLevel.unknown => l10n.nutritionComplianceUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = colorFor(level, context);
    final label = labelFor(level, context);
    final value = score;
    final textTheme = Theme.of(context).textTheme;
    final semantics = <String>[
      l10n.nutritionScoreLabel,
      if (value != null) l10n.nutritionScoreOutOf(value),
      label,
      l10n.nutritionAllergenNotChecked,
    ].join(', ');

    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: onSetTarget == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (value != null) ...<Widget>[
                Text(
                  l10n.nutritionScoreOutOf(value),
                  key: const ValueKey<String>('nutrition-score'),
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: AppDimens.sm),
              ],
              DecoratedBox(
                key: const ValueKey<String>('nutrition-level'),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.sm + 2, vertical: AppDimens.xs),
                  child: Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: foregroundFor(level, context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (onSetTarget != null) ...<Widget>[
            const SizedBox(height: AppDimens.sm),
            TextButton.icon(
              key: const ValueKey<String>('nutrition-set-target'),
              onPressed: onSetTarget,
              icon: const Icon(AppIcons.edit, size: 18),
              label: Text(l10n.nutritionSetTarget),
            ),
          ],
          const SizedBox(height: AppDimens.xs),
          Row(
            key: const ValueKey<String>('nutrition-allergen-note'),
            children: <Widget>[
              Icon(AppIcons.warning,
                  size: 16, color: context.appColors.warning),
              const SizedBox(width: AppDimens.xs),
              Expanded(
                child: Text(
                  l10n.nutritionAllergenNotChecked,
                  style: textTheme.labelSmall
                      ?.copyWith(color: context.appColors.warning),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
