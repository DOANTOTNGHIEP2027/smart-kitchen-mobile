import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/states/app_empty_view.dart';
import 'app_shell_store.dart';

/// Khung bottom-nav (fe-app-shell.md §12).
///
/// Bộ tab là giả định suy ra từ danh sách module trong `CONTEXT_FE.md`, chưa
/// được product xác nhận (open question Q2). Mỗi tab hiện là placeholder —
/// feature tương ứng sẽ thay body khi ship.
class AppShellScene extends StatelessWidget {
  const AppShellScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<AppShellStore>();
    final tabs = _tabsOf(context);

    return Observer(
      builder: (_) {
        final index = store.selectedIndex;
        return AppScaffold(
          title: tabs[index].label,
          body: IndexedStack(
            index: index,
            children: tabs
                .map((tab) => AppEmptyView(
                      message: context.l10n.comingSoon,
                      icon: tab.icon,
                    ))
                .toList(growable: false),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: store.selectTab,
            destinations: tabs
                .map((tab) => NavigationDestination(
                      icon: Icon(tab.icon),
                      label: tab.label,
                    ))
                .toList(growable: false),
          ),
        );
      },
    );
  }

  List<_ShellTab> _tabsOf(BuildContext context) => <_ShellTab>[
        _ShellTab(context.l10n.navHome, Icons.home_outlined),
        _ShellTab(context.l10n.navInventory, Icons.kitchen_outlined),
        _ShellTab(context.l10n.navPlanning, Icons.event_note_outlined),
        _ShellTab(context.l10n.navShopping, Icons.shopping_cart_outlined),
        _ShellTab(context.l10n.navProfile, Icons.person_outline),
      ];
}

class _ShellTab {
  const _ShellTab(this.label, this.icon);
  final String label;
  final IconData icon;
}
