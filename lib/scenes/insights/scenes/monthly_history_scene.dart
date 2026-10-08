import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/view_state.dart';
import '../domain/streak_summary.dart';
import '../domain/week_quick_stat.dart';
import '../stores/history_store.dart';
import '../widgets/adherence_weekly_bar_chart.dart';
import '../widgets/history_skeleton.dart';
import '../widgets/macro_stacked_area_chart.dart';
import '../widgets/nutrition_trend_chart.dart';
import '../widgets/streak_badge.dart';

/// Màn hình lịch sử/xu hướng dinh dưỡng hàng tháng — 3 tab Calo/Macro/Tuân Thủ
/// (nutrition-trend-history.md §9, issue #87).
class MonthlyHistoryScene extends StatefulWidget {
  const MonthlyHistoryScene({super.key});

  @override
  State<MonthlyHistoryScene> createState() => _MonthlyHistorySceneState();
}

class _MonthlyHistorySceneState extends State<MonthlyHistoryScene>
    with SingleTickerProviderStateMixin {
  late final HistoryStore _store;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _store = Get.find<HistoryStore>();
    _tabController = TabController(length: 3, vsync: this);
    _store.loadMonth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Observer(
          builder: (_) => Text(
            context.l10n.insightsMonthLabel(
              _store.monthCursor.month,
              _store.monthCursor.year,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _store.previousMonth,
        ),
        actions: [
          Observer(
            builder: (_) => IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _store.isCurrentMonth ? null : _store.nextMonth,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: context.l10n.insightsTitleCalorie),
                Tab(text: context.l10n.insightsTitleMacro),
                Tab(text: context.l10n.insightsTitleAdherence),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CaloTab(store: _store),
                  _MacroTab(store: _store),
                  _AdherenceTab(store: _store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaloTab extends StatelessWidget {
  const _CaloTab({required this.store});
  final HistoryStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      switch (store.dailyNutritionState) {
        case LoadingState():
          return const HistorySkeleton();
        case ErrorState(:final error):
          return AppErrorView(message: error.message, onRetry: store.loadMonth);
        case SuccessState(:final data):
          if (data.every((p) => !p.hasData)) {
            return Center(child: Text(context.l10n.insightsEmptyDiary));
          }
          return Column(
            children: [
              if (store.weekQuickStat != null)
                _WeekQuickStatPill(stat: store.weekQuickStat!),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                      AppDimens.md, 0, AppDimens.md, AppDimens.sm),
                  child: NutritionTrendChart(
                    data: data,
                    targetDailyCalories: store.targetDailyCalories,
                  ),
                ),
              ),
              if (store.targetDailyCalories == null)
                TextButton(
                  onPressed: () => Get.toNamed('/profile/health'),
                  child: Text(context.l10n.insightsSetCalorieGoal),
                ),
            ],
          );
        default:
          return const SizedBox.shrink();
      }
    });
  }
}

class _MacroTab extends StatelessWidget {
  const _MacroTab({required this.store});
  final HistoryStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      switch (store.dailyNutritionState) {
        case LoadingState():
          return const HistorySkeleton();
        case ErrorState(:final error):
          return AppErrorView(message: error.message, onRetry: store.loadMonth);
        case SuccessState(:final data):
          if (data.every((p) => !p.hasData)) {
            return Center(child: Text(context.l10n.insightsEmptyDiary));
          }
          return Container(
            margin: const EdgeInsets.fromLTRB(
                AppDimens.md, AppDimens.md, AppDimens.md, AppDimens.sm),
            child: MacroStackedAreaChart(data: data),
          );
        default:
          return const SizedBox.shrink();
      }
    });
  }
}

class _AdherenceTab extends StatelessWidget {
  const _AdherenceTab({required this.store});
  final HistoryStore store;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      switch (store.adherenceState) {
        case LoadingState():
          return const HistorySkeleton();
        case ErrorState(:final error):
          return AppErrorView(message: error.message, onRetry: store.loadMonth);
        case SuccessState(:final data):
          final streak = store.streak ??
              const StreakSummary(currentStreak: 0, bestStreak: 0);
          final isEmpty = data.every((p) => p.adherencePercent == null) &&
              streak.currentStreak == 0 &&
              streak.bestStreak == 0;
          if (isEmpty) {
            return Center(child: Text(context.l10n.insightsEmptyAdherence));
          }
          return Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                      AppDimens.md, AppDimens.md, AppDimens.md, AppDimens.sm),
                  child: AdherenceWeeklyBarChart(data: data),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.lg),
                child: StreakBadge(streak: streak),
              ),
            ],
          );
        default:
          return const SizedBox.shrink();
      }
    });
  }
}

/// Stat pill "7 ngày gần nhất" — best-effort, ẩn khi null.
class _WeekQuickStatPill extends StatelessWidget {
  const _WeekQuickStatPill({required this.stat});
  final WeekQuickStat stat;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (stat.avgCaloriesKcal != null) {
      parts.add(context.l10n.insightsAvgCalories(stat.avgCaloriesKcal!.round()));
    }
    if (stat.loggedCount != null) {
      parts.add(context.l10n.insightsLoggedCount(stat.loggedCount!));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.sm),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, color: AppColors.primaryDark),
            const SizedBox(width: AppDimens.sm),
            Text(
              '${context.l10n.insightsLast7Days}: ${parts.join(' · ')}',
              style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }
}