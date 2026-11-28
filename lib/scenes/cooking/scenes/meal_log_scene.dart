import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../insights/scenes/insights_routes.dart';
import '../../recap/scenes/recap_routes.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_state_view.dart';
import '../stores/meal_log_store.dart';
import '../domain/meal_log_entry.dart';
import '../domain/meal_type.dart';
import '../widgets/calorie_confirm_sheet.dart';
import '../widgets/calorie_goal_widget.dart';
import '../widgets/meal_log_bottom_sheet.dart';
import '../widgets/meal_log_card.dart';
import '../widgets/meal_type_label.dart';

/// Màn hình nhật ký bữa ăn (meal-log-screen §11.1 MealLogScene).
class MealLogScene extends StatefulWidget {
  const MealLogScene({super.key});

  @override
  State<MealLogScene> createState() => _MealLogSceneState();
}

class _MealLogSceneState extends State<MealLogScene> {
  late final MealLogStore _store;
  late ReactionDisposer _autoConfirmReaction;

  @override
  void initState() {
    super.initState();
    _store = Get.find<MealLogStore>();
    // Guard #6: clear NGAY trước khi mở sheet — tránh trigger lại nếu rebuild.
    _autoConfirmReaction = reaction<MealLogEntry?>(
      (_) => _store.autoConfirmTarget,
      (MealLogEntry? entry) {
        if (entry == null) return;
        _store.clearAutoConfirmTarget();
        Get.bottomSheet(
          CalorieConfirmSheet(entry: entry, store: _store),
          isScrollControlled: true,
        );
      },
    );
    unawaited(_store.loadToday());
  }

  @override
  void dispose() {
    _autoConfirmReaction();
    super.dispose();
  }

  void _openLogSheet() {
    Get.bottomSheet(
      MealLogBottomSheet(
        onSubmit: ({
          required MealType mealType,
          String? userDescription,
          Uint8List? imageBytes,
        }) =>
            _store.submitLog(
          mealType: mealType,
          userDescription: userDescription,
          imageBytes: imageBytes,
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openConfirmForEntry(MealLogEntry entry) {
    Get.bottomSheet(
      CalorieConfirmSheet(entry: entry, store: _store),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.mealLogTitle,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.insights),
          tooltip: context.l10n.insightsHistoryTooltip,
          onPressed: () => Get.toNamed(InsightsRoutes.history),
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: context.l10n.recapTitle,
          onPressed: () => Get.toNamed(RecapRoutes.root),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _openLogSheet,
        child: const Icon(Icons.add),
      ),
      body: Observer(builder: (_) {
        return AppStateView<List<MealLogEntry>>(
          state: _store.todayLogsState,
          onRetry: () => _store.loadToday(),
          emptyMessage: context.l10n.mealLogEmpty,
          successBuilder: (context, entries) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Observer(
                  builder: (_) => CalorieGoalWidget(
                    remainingKcal: _store.calorieGoalRemaining,
                    targetKcal: _store.targetDailyCalories,
                    consumedKcal: _store.consumedCaloriesToday,
                    proteinG: _store.consumedProteinToday,
                    carbsG: _store.consumedCarbsToday,
                    fatG: _store.consumedFatToday,
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? AppEmptyView(message: context.l10n.mealLogEmpty)
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDimens.md),
                          children: <Widget>[
                            // Nhóm theo bữa (sáng → trưa → tối → ăn vặt), mỗi
                            // nhóm giữ thứ tự mới nhất trước như store trả.
                            for (final group in groupMealLogs(entries)) ...<Widget>[
                              _MealSectionHeader(
                                type: group.type,
                                entries: group.entries,
                              ),
                              for (final entry in group.entries)
                                MealLogCard(
                                  entry: entry,
                                  onTap: () => _openConfirmForEntry(entry),
                                  onRetry: entry.status == MealEntryStatus.failed
                                      ? () => _store.retrySubmit(entry.id)
                                      : null,
                                  onDelete:
                                      entry.status == MealEntryStatus.failed
                                          ? () => _store.discardFailed(entry.id)
                                          : null,
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

/// Món của 1 bữa trong ngày.
class MealLogGroup {
  const MealLogGroup(this.type, this.entries);

  final MealType type;
  final List<MealLogEntry> entries;
}

/// Chia nhật ký theo bữa ([MealLogEntry.mealGroup]), bỏ bữa không có món.
List<MealLogGroup> groupMealLogs(List<MealLogEntry> entries) => <MealLogGroup>[
      for (final type in MealType.values)
        if (entries.any((e) => e.mealGroup == type))
          MealLogGroup(
              type, entries.where((e) => e.mealGroup == type).toList()),
    ];

class _MealSectionHeader extends StatelessWidget {
  const _MealSectionHeader({required this.type, required this.entries});

  final MealType type;
  final List<MealLogEntry> entries;

  static IconData _icon(MealType t) => switch (t) {
        MealType.breakfast => Icons.wb_twilight_rounded,
        MealType.lunch => Icons.wb_sunny_rounded,
        MealType.dinner => Icons.nights_stay_rounded,
        MealType.snack => Icons.cookie_outlined,
      };

  static Color _color(MealType t) => switch (t) {
        MealType.breakfast => AppColors.warning,
        MealType.lunch => AppColors.primary,
        MealType.dinner => AppColors.info,
        MealType.snack => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = _color(type);
    // Cùng luật với tổng ngày: chỉ món đã lưu và đã xác nhận / không cần xác nhận.
    final kcal = entries
        .where((e) =>
            e.status == MealEntryStatus.saved && e.countsTowardDailyTotal)
        .fold<double>(0, (sum, e) => sum + e.caloriesKcal!);
    return Padding(
      key: ValueKey<String>('meal-log-section-${type.name}'),
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, AppDimens.sm, AppDimens.md, AppDimens.xs),
      child: Row(
        children: <Widget>[
          Icon(_icon(type), size: 18, color: color),
          const SizedBox(width: AppDimens.xs),
          Expanded(
            child: Text(
              mealTypeLabel(l10n, type),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Text(
            l10n.mealLogSectionSummary(entries.length, kcal.round()),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
