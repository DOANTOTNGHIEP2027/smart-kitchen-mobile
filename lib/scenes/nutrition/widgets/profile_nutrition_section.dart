import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../routing/app_routes.dart';
import '../../../stores/session_store.dart';
import '../../shell/app_shell_store.dart';
import '../stores/nutrition_store.dart';
import 'nutrition_summary_widget.dart';

/// Thẻ dinh dưỡng tuần hiện tại trên Profile (nutrition-summary-widget.md §8.2).
///
/// ProfileScreen nằm trong IndexedStack của shell và được dựng ngay khi mở
/// app, nên tải dữ liệu khi tab Cá nhân ĐƯỢC CHỌN (review v3 HIGH-1); mở qua
/// route riêng (không có AppShellStore) thì tải một lần.
class ProfileNutritionSection extends StatefulWidget {
  const ProfileNutritionSection({super.key});

  static const int profileTabIndex = 4;
  static const int mealPlanTabIndex = 2;

  @override
  State<ProfileNutritionSection> createState() =>
      _ProfileNutritionSectionState();
}

class _ProfileNutritionSectionState extends State<ProfileNutritionSection> {
  late final NutritionStore store =
      Get.find<NutritionStore>(tag: NutritionStore.profileTag);
  ReactionDisposer? _tabDisposer;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppShellStore>()) {
      final shell = Get.find<AppShellStore>();
      _tabDisposer = reaction<bool>(
        (_) => shell.selectedIndex == ProfileNutritionSection.profileTabIndex,
        (selected) {
          if (selected && _hasHousehold) store.loadCurrentWeek();
        },
        fireImmediately: true,
      );
    } else if (_hasHousehold) {
      store.loadCurrentWeek();
    }
  }

  bool get _hasHousehold => Get.find<SessionStore>().householdId != null;

  @override
  void dispose() {
    _tabDisposer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionStore>();
    return Observer(builder: (_) {
      if (session.householdId == null) return const SizedBox.shrink();
      return NutritionSummaryWidget(
        store: store,
        compact: true,
        onSetTarget: () async => Get.toNamed<void>(AppRoutes.profileHealth),
        onViewMealPlan: Get.isRegistered<AppShellStore>()
            ? () => Get.find<AppShellStore>()
                .selectTab(ProfileNutritionSection.mealPlanTabIndex)
            : null,
      );
    });
  }
}
