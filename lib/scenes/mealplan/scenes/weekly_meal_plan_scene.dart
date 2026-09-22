import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../stores/session_store.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../domain/meal_plan_slot.dart';
import '../stores/meal_plan_store.dart';
import '../widgets/recipe_cover_image.dart';
import 'meal_slot_editor_scene.dart';

/// Lưới lịch bữa ăn tuần (FE-7 §12, 7 ngày × 3 bữa).
///
/// 4 trạng thái: loading / empty (household không có plan) / error / success.
class WeeklyMealPlanScene extends StatefulWidget {
  const WeeklyMealPlanScene({super.key});

  @override
  State<WeeklyMealPlanScene> createState() => _WeeklyMealPlanSceneState();
}

class _WeeklyMealPlanSceneState extends State<WeeklyMealPlanScene> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    Get.find<MealPlanStore>().loadWeekPlan();
  }

  Future<void> _navigateWeek(MealPlanStore store, int direction) async {
    final didNavigate = await store.navigateWeek(direction);
    if (didNavigate && mounted) {
      setState(() => _selectedDate = store.currentWeekStart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<MealPlanStore>();
    final session = Get.find<SessionStore>();
    return AppScaffold(
      title: context.l10n.mealPlanTitle,
      body: Observer(
        builder: (_) {
          if (session.householdId == null) {
            return AppEmptyView(
              icon: Icons.home_outlined,
              message: context.l10n.mealPlanNoHousehold,
            );
          }
          switch (store.status) {
            case MealPlanLoadStatus.loading:
              return const AppLoadingView();
            case MealPlanLoadStatus.error:
              return AppErrorView(
                message: store.loadError?.message ??
                    context.l10n.mealPlanLoadFailed,
                onRetry: () => store.loadWeekPlan(),
              );
            case MealPlanLoadStatus.ready:
              final selectedDate = _selectedDate;
              final dateInCurrentWeek = selectedDate != null &&
                  selectedDate.difference(store.currentWeekStart).inDays >= 0 &&
                  selectedDate.difference(store.currentWeekStart).inDays < 7;
              final effectiveSelectedDate = dateInCurrentWeek
                  ? selectedDate
                  : store.currentWeekStart;
              return _WeekCalendar(
                store: store,
                selectedDate: effectiveSelectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
                onNavigateWeek: (direction) => _navigateWeek(store, direction),
              );
          }
        },
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({
    required this.store,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onNavigateWeek,
  });

  final MealPlanStore store;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Future<void> Function(int direction) onNavigateWeek;

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) => ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, AppDimens.md, AppDimens.md, AppDimens.xl),
      children: <Widget>[
        _WeekNavigation(
          label: _weekLabel(context, store.currentWeekStart),
          onPrevious: () => onNavigateWeek(-1),
          onNext: () => onNavigateWeek(1),
        ),
        const SizedBox(height: AppDimens.md),
        if (store.pendingVoteCount > 0) _PendingVoteBanner(count: store.pendingVoteCount),
        if (store.pendingVoteCount > 0) const SizedBox(height: AppDimens.md),
        Container(
          padding: const EdgeInsets.all(AppDimens.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.32),
              width: 1.2,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8,
            ),
            itemCount: 7,
            itemBuilder: (_, index) {
              final date = store.currentWeekStart.add(Duration(days: index));
              return _CalendarDay(
                date: date,
                label: _weekdayLabels(context)[index],
                selected: _isSameDay(date, selectedDate),
                hasDishes: _hasDishes(store, date),
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ),
        const SizedBox(height: AppDimens.xl),
        Text(
          context.l10n.mealPlanDaySchedule(
            selectedDate.day,
            selectedDate.month,
          ),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppDimens.sm),
        ...const <_MealPeriod>[
          _MealPeriod('BREAKFAST', Icons.wb_sunny_outlined),
          _MealPeriod('LUNCH', Icons.light_mode_outlined),
          _MealPeriod('DINNER', Icons.nightlight_round),
        ].map(
          (period) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: _MealScheduleCard(
              store: store,
              date: selectedDate,
              period: period,
            ),
          ),
        ),
      ],
        ),
      );

  static bool _hasDishes(MealPlanStore store, DateTime date) =>
      const <String>['BREAKFAST', 'LUNCH', 'DINNER'].any(
        (meal) => store.slots[_slotKey(date, meal)]?.dishes.isNotEmpty ?? false,
      );

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _slotKey(DateTime date, String meal) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_$meal';

  static List<String> _weekdayLabels(BuildContext context) => <String>[
        context.l10n.mealPlanWeekdayMonday,
        context.l10n.mealPlanWeekdayTuesday,
        context.l10n.mealPlanWeekdayWednesday,
        context.l10n.mealPlanWeekdayThursday,
        context.l10n.mealPlanWeekdayFriday,
        context.l10n.mealPlanWeekdaySaturday,
        context.l10n.mealPlanWeekdaySunday,
      ];

  static String _weekLabel(BuildContext context, DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return context.l10n.mealPlanWeekRange(
      monday.day,
      monday.month,
      sunday.day,
      sunday.month,
    );
  }
}

