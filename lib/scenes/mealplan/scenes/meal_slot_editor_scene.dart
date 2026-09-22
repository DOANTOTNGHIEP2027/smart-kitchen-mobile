import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/meal_plan_slot.dart';
import '../stores/meal_plan_store.dart';
import '../widgets/recipe_cover_image.dart';
import 'meal_plan_routes.dart';

/// Chỉnh một bữa của ngày đã chọn trong lịch tuần.
///
/// Luồng thêm món dùng cùng state/API có sẵn: tạo dish rỗng, mở vote để lấy ba
/// candidate, rồi mở màn chọn suggestion. Khi chọn thành công, store cập nhật
/// slot và màn này tự vẽ card recipe đã xác nhận.
class MealSlotEditorScene extends StatefulWidget {
  const MealSlotEditorScene({
    super.key,
    required this.slotId,
    required this.mealLabel,
    required this.dateLabel,
  });

  final String slotId;
  final String mealLabel;
  final String dateLabel;

  @override
  State<MealSlotEditorScene> createState() => _MealSlotEditorSceneState();
}

class _MealSlotEditorSceneState extends State<MealSlotEditorScene> {
  bool _isAdding = false;

  Future<void> _addDish() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    final store = Get.find<MealPlanStore>();
    try {
      final dish = await store.addDish(widget.slotId);
      if (!mounted) return;
      if (dish == null) {
        _showActionError(context.l10n.mealPlanAddDishFailed);
        return;
      }
      await _openSuggestions(dish.id);
    } catch (_) {
      if (mounted) _showActionError(context.l10n.mealPlanAddDishFailed);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _openSuggestions(String dishId) async {
    try {
      final store = Get.find<MealPlanStore>();
      await store.openVoteSession(widget.slotId, dishId);
      if (!mounted) return;
      await Get.toNamed<void>(
        MealPlanRoutes.detailOf(widget.slotId, dishId),
      );
    } catch (_) {
      if (mounted) {
        _showActionError(context.l10n.mealPlanOpenSuggestionsFailed);
      }
    }
  }

  void _showActionError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<MealPlanStore>();
    return AppScaffold(
      title: '${widget.mealLabel} · ${widget.dateLabel}',
      body: Observer(
        builder: (_) {
          final key = store.slotKeyOf(widget.slotId);
          final slot = key == null ? null : store.slots[key];
          final dishes = slot?.dishes ?? const <MealPlanDish>[];
          return ListView(
            padding: const EdgeInsets.all(AppDimens.lg),
            children: <Widget>[
              Text(
                widget.mealLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                widget.dateLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimens.lg),
              ...dishes.map(
                (dish) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.sm),
                  child: _EditableDishCard(
                    dish: dish,
                    onDelete: () => store.removeDish(widget.slotId, dish.id),
                    onChoose: dish.status == DishUiStatus.confirmed
                        ? null
                        : () => _openSuggestions(dish.id),
                  ),
                ),
              ),
              AppButton(
                label: context.l10n.mealPlanAddDish,
                icon: Icons.add_rounded,
                isLoading: _isAdding,
                onPressed: _isAdding ? null : _addDish,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditableDishCard extends StatelessWidget {
  const _EditableDishCard({
    required this.dish,
    required this.onDelete,
    this.onChoose,
  });

  final MealPlanDish dish;
  final VoidCallback onDelete;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final recipe = dish.recipe;
    if (recipe == null) {
      return _PendingDishCard(onDelete: onDelete, onChoose: onChoose);
    }
    final minutes = RecipeCoverImage.demoPrepTimeMinutes(recipe.recipeId);
    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.32),
          width: 1.2,
        ),
      ),
      child: Row(
        children: <Widget>[
          RecipeCoverImage(
            recipeId: recipe.recipeId,
            recipeName: recipe.recipeName,
            width: 76,
            height: 76,
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  recipe.recipeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (minutes != null) ...<Widget>[
                  const SizedBox(height: AppDimens.xs),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppColors.primaryDark),
                      const SizedBox(width: AppDimens.xs),
                      Text(
                        context.l10n.homeRecipeMinutes(minutes),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _PendingDishCard extends StatelessWidget {
  const _PendingDishCard({required this.onDelete, this.onChoose});

  final VoidCallback onDelete;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.secondaryFill,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.restaurant_menu_outlined,
                color: AppColors.primaryDark),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Text(
                context.l10n.mealPlanDishUnselected,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (onChoose != null)
              IconButton(
                onPressed: onChoose,
                icon: const Icon(Icons.arrow_forward_rounded),
                color: AppColors.primaryDark,
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
            ),
          ],
        ),
      );
}
