import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../app/env_config.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../demo/fixtures/demo_fixtures.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../stores/session_store.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/buttons/app_button.dart';
import '../cooking/scenes/cooking_routes.dart';
import '../inventory/scenes/inventory_list_binding.dart';
import '../inventory/scenes/inventory_list_scene.dart';
import '../mealplan/scenes/meal_plan_routes.dart' show WeeklyMealPlanBinding;
import '../mealplan/scenes/weekly_meal_plan_scene.dart';
import '../mealplan/widgets/recipe_cover_image.dart';
import '../profile/profile_family_bindings.dart';
import '../profile/profile_screen.dart';
import '../shopping/scenes/shopping_list_binding.dart';
import '../shopping/scenes/shopping_list_scene.dart';
import 'app_shell_store.dart';
import 'home_recipe_detail_scene.dart';

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
                const ShoppingListScene(),
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
    ShoppingListBinding().dependencies();
    ProfileBinding().dependencies();
  }
}

/// Tab Home — Trang chủ thiết kế theo DESIGN_SYSTEM.md (Soft Modern Kitchen).
///
/// Áp dụng màu Cam tươi mới (#FF7A45), 100% Solid Color (không dùng gradient),
/// bo góc tròn mềm mại 18dp, bóng ambient đổ nhẹ tự nhiên.
/// Danh sách gợi ý món ăn hiển thị trong chế độ Demo Mode (theo kế hoạch backend).
class _HomeTab extends StatelessWidget {
  const _HomeTab();

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
            Row(
              children: <Widget>[
                Expanded(
                  child: _HomeActionCard(
                    title: context.l10n.homeInventoryTitle,
                    subtitle: context.l10n.homeInventorySubtitle,
                    icon: Icons.kitchen_outlined,
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
            const SizedBox(height: AppDimens.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: _HomeActionCard(
                    title: context.l10n.navShopping,
                    subtitle: 'Danh sách đồ cần mua sắm',
                    icon: Icons.shopping_cart_outlined,
                    onTap: () => Get.find<AppShellStore>().selectTab(3),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: _HomeActionCard(
                    title: context.l10n.mealLogTitle,
                    subtitle: 'Theo dõi dinh dưỡng & calo',
                    icon: Icons.analytics_outlined,
                    onTap: () => Get.toNamed<void>(CookingRoutes.mealLog),
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
                      fontSize: 18,
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
          child: Text(
            initial.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
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
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            onTap: () => Get.toNamed<void>(AppRoutes.recipes),
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
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
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
                  color: primary
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: primary ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: primary
                                ? AppColors.textOnPrimary.withValues(alpha: 0.88)
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
    final radius = BorderRadius.circular(AppDimens.radiusCard);
    final prepTime = RecipeCoverImage.demoPrepTimeMinutes(recipeId);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.border,
              width: 1.0,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusCard)),
                child: RecipeCoverImage(
                  recipeId: recipeId,
                  recipeName: recipeName,
                  height: 180,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            recipeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                        if (prepTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 13,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$prepTime phút',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                          ),
                          child: const Text(
                            'Gợi ý cho gia đình',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: AppColors.primaryShadow,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: AppColors.onPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                actionLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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
