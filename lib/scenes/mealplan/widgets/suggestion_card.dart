import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/meal_suggestion.dart';
import 'allergen_banner.dart';
import 'recipe_cover_image.dart';

/// Card hiển thị 1 suggestion món ăn. Dùng trong cả `MealSuggestionDetailScene`
/// (chi tiết đầy đủ) và `VoteSessionScene` (rút gọn).
///
/// Hiển thị theo pattern render-theo-null của §9.3:
/// - `rankReason` → luôn hiển thị (sẽ luôn có từ engine, tuna từ OAS `required`)
/// - `tradeoffNote` → hiển thị PHỤ dưới rankReason nếu có
/// - `source == "GENERATED"` → badge riêng "AI sinh"
/// - `missingIngredients` → list kèm role (MAIN/SECONDARY/SEASONING)
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.tallyCount,
    this.isMyVote = false,
    this.compact = false,
  });

  final MealSuggestion suggestion;
  final int? tallyCount;
  final bool isMyVote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.xs),
      elevation: 0,
      shape: isMyVote
          ? RoundedRectangleBorder(
              side: BorderSide(
                  color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            )
          : RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (compact)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RecipeCoverImage(
                    recipeId: suggestion.recipeId,
                    recipeName: suggestion.mealName,
                    width: 96,
                    height: 96,
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: _SuggestionSummary(
                      suggestion: suggestion,
                      tallyCount: tallyCount,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            if (compact) AllergenBanner(suggestion: suggestion)
            else ...<Widget>[
              RecipeCoverImage(
                recipeId: suggestion.recipeId,
                recipeName: suggestion.mealName,
              ),
              const SizedBox(height: AppDimens.md),
              _SuggestionSummary(
                suggestion: suggestion,
                tallyCount: tallyCount,
                theme: theme,
              ),
              AllergenBanner(suggestion: suggestion),
              if (suggestion.missingIngredients.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppDimens.sm),
                Text(context.l10n.mealplanNeedsMore, style: theme.textTheme.titleSmall),
                ...suggestion.missingIngredients.map(
                  (IngredientItem i) => Padding(
                    padding: const EdgeInsets.only(left: AppDimens.md, top: 2),
                    child: Text(
                      '• ${i.role?.toLowerCase() == 'main' ? context.l10n.mealplanMainIngredientPrefix : ''}'
                      '${i.name} — ${i.quantity} ${i.unit}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionSummary extends StatelessWidget {
  const _SuggestionSummary({
    required this.suggestion,
    required this.tallyCount,
    required this.theme,
  });

  final MealSuggestion suggestion;
  final int? tallyCount;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  suggestion.mealName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (suggestion.source == 'GENERATED') const _SourceBadge(),
              if (tallyCount != null && tallyCount! > 0) ...<Widget>[
                const SizedBox(width: AppDimens.sm),
                _TallyBadge(count: tallyCount!),
              ],
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            suggestion.rankReason ?? context.l10n.mealplanNoReason,
            style: theme.textTheme.bodyMedium,
          ),
          if (suggestion.tradeoffNote != null) ...<Widget>[
            const SizedBox(height: AppDimens.xs),
            Text(
              suggestion.tradeoffNote!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      );
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimens.sm, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: Text(
          context.l10n.mealplanAiGenerated,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _TallyBadge extends StatelessWidget {
  const _TallyBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count vote',
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
