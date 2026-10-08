import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

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
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? AppEmptyView(message: context.l10n.mealLogEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDimens.md),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return MealLogCard(
                              entry: entry,
                              onTap: () => _openConfirmForEntry(entry),
                              onRetry: entry.status == MealEntryStatus.failed
                                  ? () => _store.retrySubmit(entry.id)
                                  : null,
                              onDelete:
                                  entry.status == MealEntryStatus.failed
                                      ? () => _store.discardFailed(entry.id)
                                      : null,
                            );
                          },
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