import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/states/app_empty_view.dart';
import '../../constants/app_colors.dart';
import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../widgets/buttons/app_button.dart';
import 'app_shell_store.dart';

class AppShellScene extends StatelessWidget {
  const AppShellScene({super.key});

  static const _tabs = <_ShellTab>[
    _ShellTab('home', Icons.home_outlined, Icons.home_rounded),
    _ShellTab('inventory', Icons.kitchen_outlined, Icons.kitchen_rounded),
    _ShellTab('planning', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
    _ShellTab('shopping', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
    _ShellTab('profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final store = Get.find<AppShellStore>();
    return Observer(
      builder: (_) => AppScaffold(
        body: IndexedStack(
          index: store.selectedIndex,
          children: _tabs.asMap().entries
              .map(
                (entry) => entry.key == 4
                    ? const _ProfileTab()
                    : _PlaceholderTab(
                  key: ValueKey(entry.key),
                  title: entry.value.labelKey.tr,
                  icon: entry.value.selectedIcon,
                ),
              )
              .toList(growable: false),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: store.selectedIndex,
          onDestinationSelected: store.selectTab,
          destinations: _tabs
              .map(
                (tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.labelKey.tr,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionStore>();
    return AppScaffold(
      title: 'profile'.tr,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (session.provider == 'GUEST') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('guest_banner_title'.tr, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('guest_banner_body'.tr),
                const SizedBox(height: 12),
                AppButton(label: 'complete_profile'.tr, onPressed: () => Get.toNamed(AppRoutes.upgradeProfile)),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(child: AppEmptyView(icon: Icons.person_rounded, message: 'coming_soon'.tr)),
        ]),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: AppEmptyView(icon: icon, message: 'coming_soon'.tr),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.labelKey, this.icon, this.selectedIcon);

  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
}
