import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../cooking/scenes/cooking_routes.dart' show CookingArgs, CookingRoutes;
import '../domain/meal_plan_slot.dart';
import '../domain/vote_session_summary.dart';
import '../stores/meal_plan_store.dart';
import '../scenes/meal_plan_routes.dart';

/// 1 ô lưới meal plan (FE-7 §12, Observer riêng — granular reactivity).
///
/// Hiển thị danh sách `MealPlanDish` của slot + nút "+ Thêm món". Tap `DishChip`
/// theo `dish.status`:
/// - `EMPTY`/`SUGGESTED` → mở `MealPlanRoutes.voteOf(slotId, dishId)`
/// - `VOTING` → mở `MealPlanRoutes.detailOf(slotId, dishId)`
/// - `CONFIRMED` → `Get.bottomSheet(ConfirmedDishSheet)` (Guard §15.13).
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.slot,
    required this.slotKey,
    required this.store,
    this.onTapEmptySlot,
  });

  final MealPlanSlot slot;
  final String slotKey;
  final MealPlanStore store;
  final void Function(String slotId)? onTapEmptySlot;

  @override
  Widget build(BuildContext context) {
    return Observer(
      // Rebuild CHỈ ô này khi slot đó đổi (Guard §15.1).
      builder: (_) {
        // Đọc lại slot mới nhất từ store — key mang store.slots[key].
        final currentSlot = store.slots[slotKey] ?? slot;
        final uiStatus = store.uiStatusOf(slotKey);
        return Card(
          margin: const EdgeInsets.all(2),
          elevation: 0,
          color: _bgColor(uiStatus),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: _borderColor(uiStatus)),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: InkWell(
            onTap: currentSlot.dishes.isEmpty && currentSlot.id.isNotEmpty
                ? () {
                    onTapEmptySlot?.call(currentSlot.id);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...currentSlot.dishes.map(
                    (MealPlanDish dish) => _DishChip(
                      dish: dish,
                      voteTallyCount: _voteCount(dish.id),
                      onTap: () => _handleDishTap(dish),
                    ),
                  ),
                  if (currentSlot.id.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _confirmAddDish(currentSlot.id),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(context.l10n.mealPlanAddDish,
                          style: const TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.sm),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int? _voteCount(String dishId) {
    final session = store.activeSessions[dishId];
    if (session == null) return null;
    final total = session.tally.fold<int>(
      0,
      (int prev, VoteTallyItem t) => prev + t.count,
    );
    return total == 0 ? null : total;
  }

  void _handleDishTap(MealPlanDish dish) {
    switch (dish.status) {
      case DishUiStatus.empty:
      case DishUiStatus.suggested:
        Get.toNamed<void>(
          MealPlanRoutes.voteOf(dish.slotId, dish.id),
        );
      case DishUiStatus.voting:
        Get.toNamed<void>(
          MealPlanRoutes.detailOf(dish.slotId, dish.id),
        );
      case DishUiStatus.confirmed:
        Get.bottomSheet<void>(
          ConfirmedDishSheet(
            dish: dish,
            onRemove: () async {
              await store.removeDish(dish.slotId, dish.id);
            },
          ),
          backgroundColor: Theme.of(Get.context!).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusLg)),
          ),
        );
    }
  }

  Future<void> _confirmAddDish(String slotId) async {
    await store.addDish(slotId);
  }

  Color _bgColor(SlotUiStatus status) {
    switch (status) {
      case SlotUiStatus.empty:
        return Colors.transparent;
      case SlotUiStatus.voting:
        return AppColors.secondary.withValues(alpha: 0.05);
      case SlotUiStatus.inProgress:
        return AppColors.warning.withValues(alpha: 0.05);
      case SlotUiStatus.confirmed:
        return AppColors.success.withValues(alpha: 0.05);
    }
  }

  Color _borderColor(SlotUiStatus status) {
    switch (status) {
      case SlotUiStatus.empty:
        return AppColors.border;
      case SlotUiStatus.voting:
        return AppColors.secondary.withValues(alpha: 0.4);
      case SlotUiStatus.inProgress:
        return AppColors.warning.withValues(alpha: 0.4);
      case SlotUiStatus.confirmed:
        return AppColors.success.withValues(alpha: 0.4);
    }
  }
}

class _DishChip extends StatelessWidget {
  const _DishChip({
    required this.dish,
    required this.voteTallyCount,
    required this.onTap,
  });

  final MealPlanDish dish;
  final int? voteTallyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _label(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            if (voteTallyCount != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$voteTallyCount',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _label(BuildContext context) {
    if (dish.status == DishUiStatus.confirmed) {
      return dish.recipe?.recipeName ?? context.l10n.mealplanConfirmed;
    }
    switch (dish.status) {
      case DishUiStatus.empty:
        return context.l10n.mealplanAddSuggestion;
      case DishUiStatus.suggested:
        return context.l10n.mealplanWaitingForVote;
      case DishUiStatus.voting:
        return context.l10n.mealplanVoting;
      case DishUiStatus.confirmed:
        return dish.recipe?.recipeName ?? '';
    }
  }
}

/// Bottom-sheet cho CONFIRMED dish (Guard §15.13 — KHÔNG điều hướng route).
class ConfirmedDishSheet extends StatelessWidget {
  const ConfirmedDishSheet({
    super.key,
    required this.dish,
    required this.onRemove,
  });

  final MealPlanDish dish;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(dish.recipe?.recipeName ?? context.l10n.mealplanSelectedDish,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimens.sm),
            if (dish.recipe != null && dish.recipe!.source == 'AI')
              Text(context.l10n.mealplanAiSuggestion),
            const SizedBox(height: AppDimens.lg),
            if (dish.recipe != null)
              FilledButton.icon(
                onPressed: () {
                  Get.back<void>();
                  Get.toNamed<void>(
                    CookingRoutes.session,
                    arguments: CookingArgs.start(dish.recipe!.recipeId),
                  );
                },
                icon: const Icon(Icons.restaurant),
                label: Text(context.l10n.mealplanStartCooking),
              ),
            const SizedBox(height: AppDimens.sm),
            TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(context.l10n.mealplanDeleteDishTitle),
                    content: Text(context.l10n.mealplanDeleteDishMessage),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(context.l10n.delete,
                            style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await onRemove();
                if (context.mounted) Get.back<void>();
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: Text(context.l10n.mealplanDeleteDish,
                  style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}