class _WeekNavigation extends StatelessWidget {
  const _WeekNavigation({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.32),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevious),
            Text(label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
          ],
        ),
      );
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.label,
    required this.selected,
    required this.hasDishes,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool selected;
  final bool hasDishes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? AppColors.textOnPrimary.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${date.day}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: hasDishes
                        ? (selected ? AppColors.textOnPrimary : AppColors.primary)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PendingVoteBanner extends StatelessWidget {
  const _PendingVoteBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.sm),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.how_to_vote_outlined,
                color: AppColors.secondary, size: 20),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Text(
                context.l10n.mealPlanOpenVotes(count),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _MealPeriod {
  const _MealPeriod(this.wireValue, this.icon);

  final String wireValue;
  final IconData icon;

  String labelOf(BuildContext context) => switch (wireValue) {
        'BREAKFAST' => context.l10n.mealPlanBreakfast,
        'LUNCH' => context.l10n.mealPlanLunch,
        'DINNER' => context.l10n.mealPlanDinner,
        _ => wireValue,
      };
}

class _MealScheduleCard extends StatelessWidget {
  const _MealScheduleCard({
    required this.store,
    required this.date,
    required this.period,
  });

  final MealPlanStore store;
  final DateTime date;
  final _MealPeriod period;

  @override
  Widget build(BuildContext context) {
    final slot = store.slots[_WeekCalendar._slotKey(date, period.wireValue)];
    final slotId = slot?.id;
    final canEdit = slotId?.isNotEmpty == true;
    final periodLabel = period.labelOf(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: canEdit
            ? () => Get.to<void>(
                  () => MealSlotEditorScene(
                    slotId: slotId!,
                    mealLabel: periodLabel,
                    dateLabel:
                        context.l10n.mealPlanDateShort(date.day, date.month),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.32),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(period.icon, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: AppDimens.sm),
                  Text(periodLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: canEdit
                          ? AppColors.textSecondary
                          : AppColors.textDisabled),
                ],
              ),
              const SizedBox(height: AppDimens.sm),
              if (slot == null || slot.dishes.isEmpty)
                Text(context.l10n.mealPlanTapToAdd,
                    style: Theme.of(context).textTheme.bodyMedium)
              else
                ...slot.dishes.map(
                  (dish) => _ScheduledDishCard(
                    dish: dish,
                    onDelete: () => store.removeDish(slotId!, dish.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledDishCard extends StatelessWidget {
  const _ScheduledDishCard({required this.dish, required this.onDelete});

  final MealPlanDish dish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final recipe = dish.recipe;
    if (recipe == null) {
      return Text(
        context.l10n.mealPlanSelectingDish,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final minutes = RecipeCoverImage.demoPrepTimeMinutes(recipe.recipeId);
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.xs),
      child: Row(
        children: <Widget>[
          RecipeCoverImage(
            recipeId: recipe.recipeId,
            recipeName: recipe.recipeName,
            width: 58,
            height: 58,
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(recipe.recipeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                if (minutes != null)
                  Text(context.l10n.homeRecipeMinutes(minutes),
                      style: Theme.of(context).textTheme.bodySmall),
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
