import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/meal_plan_candidate.dart';
import 'soft_score_breakdown_panel.dart';

/// 1 ứng viên với đúng 3 badge thiết kế §8.3: ⭐ lựa chọn cuối cùng / đã qua
/// kiểm tra / 🚫 bị loại. Mọi card — kể cả BLOCKED — đều hiện (I7) và mang nhãn
/// "Gợi ý AI" để tách rõ nguồn AI với tầng lọc/xếp hạng của thuật toán.
class CandidateCard extends StatefulWidget {
  const CandidateCard({super.key, required this.candidate});

  final MealPlanCandidate candidate;

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> {
  // Lựa chọn cuối cùng mở sẵn bảng điểm; PASSED khác gập lại, tap để mở.
  late bool _expanded = widget.candidate.isAlgorithmRecommended;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.candidate;
    final recommended = c.isAlgorithmRecommended;
    final borderRadius = BorderRadius.circular(AppDimens.radiusMd);
    return Opacity(
      opacity: c.isBlocked ? 0.6 : 1,
      child: Material(
        key: ValueKey<String>('candidate-${c.id}'),
        color: AppColors.surface,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: c.isBlocked ? null : () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: recommended ? AppColors.sage : AppColors.border,
                width: recommended ? 2 : AppDimens.borderWidth,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        c.recipeName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    _Pill(
                      icon: Icons.smart_toy_outlined,
                      text: l10n.planningCandidateAiLabel,
                      background: AppColors.secondaryFill,
                      foreground: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.sm),
                _statusPill(context),
                if (!c.isBlocked && c.softScore != null) ...<Widget>[
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    l10n.planningCandidateScore(c.softScore!.toStringAsFixed(2)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                // I1: BLOCKED không có điểm mềm → không có bảng điểm.
                if (!c.isBlocked && _expanded) ...<Widget>[
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    l10n.planningCandidateBreakdown,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppDimens.xs),
                  SoftScoreBreakdownPanel(features: c.features),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.candidate;
    if (c.isBlocked) {
      final reason = c.blockedReason?.trim();
      return _Pill(
        key: const ValueKey<String>('candidate-badge-blocked'),
        icon: Icons.block,
        text: l10n.planningCandidateBlocked(
          reason == null || reason.isEmpty
              ? l10n.planningCandidateBlockedUnknown
              : reason,
        ),
        background: AppColors.errorSurface,
        foreground: AppColors.error,
      );
    }
    if (c.isUnverified) {
      return _Pill(
        key: const ValueKey<String>('candidate-badge-unverified'),
        icon: Icons.warning_amber_rounded,
        text: l10n.planningCandidateUnverified,
        background: AppColors.primaryLight,
        foreground: AppColors.primaryDark,
      );
    }
    if (c.isAlgorithmRecommended) {
      return _Pill(
        key: const ValueKey<String>('candidate-badge-final'),
        icon: Icons.star_rounded,
        text: l10n.planningCandidateFinalPick,
        background: AppColors.sageLight,
        foreground: AppColors.sageDark,
      );
    }
    return _Pill(
      key: const ValueKey<String>('candidate-badge-passed'),
      icon: Icons.verified_outlined,
      text: l10n.planningCandidatePassed,
      background: AppColors.secondaryFill,
      foreground: AppColors.textPrimary,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.sm, vertical: AppDimens.xs),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppDimens.xs),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
