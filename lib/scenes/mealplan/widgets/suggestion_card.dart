import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../domain/meal_suggestion.dart';
import 'allergen_banner.dart';

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
      shape: isMyVote
          ? RoundedRectangleBorder(
              side: BorderSide(
                  color: theme.colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
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
                if (suggestion.source == 'GENERATED')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: const Text(
                      'AI sinh',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (tallyCount != null && tallyCount! > 0) ...<Widget>[
                  const SizedBox(width: AppDimens.sm),
                  _TallyBadge(count: tallyCount!),
                ],
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            // rankReason (lý do xếp hạng) — sinh từ engine, không từ LLM.
            Text(
              suggestion.rankReason ?? 'Không có lý do',
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
            AllergenBanner(suggestion: suggestion),
            if (!compact &&
                suggestion.missingIngredients.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppDimens.sm),
              Text('Cần thêm:', style: theme.textTheme.titleSmall),
              ...suggestion.missingIngredients.map(
                (IngredientItem i) => Padding(
                  padding: const EdgeInsets.only(left: AppDimens.md, top: 2),
                  child: Text(
                    '• ${i.role?.toLowerCase() == 'main' ? '[Chính] ' : ''}'
                    '${i.name} — ${i.quantity} ${i.unit}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
