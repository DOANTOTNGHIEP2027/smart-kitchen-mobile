import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../planning/scenes/planning_routes.dart';
import '../../planning/widgets/slot_guest_diner_entry.dart';
import '../domain/meal_suggestion.dart';
import '../domain/meal_composition.dart';
import '../domain/meal_plan_slot.dart';
import '../../recipe/domain/recipe.dart';
import '../../recipe/scenes/recipe_list_scene.dart';
import '../stores/meal_plan_store.dart';
import '../stores/meal_composition_store.dart';
import '../widgets/missing_ingredients_prompt.dart';
import '../widgets/meal_composition_panel.dart';
import '../../../app/env_config.dart';
import '../widgets/recipe_cover_image.dart';
import '../widgets/meal_attendance_panel.dart';
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

  /// `null` khi cờ tắt HOẶC store chưa đăng ký (binding chỉ tạo khi tạo mới
  /// MealPlanStore) — không `Get.find` mù.
  MealCompositionStore? get _compositionStore =>
      EnvConfig.automaticMealComposition &&
              Get.isRegistered<MealCompositionStore>()
          ? Get.find<MealCompositionStore>()
          : null;

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
      // Thêm món xong hỏi cách chọn: gợi ý AI (luồng cũ) hay chọn thẳng
      // từ công thức. Đóng sheet = để món "chưa chọn", chọn sau cũng được.
      final source = await _askDishSource();
      if (!mounted) return;
      switch (source) {
        case _DishSource.ai:
          await _openSuggestions(dish.id);
        case _DishSource.recipe:
          await _chooseManual(dish.id);
        case null:
          break;
      }
    } catch (_) {
      if (mounted) _showActionError(context.l10n.mealPlanAddDishFailed);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<_DishSource?> _askDishSource() => showModalBottomSheet<_DishSource>(
        context: context,
        showDragHandle: true,
        builder: (sheetCtx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.lg, vertical: AppDimens.sm),
                  child: Text(
                    sheetCtx.l10n.mealPlanDishSourceTitle,
                    style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ListTile(
                  key: const ValueKey<String>('dish-source-ai'),
                  leading: const Icon(Icons.auto_awesome,
                      color: AppColors.primary),
                  title: Text(sheetCtx.l10n.mealPlanDishSourceAi),
                  onTap: () => Navigator.of(sheetCtx).pop(_DishSource.ai),
                ),
                ListTile(
                  key: const ValueKey<String>('dish-source-recipe'),
                  leading: const Icon(Icons.menu_book_outlined,
                      color: AppColors.primary),
                  title: Text(sheetCtx.l10n.mealPlanChooseRecipe),
                  onTap: () => Navigator.of(sheetCtx).pop(_DishSource.recipe),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _openSuggestions(String dishId) async {
    try {
      if (!mounted) return;
      await Get.toNamed<void>(MealPlanRoutes.detailOf(widget.slotId, dishId));
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
    if (planId == null) {
      _showActionError(context.l10n.planningPlanNotReady);
      return;
    }
    Get.toNamed<void>(
      PlanningRoutes.candidatesOf(
        planId,
        slotId: widget.slotId,
        dishId: dish.id,
      ),
    );
  }

  Future<void> _chooseManual(String dishId) async {
    final recipe = await Get.to<Recipe>(
      () =>
          RecipeListScene(onSelect: (value) => Get.back<Recipe>(result: value)),
    );
    if (recipe == null || !mounted) return;
    final store = Get.find<MealPlanStore>();
    if (store.hasRecipeInSlot(widget.slotId, recipe.id, exceptDishId: dishId)) {
      _showActionError(context.l10n.mealPlanDuplicateRecipe);
      return;
    }
    List<IngredientItem>? serverMissing;
    final ok = await store.assignManual(
      widget.slotId,
      dishId,
      recipe.id,
      recipe.name,
      onAssigned: (dish) => serverMissing = dish.missingIngredients,
    );
    if (!mounted) return;
    if (!ok) {
      _showActionError(context.l10n.mealplanUnableToChoose);
      return;
    }
    final missing =
        await missingForRecipe(recipe.id, fromServer: serverMissing);
    if (mounted) await confirmAddMissingToShopping(context, missing: missing);
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
      titleMaxLines: 2,
      body: Observer(
        builder: (_) {
          final key = store.slotKeyOf(widget.slotId);
          final slot = key == null ? null : store.slots[key];
          final dishes = slot?.dishes ?? const <MealPlanDish>[];
          // Plan đã chốt hoặc bữa của ngày đã qua ⇒ chỉ xem.
          final readOnly =
              store.isConfirmed || store.isSlotLocked(widget.slotId);
          // #201: món do AI ghép bữa đã được BE lưu thành dish thường của
          // slot → chỉ render `dishes` (không render lại menu), menu chỉ bổ
          // sung vai trò + khẩu phần cho thẻ.
          final composition = _compositionStore;
          final composed = composeInfoByDish(
            dishes,
            composition?.contexts[widget.slotId]?.menu,
          );
          return ListView(
            padding: const EdgeInsets.all(AppDimens.lg),
            children: <Widget>[
              if (store.currentPlanId != null) ...<Widget>[
                MealAttendancePanel(
                  planId: store.currentPlanId!,
                  slotId: widget.slotId,
                ),
                // #201: khách ăn cùng theo TỪNG BỮA, ngay dưới điểm danh.
                SlotGuestDinerEntry(
                  planId: store.currentPlanId!,
                  slotId: widget.slotId,
                ),
              ],
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimens.lg),
              if (composition != null)
                MealCompositionPanel(
                  store: composition,
                  slotId: widget.slotId,
                  hasDishes: dishes.isNotEmpty,
                  readOnly: readOnly,
                ),
              ...dishes.map(
                  (dish) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EditableDishCard(
                          key: ValueKey<String>('slot-dish-${dish.id}'),
                          dish: dish,
                          composed: composed[dish.id],
                          onDelete: !store.canEditDish(dish.id)
                              ? null
                              : () => store.removeDish(widget.slotId, dish.id),
                          onInsights: () => _openCandidates(dish),
                          onChoose: readOnly
                              ? null
                              : () => _openSuggestions(dish.id),
                        ),
                        if (!readOnly)
                          Wrap(
                            spacing: 8,
                            children: [
                              if (dish.recipe != null)
                                TextButton.icon(
                                  onPressed: () => _openSuggestions(dish.id),
                                  icon: const Icon(Icons.auto_awesome),
                                  label: Text(
                                    context.l10n.mealPlanGenerateSuggestions,
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: store.canEditDish(dish.id)
                                    ? () => _chooseManual(dish.id)
                                    : null,
                                icon: const Icon(Icons.menu_book_outlined),
                                label: Text(context.l10n.mealPlanChooseRecipe),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppDimens.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
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
                onPressed: _isAdding || readOnly ? null : _addDish,
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _DishSource { ai, recipe }

/// Ghép món của menu AI vào dish của slot theo tên công thức (BE lưu
/// `recipe_name = mealName`), mỗi món menu chỉ dùng một lần. Dish đã bị đổi /
/// thêm tay không khớp → không có nhãn vai trò.
Map<String, ComposedMealDish> composeInfoByDish(
  List<MealPlanDish> dishes,
  ComposedMeal? menu,
) {
  if (menu == null) return const <String, ComposedMealDish>{};
  final remaining = List<ComposedMealDish>.of(menu.dishes);
  final result = <String, ComposedMealDish>{};
  for (final dish in dishes) {
    final name = dish.recipe?.recipeName;
    if (name == null) continue;
    final index = remaining.indexWhere((m) => m.name == name);
    if (index < 0) continue;
    result[dish.id] = remaining.removeAt(index);
  }
  return result;
}

class _EditableDishCard extends StatelessWidget {
  const _EditableDishCard({
    super.key,
    required this.dish,
    required this.onDelete,
    required this.onInsights,
    this.onChoose,
    this.composed,
  });

  final MealPlanDish dish;

  /// #201: thông tin vai trò/khẩu phần khi món đến từ AI ghép bữa.
  final ComposedMealDish? composed;
  final VoidCallback? onDelete;
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
    final info = composed;
    final roleText = info == null ? null : dishRoleLabel(context, info.role);
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
              width: 64,
              height: 64,
            ),
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
                if (info != null) ...<Widget>[
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    <String>[
                      if (roleText != null) roleText,
                      context.l10n.mealComposeServingsShort(
                        _formatServings(info.servings),
                      ),
                    ].join(' · '),
                    key: ValueKey<String>('slot-dish-role-${dish.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (minutes != null) ...<Widget>[
                  const SizedBox(height: AppDimens.xs),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          context.l10n.homeRecipeMinutes(minutes),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
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
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
            tooltip: context.l10n.mealplanDeleteDish,
          ),
        ],
      ),
    );
  }
}

/// Nhãn tiếng Việt của vai trò món trong bữa (AI ghép bữa); lạ → `null`.
String? dishRoleLabel(BuildContext context, String? role) {
  final l = context.l10n;
  return switch (role) {
    'STAPLE' => l.mealDishRoleStaple,
    'MAIN' => l.mealDishRoleMain,
    'VEGETABLE' => l.mealDishRoleVegetable,
    'SOUP' => l.mealDishRoleSoup,
    'COMPLETE_MEAL' => l.mealDishRoleCompleteMeal,
    'LIGHT_MEAL' => l.mealDishRoleLightMeal,
    _ => null,
  };
}

String _formatServings(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class _PendingDishCard extends StatelessWidget {
  const _PendingDishCard({
    required this.onDelete,
    required this.onInsights,
    this.onChoose,
  });

  final VoidCallback? onDelete;
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
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Text(
                context.l10n.mealPlanDishUnselected,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (onChoose != null)
              IconButton.filledTonal(
                onPressed: onChoose,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                ),
              ),
            _InsightsButton(onPressed: onInsights),
            IconButton(
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
              tooltip: context.l10n.mealplanDeleteDish,
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
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.auto_awesome_outlined),
        color: AppColors.primary,
        tooltip: context.l10n.planningCandidateTooltip,
      );
}
