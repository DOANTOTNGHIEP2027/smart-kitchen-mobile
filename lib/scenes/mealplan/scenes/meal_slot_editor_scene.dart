import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart' show ReactionDisposer, reaction;

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../data/network/api_exception.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../planning/scenes/planning_routes.dart';
import '../../planning/widgets/slot_guest_diner_entry.dart';
import '../domain/meal_composition.dart';
import '../domain/meal_plan_slot.dart';
import '../domain/recipe_check.dart';
import '../../recipe/domain/recipe.dart';
import '../../recipe/scenes/recipe_list_scene.dart';
import '../../recipe/scenes/recipe_routes.dart';
import '../stores/meal_plan_store.dart';
import '../stores/meal_composition_store.dart';
import '../widgets/allergen_conflict_dialog.dart';
import '../widgets/missing_ingredients_prompt.dart';
import '../widgets/meal_composition_panel.dart';
import '../../../app/env_config.dart';
import '../widgets/recipe_cover_image.dart';
import '../widgets/meal_attendance_panel.dart';
import 'meal_plan_routes.dart';
import '../../../widgets/feedback/app_toast.dart';

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
  bool _isFinishing = false;
  ReactionDisposer? _lockedReaction;

  @override
  void initState() {
    super.initState();
    // Server báo bữa đã khoá (409 ERR_PLAN_SLOT_LOCKED): store đã đánh dấu
    // khoá + tải lại plan, màn chỉ cần báo toast.
    final store = Get.find<MealPlanStore>();
    _lockedReaction = reaction<int>((_) => store.slotLockedTick, (_) {
      if (mounted) {
        AppToast.show(context.l10n.mealPlanSlotLockedToast,
            type: AppToastType.error);
      }
    });
  }

  @override
  void dispose() {
    _lockedReaction?.call();
    super.dispose();
  }

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
      // Hỏi cách chọn TRƯỚC khi tạo món trên server: đóng sheet/huỷ ở bất kỳ
      // bước nào cũng không để lại món rỗng (#201 R3).
      final source = await _askDishSource();
      if (!mounted) return;
      switch (source) {
        case _DishSource.ai:
          final dish = await store.addDish(widget.slotId);
          if (!mounted) return;
          if (dish == null) {
            _showActionError(context.l10n.mealPlanAddDishFailed);
            return;
          }
          await _openSuggestions(dish.id);
        case _DishSource.recipe:
          // Món chỉ được tạo sau khi người dùng xác nhận hết các bước.
          await _chooseManual(null);
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

  /// Chọn món từ công thức. [dishId] `null` = thêm món mới; khác null = đổi
  /// công thức của món đang có.
  ///
  /// Thứ tự (#201 R3): chọn công thức → kiểm tra (chỉ đọc) → cảnh báo dị ứng
  /// → tạo/gán món. Huỷ/back ở bất kỳ bước nào: không tạo món mới, món đang có
  /// giữ công thức cũ. Đồ thiếu chỉ đẩy khi bấm "Hoàn thành thêm món".
  Future<void> _chooseManual(String? dishId) async {
    final recipe = await Get.to<Recipe>(
      () =>
          RecipeListScene(onSelect: (value) => Get.back<Recipe>(result: value)),
    );
    if (recipe == null || !mounted) return;
    final store = Get.find<MealPlanStore>();
    final l10n = context.l10n;
    if (store.hasRecipeInSlot(widget.slotId, recipe.id, exceptDishId: dishId)) {
      _showActionError(l10n.mealPlanDuplicateRecipe);
      return;
    }

    // 1. Kiểm tra trước — server cũ chưa có endpoint ⇒ `null`, bỏ qua bước.
    RecipeCheckResult? check;
    try {
      check = await store.recipeCheck(widget.slotId, recipe.id);
    } on ApiException catch (e) {
      _showActionError(
          apiErrorMessage(l10n, e, fallback: l10n.mealplanUnableToChoose));
      return;
    }
    if (!mounted) return;

    // 2. Có người ăn bữa này dị ứng → cảnh báo đỏ, Huỷ = dừng.
    if (check != null && check.allergenConflicts.isNotEmpty) {
      final proceed = await showAllergenConflictDialog(
        context,
        conflicts: check.allergenConflicts,
        verified: check.allergenVerified,
      );
      if (!proceed || !mounted) return;
    }

    // 3. Tạo món (nếu thêm mới) rồi gán công thức.
    var targetId = dishId;
    MealPlanDish? created;
    if (targetId == null) {
      created = await store.addDish(widget.slotId);
      if (created == null) {
        _showActionError(l10n.mealPlanAddDishFailed);
        return;
      }
      targetId = created.id;
    }
    final ok = await store.assignManual(
      widget.slotId,
      targetId,
      recipe.id,
      recipe.name,
    );
    if (!ok) {
      // Gán lỗi: xoá món vừa tạo để không để lại món rỗng.
      if (created != null) {
        await store.removeDish(widget.slotId, created.id,
            discardCreated: true);
      }
      _showActionError(l10n.mealplanUnableToChoose);
    }
  }

  Future<void> _finish(MealPlanSlot slot) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      final done = await finishSlotShopping(
        context,
        slotDate: slot.slotDate,
        mealTime: slot.mealTime,
        dishes: slot.dishes,
      );
      if (done && mounted) Get.back<void>();
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  void _showActionError(String message) {
    // Bữa vừa bị server khoá: toast "bữa đã khoá" đã hiện, không đè bằng
    // lỗi chung.
    if (Get.find<MealPlanStore>().isSlotLocked(widget.slotId)) return;
    AppToast.show(message, type: AppToastType.error);
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
                          // Bữa đã khoá: không mở gợi ý AI cho món.
                          onInsights: store.isSlotLocked(widget.slotId)
                              ? null
                              : () => _openCandidates(dish),
                          onOpen: dish.recipe == null
                              ? null
                              : () => Get.toNamed<void>(
                                    recipeDetailPath(
                                      dish.recipe!.recipeId,
                                      viewOnly: true,
                                    ),
                                  ),
                          onChoose: readOnly
                              ? null
                              : () => _openSuggestions(dish.id),
                        ),
                        if (!readOnly)
                          Wrap(
                            spacing: 8,
                            children: [
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
              if (!readOnly && slot != null) ...<Widget>[
                const SizedBox(height: AppDimens.sm),
                OutlinedButton.icon(
                  key: const ValueKey<String>('slot-finish-adding'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    ),
                  ),
                  icon: _isFinishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    context.l10n.mealPlanFinishAdding,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: _isFinishing ? null : () => _finish(slot),
                ),
              ],
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
    this.onOpen,
    this.composed,
  });

  final MealPlanDish dish;

  /// #201: thông tin vai trò/khẩu phần khi món đến từ AI ghép bữa.
  final ComposedMealDish? composed;
  final VoidCallback? onDelete;
  final VoidCallback? onInsights;
  final VoidCallback? onChoose;

  /// Bấm thân thẻ → chi tiết món (chỉ xem).
  final VoidCallback? onOpen;

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
      child: InkWell(
        key: ValueKey<String>('slot-dish-open-${dish.id}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
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
  final VoidCallback? onInsights;
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

  final VoidCallback? onPressed;

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
