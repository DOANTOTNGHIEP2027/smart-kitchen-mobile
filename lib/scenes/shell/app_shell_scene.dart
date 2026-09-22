import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../app/env_config.dart';
import '../../demo/fixtures/demo_fixtures.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../stores/session_store.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/app_empty_view.dart';
import '../inventory/scenes/inventory_list_binding.dart';
import '../inventory/scenes/inventory_list_scene.dart';
import '../mealplan/scenes/meal_plan_routes.dart' show WeeklyMealPlanBinding;
import '../mealplan/scenes/weekly_meal_plan_scene.dart';
import '../mealplan/widgets/recipe_cover_image.dart';
import '../profile/profile_family_bindings.dart';
import '../profile/profile_screen.dart';
import 'app_shell_store.dart';
import 'home_recipe_detail_scene.dart';

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
            body: IndexedStack(
              index: index,
              children: <Widget>[
                const _HomeTab(),
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
          ),
        );
      },
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

  static void _ensureBindings() {
    InventoryListBinding().dependencies();
    WeeklyMealPlanBinding().dependencies();
    ProfileBinding().dependencies();
  }
}

/// Tab Home — dashboard cho bản demo, dùng các flow đã ship làm lối tắt.
///
/// Không gọi endpoint mới ở đây: trong Demo Mode, recipe fixture mở thẳng
/// cooking session; với backend thật, người dùng được dẫn tới kế hoạch tuần
/// để chọn recipe hợp lệ của chính household.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final session =
        Get.isRegistered<SessionStore>() ? Get.find<SessionStore>() : null;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.xl),
          children: <Widget>[
            _HomeHeader(
              greeting: context.l10n.homeGreeting,
              displayName:
                  session?.currentUser?.displayName ?? context.l10n.appTitle,
            ),
            const SizedBox(height: AppDimens.lg),
            if (session?.provider == 'GUEST') ...<Widget>[
              _GuestProfileCard(
                message: context.l10n.guestProfileBanner,
                actionLabel: context.l10n.completeProfile,
              ),
              const SizedBox(height: AppDimens.lg),
            ],
            Text(
              context.l10n.homeQuickActions,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
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
            Row(
              children: <Widget>[
                Expanded(
                  child: _HomeActionCard(
                    title: context.l10n.homeInventoryTitle,
                    subtitle: context.l10n.homeInventorySubtitle,
                    icon: Icons.inventory_2_outlined,
                    onTap: () => Get.find<AppShellStore>().selectTab(1),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: _HomeActionCard(
                    title: context.l10n.homeMealPlanTitle,
                    subtitle: context.l10n.homeMealPlanSubtitle,
                    icon: Icons.event_note_outlined,
                    onTap: _openMealPlan,
                  ),
                ),
              ],
            ),
            if (EnvConfig.isDemoMode) ...<Widget>[
              const SizedBox(height: AppDimens.xl),
              Text(
                context.l10n.homeRecommendedMeals,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppDimens.sm),
              ...DemoFixtures.suggestions().map(
                (recipe) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.md),
                  child: _HomeRecipeCard(
                    recipeId: recipe['recipeId']! as String,
                    recipeName: recipe['recipeName']! as String,
                    actionLabel: context.l10n.homeRecipeAction,
                    onTap: () => Get.to<void>(
                      () => HomeRecipeDetailScene(
                        recipeId: recipe['recipeId']! as String,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openMealPlan() => Get.find<AppShellStore>().selectTab(2);
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.greeting, required this.displayName});

  final String greeting;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final trimmedName = displayName.trim();
    final initial = trimmedName.isEmpty ? 'S' : trimmedName.substring(0, 1);
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: AppDimens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textOnPrimary),
        ),
      ],
    );
  }
}

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({required this.message, required this.actionLabel});

  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppDimens.sm),
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
    final radius = BorderRadius.circular(AppDimens.radiusMd);
    final foreground =
        primary ? AppColors.textOnPrimary : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: primary ? null : AppColors.surface,
            gradient: primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.primaryGradientStart,
                      AppColors.primary,
                    ],
                  )
                : null,
            borderRadius: radius,
            border: primary
                ? null
                : Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.32),
                    width: 1.2,
                  ),
            boxShadow: primary
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0D111111),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: primary ? 46 : 38,
                height: primary ? 46 : 38,
                decoration: BoxDecoration(
                  color: primary
                      ? AppColors.textOnPrimary.withValues(alpha: 0.2)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(icon,
                    color: primary
                        ? AppColors.textOnPrimary
                        : AppColors.primaryDark),
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: primary ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      subtitle,
                      maxLines: primary ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: primary
                                ? AppColors.textOnPrimary
                                    .withValues(alpha: 0.86)
                                : AppColors.textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color:
                    primary ? AppColors.textOnPrimary : AppColors.textSecondary,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeRecipeCard extends StatelessWidget {
  const _HomeRecipeCard({
    required this.recipeId,
    required this.recipeName,
    required this.actionLabel,
    required this.onTap,
  });

  final String recipeId;
  final String recipeName;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusMd);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.sm),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.32),
              width: 1.2,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0D111111),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              RecipeCoverImage(
                recipeId: recipeId,
                recipeName: recipeName,
                height: 184,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                recipeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppDimens.sm),
              Row(
                children: <Widget>[
                  const Icon(Icons.play_circle_outline_rounded,
                      size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: AppDimens.xs),
                  Text(
                    actionLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
