import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../domain/meal_plan_slot.dart';
import '../stores/meal_plan_store.dart';
import '../widgets/meal_card.dart';

/// Lưới lịch bữa ăn tuần (FE-7 §12, 7 ngày × 3 bữa).
///
/// 4 trạng thái: loading / empty (household không có plan) / error / success.
class WeeklyMealPlanScene extends StatefulWidget {
  const WeeklyMealPlanScene({super.key});

  @override
  State<WeeklyMealPlanScene> createState() => _WeeklyMealPlanSceneState();
}

class _WeeklyMealPlanSceneState extends State<WeeklyMealPlanScene> {
  @override
  void initState() {
    super.initState();
    Get.find<MealPlanStore>().loadWeekPlan();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<MealPlanStore>();
    final session = Get.find<SessionStore>();
    return AppScaffold(
      title: 'Kế hoạch tuần',
      body: Observer(
        builder: (_) {
          if (session.householdId == null) {
            return const AppEmptyView(
              icon: Icons.home_outlined,
              message: 'Bạn chưa thuộc Nhà nào.',
            );
          }
          switch (store.status) {
            case MealPlanLoadStatus.loading:
              return const AppLoadingView();
            case MealPlanLoadStatus.error:
              return AppErrorView(
                message: store.loadError?.message ?? 'Không tải được kế hoạch.',
                onRetry: () => store.loadWeekPlan(),
              );
            case MealPlanLoadStatus.ready:
              return _WeekGrid(store: store);
          }
        },
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.store});

  final MealPlanStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Week navigation.
        Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => store.navigateWeek(-1),
              ),
              Observer(
                builder: (_) => Text(
                  _weekLabel(store.currentWeekStart),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => store.navigateWeek(1),
              ),
            ],
          ),
        ),
        // Pending vote banner.
        Observer(
          builder: (_) => store.pendingVoteCount > 0
              ? Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppDimens.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.md, vertical: AppDimens.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.how_to_vote,
                          color: AppColors.secondary, size: 20),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: Text(
                          '${store.pendingVoteCount} phiên vote đang mở',
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Grid header (3 cột bữa).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
          child: Row(
            children: const <String>['Sáng', 'Trưa', 'Tối']
                .map((String label) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimens.sm),
                        child: Text(label,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ),
        // 7 rows × 3 cols grid.
        Expanded(
          child: Observer(
            builder: (_) {
              final keys = store.currentWeekSlotKeys;
              return ListView.builder(
                itemCount: 7,
                itemBuilder: (_, int rowIdx) {
                  final date = store.currentWeekStart
                      .add(Duration(days: rowIdx));
                  return Row(
                    children: List<Widget>.generate(3, (int colIdx) {
                      final key = keys[rowIdx * 3 + colIdx];
                      return Expanded(
                        child: Observer(
                          // Guard §15.1 — mỗi ô đọc trực tiếp `slots[key]`,
                          // rebuild chỉ ô này khi thay đổi.
                          builder: (_) => MealCard(
                            slot: store.slots[key] ??
                                MealPlanSlot(
                                  id: '',
                                  slotDate: date,
                                  mealTime: const <String>[
                                    'BREAKFAST',
                                    'LUNCH',
                                    'DINNER'
                                  ][colIdx],
                                  dishes: const <MealPlanDish>[],
                                ),
                            slotKey: key,
                            store: store,
                            onTapEmptySlot: (String slotId) => Get.snackbar(
                              'Chưa có món',
                              'Bấm "+ Thêm món" để thêm món vào bữa này.',
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static String _weekLabel(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return 'Tuần ${monday.day}/${monday.month} – ${sunday.day}/${sunday.month}';
  }
}
