import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/states/app_empty_view.dart';
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
          children: _tabs
              .map(
                (tab) => _PlaceholderTab(
                  title: tab.labelKey.tr,
                  icon: tab.selectedIcon,
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.icon});

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
