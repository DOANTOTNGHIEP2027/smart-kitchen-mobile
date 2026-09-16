import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../stores/session_store.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/app_empty_view.dart';
import '../cooking/scenes/cooking_routes.dart' as cooking_routes;
import '../inventory/scenes/inventory_list_binding.dart';
import '../inventory/scenes/inventory_list_scene.dart';
import '../mealplan/scenes/meal_plan_routes.dart' show WeeklyMealPlanBinding;
import '../mealplan/scenes/weekly_meal_plan_scene.dart';
import '../profile/profile_family_bindings.dart';
import '../profile/profile_screen.dart';
import 'app_shell_store.dart';

/// Khung bottom-nav (fe-app-shell.md §12).
///
/// 5 tab: Home (placeholder), Kho (FE-5), Thực đơn (FE-7), Đi chợ (chưa làm
/// theo §6.1 D-07), Cá nhân (FE-3). Mỗi tab render feature scene thật —
/// không còn placeholder "Coming soon" cho các feature đã ship.
///
/// **Lưu ý binding (D7):** GetPage binding chỉ chạy khi route được navigate,
/// không chạy khi widget render trực tiếp trong shell. Shell phải tự call
/// `binding.dependencies()` 1 lần trước khi render scene tương ứng, để store
/// và các dependency được đăng ký, tránh `Get.find<S>()` ném "not found".
class AppShellScene extends StatelessWidget {
  const AppShellScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<AppShellStore>();
    final tabs = _tabsOf(context);

    // Đăng ký binding cho các tab có feature thật — idempotent (bindings tự
    // check Get.isRegistered trước khi put). Chạy ở đây thay vì trong
    // GetPage vì shell không đi qua route của feature.
    _ensureBindings();

    return Observer(
      builder: (_) {
        final index = store.selectedIndex;
        // Mỗi tab là Scaffold riêng — không dùng AppScaffold cha để tránh 2
        // AppBar chồng lên nhau (feature scene đã có AppBar của mình).
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: <Widget>[
              _HomeTab(tabs[0]),
              const InventoryListScene(),
              const WeeklyMealPlanScene(),
              _PlaceholderTab(icon: tabs[3].icon),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            selectedIndex: index,
            onDestinationSelected: store.selectTab,
            destinations: tabs
                .map((tab) => AppBottomNavDestination(
                      icon: tab.icon,
                      activeIcon: tab.activeIcon,
                      label: tab.label,
                    ))
                .toList(growable: false),
          ),
        );
      },
    );
  }

  List<_ShellTab> _tabsOf(BuildContext context) => <_ShellTab>[
        _ShellTab(context.l10n.navHome, Icons.home_outlined, Icons.home_rounded),
        _ShellTab(context.l10n.navInventory, Icons.kitchen_outlined, Icons.kitchen_rounded),
        _ShellTab(context.l10n.navPlanning, Icons.event_note_outlined, Icons.event_rounded),
        _ShellTab(context.l10n.navShopping, Icons.shopping_cart_outlined, Icons.shopping_cart_rounded),
        _ShellTab(context.l10n.navProfile, Icons.person_outline, Icons.person_outline),
      ];

  static void _ensureBindings() {
    InventoryListBinding().dependencies();
    WeeklyMealPlanBinding().dependencies();
    ProfileBinding().dependencies();
  }
}

/// Tab Home — tạm thời là trung tâm điều hướng nhanh tới các flow đã ship
/// (cooking session, inventory, meal plan) thay vì dashboard thật. Dashboard
/// widget (nutrition recap, weekly recap) chưa làm — nằm ngoài scope MVP.
class _HomeTab extends StatelessWidget {
  const _HomeTab(this.tab);
  final _ShellTab tab;

  @override
  Widget build(BuildContext context) {
    final session = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>()
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(tab.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (session?.provider == 'GUEST') ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.l10n.guestProfileBanner),
                    const SizedBox(height: 12),
                    AppButton(
                      label: context.l10n.completeProfile,
                      onPressed: () => Get.toNamed(AppRoutes.profileUpgrade),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Bắt đầu nấu — entry tới flow FE-6.
          ListTile(
            leading: const Icon(Icons.restaurant_menu_rounded),
            title: const Text('Bắt đầu buổi nấu'),
            subtitle: const Text('Chọn công thức → các bước → Hoàn tất nấu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.toNamed(cooking_routes.CookingRoutes.session),
          ),
          // Tới Kho.
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Kho thực phẩm'),
            subtitle: const Text('Thêm/sửa item, nhận cảnh báo hết hạn'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.find<AppShellStore>().selectTab(1),
          ),
          // Tới Kế hoạch.
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Kế hoạch bữa ăn'),
            subtitle: const Text('Lịch tuần + vote món'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.find<AppShellStore>().selectTab(2),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navShopping)),
      body: AppEmptyView(message: context.l10n.comingSoon, icon: icon),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
