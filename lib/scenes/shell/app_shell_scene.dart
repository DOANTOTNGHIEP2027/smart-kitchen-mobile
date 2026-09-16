import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../stores/session_store.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/app_bottom_nav.dart';
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
    final session = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>()
        : null;
    final tabs = _tabsOf(context);

    return Observer(
      builder: (_) {
        final index = store.selectedIndex;
        return AppScaffold(
          title: tabs[index].label,
          body: IndexedStack(
            index: index,
            children: List<Widget>.generate(tabs.length, (tabIndex) {
              final tab = tabs[tabIndex];
              if (tabIndex == 4 && session?.provider == 'GUEST') {
                return Column(children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
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
                  ),
                  Expanded(
                    child: AppEmptyView(
                      message: context.l10n.comingSoon,
                      icon: tab.icon,
                    ),
                  ),
                ]);
              }
              return AppEmptyView(
                      message: context.l10n.comingSoon,
                      icon: tab.icon,
                    );
            }),
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
        _ShellTab(context.l10n.navProfile, Icons.person_outline, Icons.person_rounded),
      ];
}

class _ShellTab {
  const _ShellTab(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
