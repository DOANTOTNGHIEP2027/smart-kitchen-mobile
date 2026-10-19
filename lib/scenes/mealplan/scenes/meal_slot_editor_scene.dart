import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../planning/scenes/planning_routes.dart';
import '../domain/meal_plan_slot.dart';
import '../stores/meal_plan_store.dart';
import '../widgets/recipe_cover_image.dart';
import 'meal_plan_routes.dart';

/// Chỉnh một bữa của ngày đã chọn trong lịch tuần — Phong cách Tasty.
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

  /// Mở "Gợi ý AI có kiểm chứng" của đúng món này (OD-08): biết id phiên thật
  /// thì lọc theo phiên; món chưa từng mở phiên thì hiện rỗng + nút sinh.
  void _openCandidates(MealPlanDish dish) {
    final store = Get.find<MealPlanStore>();
    final planId = store.currentPlanId;
    if (planId == null) return;
    final session = store.activeSessions[dish.id];
    // Món đã chốt không được mở phiên mới (cùng luật với `onChoose`) → không
    // truyền slotId/dishId để màn insight không hiện nút sinh gợi ý.
    final canChoose = dish.status != DishUiStatus.confirmed;
    Get.toNamed<void>(PlanningRoutes.candidatesOf(
      planId,
      sessionId: session?.sessionId,
      slotId: canChoose ? widget.slotId : null,
      dishId: canChoose ? dish.id : null,
      dishHasNoSession: session == null && dish.status == DishUiStatus.empty,
    ));
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppDimens.lg),
              ...dishes.map(
                (dish) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.sm),
                  child: _EditableDishCard(
                    dish: dish,
                    onDelete: () => store.removeDish(widget.slotId, dish.id),
                    onInsights: () => _openCandidates(dish),
                    onChoose: dish.status == DishUiStatus.confirmed
                        ? null
                        : () => _openSuggestions(dish.id),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                icon: _isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  context.l10n.mealPlanAddDish,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
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
    required this.onInsights,
    this.onChoose,
  });

  final MealPlanDish dish;
  final VoidCallback onDelete;
  final VoidCallback onInsights;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final recipe = dish.recipe;
    if (recipe == null) {
      return _PendingDishCard(
        onDelete: onDelete,
        onInsights: onInsights,
        onChoose: onChoose,
      );
    }
    final minutes = RecipeCoverImage.demoPrepTimeMinutes(recipe.recipeId);
    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: RecipeCoverImage(
              recipeId: recipe.recipeId,
              recipeName: recipe.recipeName,
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(width: AppDimens.md),
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
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.sage,
                      ),
                      const SizedBox(width: 4),
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
          _InsightsButton(onPressed: onInsights),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
            tooltip: 'Xoá món',
          ),
        ],
      ),
    );
  }
}

class _PendingDishCard extends StatelessWidget {
  const _PendingDishCard({
    required this.onDelete,
    required this.onInsights,
    this.onChoose,
  });

  final VoidCallback onDelete;
  final VoidCallback onInsights;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.sageLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.sage,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimens.md),
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
              IconButton.filledTonal(
                onPressed: onChoose,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.sageLight,
                  foregroundColor: AppColors.sageDark,
                ),
              ),
            _InsightsButton(onPressed: onInsights),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
            ),
          ],
        ),
      );
}

/// Mở "Gợi ý AI có kiểm chứng" của 1 món (flexible-meal-planning §9 mục 1).
class _InsightsButton extends StatelessWidget {
  const _InsightsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        key: const ValueKey<String>('dish-candidate-insights'),
        onPressed: onPressed,
        icon: const Icon(Icons.auto_awesome_outlined),
        color: AppColors.sage,
        tooltip: context.l10n.planningCandidateTooltip,
      );
}
