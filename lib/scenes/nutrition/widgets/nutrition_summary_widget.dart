import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_colors_extension.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/view_state.dart';
import '../domain/nutrition_models.dart';
import '../stores/nutrition_store.dart';
import 'daily_breakdown_list.dart';
import 'diet_compliance_badge.dart';
import 'macro_doughnut_chart.dart';
import 'weekly_calorie_bar_chart.dart';
import 'weekly_calorie_overview_card.dart';

/// Widget tổng hợp dinh dưỡng tuần (nutrition-summary-widget.md §1, §10).
///
/// [showTitle] = false khi màn chứa đã có tiêu đề trên AppBar.
class NutritionSummaryWidget extends StatelessWidget {
  const NutritionSummaryWidget({
    super.key,
    required this.store,
    this.showTitle = true,
    this.onSetTarget,
    this.onOpenMealLog,
  });

  final NutritionStore store;
  final bool showTitle;

  /// Mở màn đặt mục tiêu; widget gọi `store.refreshTarget()` khi quay về.
  final Future<void> Function()? onSetTarget;
  final VoidCallback? onOpenMealLog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey<String>('nutrition-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showTitle) ...<Widget>[
          Text(
            l10n.nutritionWeekThisTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppDimens.sm),
        ],
        Observer(
          builder: (_) => switch (store.state) {
            LoadingState<NutritionWeekSummary>() => const NutritionSkeleton(),
            ErrorState<NutritionWeekSummary>(:final error) => SizedBox(
                height: 220,
                child: AppErrorView(
                  message: apiErrorMessage(l10n, error,
                      fallback: l10n.nutritionLoadFailed),
                  onRetry: store.retry,
                ),
              ),
            EmptyState<NutritionWeekSummary>() => SizedBox(
                height: 180,
                child: AppEmptyView(message: l10n.nutritionEmpty),
              ),
            SuccessState<NutritionWeekSummary>(:final data) =>
              _content(context, data),
          },
        ),
        if (onOpenMealLog != null)
          TextButton(
            key: const ValueKey<String>('nutrition-open-meal-log'),
            onPressed: onOpenMealLog,
            child: Text(l10n.nutritionOpenMealLog),
          ),
      ],
    );
  }

  Widget _content(BuildContext context, NutritionWeekSummary data) {
    final setTarget = onSetTarget;
    final noTarget =
        data.targetDailyCalories == null || data.targetDailyCalories! <= 0;
    const gap = SizedBox(height: AppDimens.sm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: DietComplianceBadge(
            score: data.complianceScore,
            level: data.level,
            onSetTarget: noTarget && setTarget != null
                ? () async {
                    await setTarget();
                    await store.refreshTarget();
                  }
                : null,
          ),
        ),
        gap,
        AppCard(child: WeeklyCalorieOverviewCard(summary: data)),
        gap,
        AppCard(child: WeeklyCalorieBarChart(summary: data)),
        gap,
        AppCard(child: MacroDoughnutChart(summary: data)),
        gap,
        AppCard(child: DailyBreakdownList(summary: data)),
      ],
    );
  }
}

/// Skeleton tĩnh cho lần tải đầu (§9.6, theo `history_skeleton.dart`).
class NutritionSkeleton extends StatelessWidget {
  const NutritionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.surfaceSubtle;
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: AppDimens.sm),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        );
    return Semantics(
      label: context.l10n.commonLoading,
      child: Column(
        key: const ValueKey<String>('nutrition-skeleton'),
        children: <Widget>[block(64), block(72), block(180), block(150)],
      ),
    );
  }
}
