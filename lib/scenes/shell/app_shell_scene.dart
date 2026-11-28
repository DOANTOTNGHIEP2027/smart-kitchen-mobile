import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../stores/session_store.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/buttons/app_button.dart';
import '../cooking/scenes/cooking_routes.dart';
import '../home/home_binding.dart';
import '../home/widgets/upcoming_meal_section.dart';
import '../inventory/scenes/inventory_list_binding.dart';
import '../inventory/scenes/inventory_list_scene.dart';
import '../mealplan/scenes/meal_plan_routes.dart' show WeeklyMealPlanBinding;
import '../mealplan/scenes/weekly_meal_plan_scene.dart';
import '../profile/profile_family_bindings.dart';
import '../profile/profile_screen.dart';
import '../profile/widgets/profile_avatar.dart';
import '../shopping/scenes/shopping_list_binding.dart';
import '../shopping/scenes/shopping_list_scene.dart';
import '../shopping/stores/shopping_store.dart';
import '../assistant/scenes/assistant_routes.dart';
import 'app_shell_store.dart';
import 'home_greeting.dart';
import '../notifications/shell_notification_host.dart';
import '../notifications/notifications_routes.dart';
import '../../stores/notification_store.dart';

/// Khung bottom-nav (fe-app-shell.md §12).
///
/// 5 tab: Home, Kho (FE-5), Thực đơn (FE-7), Đi chợ (Shopping offline-first),
/// Cá nhân (FE-3). Mỗi tab render feature scene thật —
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

    // #48 — điều hướng từ push + sheet xin quyền chỉ chạy khi shell đã lên.
    return ShellNotificationHost(
      child: Observer(
        builder: (_) {
          final index = store.selectedIndex;
          // Mỗi tab là Scaffold riêng — không dùng AppScaffold cha để tránh 2
          // AppBar chồng lên nhau (feature scene đã có AppBar của mình).
          return PopScope<void>(
            // IndexedStack không tạo route history khi đổi tab. Chặn pop ở tab
            // khác Home để Android back gesture/nút back đưa người dùng về
            // Home, thay vì pop route shell và thoát app.
            canPop: index == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && store.selectedIndex != 0) {
                store.selectTab(0);
              }
            },
            child: Scaffold(
              // Trợ lý bếp GLOBAL (#204, FE design v2 §1). Góc trái để không đè
              // FAB của tab Kho/Đi chợ (end-float); ẩn khi bàn phím mở.
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.startFloat,
              floatingActionButton: MediaQuery.viewInsetsOf(context).bottom > 0
                  ? null
                  : FloatingActionButton.small(
                      heroTag: 'assistant-fab',
                      tooltip: context.l10n.assistantFabTooltip,
                      onPressed: AssistantRoutes.openGlobal,
                      child: const Icon(Icons.assistant_outlined),
                    ),
              body: IndexedStack(
                index: index,
                children: const <Widget>[
                  HomeTab(),
                  InventoryListScene(),
                  WeeklyMealPlanScene(),
                  ShoppingListScene(),
                  ProfileScreen(),
                ],
              ),
              // #134 (shopping-list-screen §9.7(a)): Observer RIÊNG cho badge —
              // đọc số trong Observer ngoài thì mỗi lần Drift emit sẽ dựng lại
              // cả Scaffold/IndexedStack.
              bottomNavigationBar: Observer(builder: (context) {
                final assigned = shoppingAssignedBadgeCount();
                return AppBottomNav(
                  selectedIndex: index,
                  onDestinationSelected: store.selectTab,
                  destinations: <AppBottomNavDestination>[
                    for (var i = 0; i < tabs.length; i++)
                      AppBottomNavDestination(
                        icon: tabs[i].icon,
                        activeIcon: tabs[i].activeIcon,
                        label: tabs[i].label,
                        badgeCount: i == _shoppingTabIndex ? assigned : 0,
                        semanticsLabel: i == _shoppingTabIndex
                            ? context.l10n
                                .navShoppingAssignedSemantics(assigned)
                            : null,
                      ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  List<_ShellTab> _tabsOf(BuildContext context) => <_ShellTab>[
        _ShellTab(
            context.l10n.navHome, Icons.home_outlined, Icons.home_rounded),
        _ShellTab(context.l10n.navInventory, Icons.kitchen_outlined,
            Icons.kitchen_rounded),
        _ShellTab(context.l10n.navPlanning, Icons.event_note_outlined,
            Icons.event_rounded),
        _ShellTab(context.l10n.navShopping, Icons.shopping_cart_outlined,
            Icons.shopping_cart_rounded),
        _ShellTab(context.l10n.navProfile, Icons.person_outline,
            Icons.person_outline),
      ];

  /// Vị trí tab Đi chợ trong [IndexedStack] / bottom nav.
  static const int _shoppingTabIndex = 3;

  static void _ensureBindings() {
    HomeBinding().dependencies();
    InventoryListBinding().dependencies();
    WeeklyMealPlanBinding().dependencies();
    ShoppingListBinding().dependencies();
    ProfileBinding().dependencies();
  }
}

/// Số món CHƯA MUA giao cho chính mình — CÙNG nguồn với chip "Của tôi"
/// (`ShoppingStore.assignedToMeCount`, cục bộ). Store chưa đăng ký ⇒ 0.
/// Gọi trong Observer để badge tự cập nhật.
int shoppingAssignedBadgeCount() => Get.isRegistered<ShoppingStore>()
    ? Get.find<ShoppingStore>().assignedToMeCount
    : 0;

/// Tab Home — Trang chủ thiết kế theo DESIGN_SYSTEM.md (Soft Modern Kitchen).
///
/// Áp dụng màu Cam tươi mới (#FF7A45), 100% Solid Color (không dùng gradient),
/// bo góc tròn mềm mại 18dp, bóng ambient đổ nhẹ tự nhiên.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final session =
        Get.isRegistered<SessionStore>() ? Get.find<SessionStore>() : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.xl),
          children: <Widget>[
            // Observer riêng cho header: đổi tên/ảnh đại diện ở Hồ sơ phải
            // phản ánh ngay ở Home (HomeTab là StatelessWidget, không tự
            // dựng lại khi currentUser đổi).
            Observer(
              builder: (context) {
                final user = session?.currentUser;
                return _HomeHeader(
                  displayName: user?.displayName ?? context.l10n.appTitle,
                  avatarUrl: user?.avatarUrl,
                );
              },
            ),
            const SizedBox(height: AppDimens.lg),
            if (session?.provider == 'GUEST') ...<Widget>[
              _GuestProfileCard(
                message: context.l10n.guestProfileBanner,
                actionLabel: context.l10n.completeProfile,
              ),
              const SizedBox(height: AppDimens.lg),
            ],
            const UpcomingMealSection(),
            const SizedBox(height: AppDimens.xl),
            Text(
              context.l10n.homeQuickActions,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: AppDimens.sm),
            _HomeActionCard(
              title: context.l10n.homeStartCooking,
              subtitle: context.l10n.homeStartCookingSubtitle,
              icon: Icons.restaurant_menu_rounded,
              primary: true,
              onTap: _openMealPlan,
            ),
            const SizedBox(height: AppDimens.sm),
            LayoutBuilder(builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >=
                  600 * MediaQuery.textScalerOf(context).scale(1);
              final width = twoColumns
                  ? (constraints.maxWidth - AppDimens.sm) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppDimens.sm,
                runSpacing: AppDimens.sm,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: _HomeActionCard(
                      title: context.l10n.homeInventoryTitle,
                      subtitle: context.l10n.homeInventorySubtitle,
                      icon: Icons.kitchen_outlined,
                      onTap: () => Get.find<AppShellStore>().selectTab(1),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _HomeActionCard(
                      title: context.l10n.homeMealPlanTitle,
                      subtitle: context.l10n.homeMealPlanSubtitle,
                      icon: Icons.event_note_outlined,
                      onTap: _openMealPlan,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _HomeActionCard(
                      title: context.l10n.navShopping,
                      subtitle: context.l10n.homeShoppingSubtitle,
                      icon: Icons.shopping_cart_outlined,
                      onTap: () => Get.find<AppShellStore>().selectTab(3),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _HomeActionCard(
                      title: context.l10n.mealLogTitle,
                      subtitle: context.l10n.homeMealLogSubtitle,
                      icon: Icons.analytics_outlined,
                      onTap: () => Get.toNamed<void>(CookingRoutes.mealLog),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openMealPlan() => Get.find<AppShellStore>().selectTab(2);
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.displayName, this.avatarUrl});

  final String displayName;

  /// Ảnh đại diện của user; null/rỗng ⇒ [ProfileAvatar] tự hiện chữ cái đầu.
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          key: const ValueKey<String>('home-header-avatar'),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x10FF7A45),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: ProfileAvatar(
            avatarUrl: avatarUrl,
            fullName: displayName,
            size: 45,
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              HomeGreeting(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          child: InkWell(
            key: const ValueKey<String>('home-header-notifications'),
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            onTap: () => Get.toNamed<void>(NotificationsRoutes.list),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.0),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Tooltip(
                message: context.l10n.notificationsNavTitle,
                child: _notificationIcon(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon chuông + badge số chưa đọc (cùng nguồn `NotificationStore.unreadCount`
/// như mục Thông báo ở màn Cá nhân). Chưa đăng ký store → chỉ icon.
Widget _notificationIcon() {
  const icon = Icon(
    Icons.notifications_none_rounded,
    color: AppColors.primary,
    size: 20,
  );
  if (!Get.isRegistered<NotificationStore>()) return const Center(child: icon);
  final store = Get.find<NotificationStore>();
  return Center(
    child: Observer(builder: (_) {
      final unread = store.unreadCount;
      return Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: icon,
      );
    }),
  );
}

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({required this.message, required this.actionLabel});

  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.primaryLight, width: 1.0),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            AppButton(
              label: actionLabel,
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => Get.toNamed(AppRoutes.profileUpgrade),
            ),
          ],
        ),
      );
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusCard);
    final foreground =
        primary ? AppColors.textOnPrimary : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: primary ? AppColors.primary : AppColors.surface,
            // 100% Solid Color — Tuyệt đối không dùng gradient theo DESIGN_SYSTEM.md
            borderRadius: radius,
            border: primary
                ? null
                : Border.all(
                    color: AppColors.border,
                    width: 1.0,
                  ),
            boxShadow: primary
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: primary ? 46 : 40,
                height: primary ? 46 : 40,
                decoration: BoxDecoration(
                  color: primary
                      ? AppColors.textOnPrimary.withValues(alpha: 0.18)
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: primary ? 24 : 20,
                  color: primary ? AppColors.textOnPrimary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: primary
                                ? AppColors.textOnPrimary
                                    .withValues(alpha: 0.88)
                                : AppColors.textSecondary,
                            height: 1.25,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: primary
                      ? AppColors.textOnPrimary.withValues(alpha: 0.15)
                      : AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: primary
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
