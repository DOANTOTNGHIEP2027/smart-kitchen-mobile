import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../domain/meal_plan_candidate.dart';

/// Nhãn l10n cho key feature của engine; key lạ (engine thêm feature mới)
/// hiện nguyên key thay vì ẩn đi.
String softScoreFeatureLabel(AppLocalizations l10n, String key) =>
    switch (key) {
      'inventory_coverage' => l10n.planningFeatureInventoryCoverage,
      'expiry_urgency' => l10n.planningFeatureExpiryUrgency,
      'repetition_penalty' => l10n.planningFeatureRepetitionPenalty,
      'nutrition_fit' => l10n.planningFeatureNutritionFit,
      'diet_match' => l10n.planningFeatureDietMatch,
      'effort_fit' => l10n.planningFeatureEffortFit,
      'preference' => l10n.planningFeaturePreference,
      'prior' => l10n.planningFeaturePrior,
      'nutrient_balance' => l10n.planningFeatureNutrientBalance,
      'risk_penalty' => l10n.planningFeatureRiskPenalty,
      'constraint_match' => l10n.planningFeatureConstraintMatch,
      'graph_path' => l10n.planningFeatureGraphPath,
      _ => key,
    };

/// Bảng điểm mềm của 1 ứng viên PASSED — mỗi feature 1 thanh 0..1 kèm trọng
/// số đọc từ response (thiết kế §8.3, không hardcode trọng số).
class SoftScoreBreakdownPanel extends StatelessWidget {
  const SoftScoreBreakdownPanel({super.key, required this.features});

  final List<SoftScoreFeature> features;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = features.where((f) => f.value != null).toList();
    if (shown.isEmpty) {
      return Text(
        l10n.planningCandidateNoBreakdown,
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final f in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: _FeatureRow(feature: f),
          ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final SoftScoreFeature feature;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = feature.value!.clamp(0.0, 1.0);
    // Trọng số âm = feature trừ điểm (vd. lặp món) → tô màu cảnh báo.
    // `repetition_penalty` luôn là phạt — BE fallback (#106) chèn key này mà
    // không kèm trọng số; `risk_penalty` (KG-C) cũng là phạt.
    final isPenalty = (feature.weight ?? 0) < 0 ||
        feature.key == 'repetition_penalty' ||
        feature.key == 'risk_penalty';
    final weight = feature.weight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                softScoreFeatureLabel(l10n, feature.key),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (weight != null)
              Text(
                l10n.planningCandidateWeight(weight.toStringAsFixed(2)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.secondaryFill,
            color: isPenalty ? AppColors.warning : AppColors.sage,
          ),
        ),
      ],
    );
  }
}
