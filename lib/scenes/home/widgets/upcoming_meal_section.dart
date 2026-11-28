import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_state_view.dart';
import '../../../widgets/states/view_state.dart';
import '../../cooking/widgets/dish_cooked_dialog.dart';
import '../../cooking/widgets/start_cooking_guard.dart';
import '../../mealplan/domain/meal_plan_slot.dart';
import '../../mealplan/widgets/dish_cooked_badge.dart';
import '../../shell/app_shell_store.dart';
import '../domain/upcoming_meal.dart';
import '../stores/home_store.dart';

/// Khung "Bữa sắp tới" ở Trang chủ: slot gần nhất + danh sách món.
///
/// Bấm món → còn nguyên liệu chưa mua thì popup dẫn sang Đi chợ, không thì
/// vào màn nấu từng bước. Hoàn thành nấu thì BE trừ kho
/// (`POST /cooking/sessions/{id}/complete`).
class UpcomingMealSection extends StatefulWidget {
  const UpcomingMealSection({super.key});

  @override
  State<UpcomingMealSection> createState() => _UpcomingMealSectionState();
}

class _UpcomingMealSectionState extends State<UpcomingMealSection> {
  late final HomeStore _store = Get.find<HomeStore>();
  ReactionDisposer? _tabReaction;

  /// Chặn bấm lặp trong lúc guard đang đọc công thức + danh sách đi chợ.
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _store.load();
    // Thực đơn có thể đổi ở tab khác — quay lại Home thì đọc lại.
    if (Get.isRegistered<AppShellStore>()) {
      final shell = Get.find<AppShellStore>();
      _tabReaction = reaction<int>((_) => shell.selectedIndex, (index) {
        if (index == 0) _store.load();
      });
    }
  }

  @override
  void dispose() {
    _tabReaction?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            context.l10n.homeUpcomingMealTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: AppDimens.sm),
          Observer(builder: (context) {
            final state = _store.upcoming;
            if (state is EmptyState<UpcomingMeal>) {
              return _EmptyUpcoming(onOpenPlan: () => _selectTab(2));
            }
            return AppStateView<UpcomingMeal>(
              state: state,
              onRetry: _store.load,
              successBuilder: (context, meal) => _UpcomingMealCard(
                meal: meal,
                onDishTap: (dish) => _onDishTap(meal, dish),
              ),
            );
          }),
        ],
      );

  /// Popup món chưa mua (dẫn sang Đi chợ) hoặc vào màn nấu — dùng chung
  /// guard với thẻ món trong thực đơn. Hoàn thành nấu thì BE trừ kho.
  Future<void> _onDishTap(UpcomingMeal meal, MealPlanDish dish) async {
    final recipeId = dish.recipe?.recipeId;
    if (recipeId == null || _opening) return;
    _opening = true;
    try {
      // Bữa/món đã nấu xong: chỉ báo, không mở màn nấu.
      if (meal.allCooked && !dish.isCooked) {
        await showDishCookedDialog();
        return;
      }
      await startCookingWithShoppingCheck(
        recipeId,
        mealPlanDishId: dish.id,
        cookedAt: dish.cookedAt,
      );
    } finally {
      _opening = false;
    }
  }

  void _selectTab(int index) {
    if (Get.isRegistered<AppShellStore>()) {
      Get.find<AppShellStore>().selectTab(index);
    }
  }
}

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming({required this.onOpenPlan});

  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) => _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.homeUpcomingEmpty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppDimens.md),
            AppButton(
              label: context.l10n.homeUpcomingOpenPlan,
              icon: Icons.event_note_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: onOpenPlan,
            ),
          ],
        ),
      );
}

class _UpcomingMealCard extends StatelessWidget {
  const _UpcomingMealCard({required this.meal, required this.onDishTap});

  final UpcomingMeal meal;
  final ValueChanged<MealPlanDish> onDishTap;

  @override
  Widget build(BuildContext context) => _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.schedule_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    '${meal.slot.label ?? _mealTimeLabel(context, meal.slot.mealTime)} · '
                    '${_dateLabel(context, meal.slot.slotDate)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (meal.allCooked) ...<Widget>[
                  const SizedBox(width: AppDimens.sm),
                  Flexible(
                    child: DishCookedBadge(
                      key: const ValueKey<String>('home-upcoming-all-cooked'),
                      label: context.l10n.homeUpcomingAllCooked,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            for (final dish in meal.dishes)
              _DishTile(
                dish: dish,
                cooked: meal.allCooked || dish.isCooked,
                onTap: () => onDishTap(dish),
              ),
          ],
        ),
      );

  static String _mealTimeLabel(BuildContext context, String mealTime) =>
      switch (mealTime) {
        'BREAKFAST' => context.l10n.mealPlanBreakfast,
        'LUNCH' => context.l10n.mealPlanLunch,
        'DINNER' => context.l10n.mealPlanDinner,
        'SNACK' => context.l10n.nutritionMealSnack,
        _ => mealTime,
      };

  static String _dateLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return context.l10n.homeUpcomingToday;
    if (diff == 1) return context.l10n.homeUpcomingTomorrow;
    return context.l10n.mealPlanDateShort(date.day, date.month);
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.dish,
    required this.onTap,
    this.cooked = false,
  });

  final MealPlanDish dish;
  final VoidCallback onTap;

  /// Món đã nấu xong — thay mũi tên bằng nhãn "Đã nấu".
  final bool cooked;

  @override
  Widget build(BuildContext context) => ListTile(
        key: Key('home-upcoming-dish-${dish.id}'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
        title: Text(
          dish.recipe?.recipeName ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: cooked
            ? const DishCookedBadge()
            : const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
        onTap: onTap,
      );
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        // Material (không phải màu nền của Container) để ListTile bên trong
        // vẽ được ink splash.
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: child,
          ),
        ),
      );
}
