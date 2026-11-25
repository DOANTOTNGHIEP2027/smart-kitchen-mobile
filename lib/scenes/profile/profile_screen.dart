import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../app/env_config.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_colors_extension.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/state_view_layout.dart';
import '../auth/stores/auth_store.dart';
import '../cooking/scenes/cooking_routes.dart';
import '../dev/dev_routes.dart';
import '../insights/scenes/insights_routes.dart';
import '../recap/scenes/recap_routes.dart';
import '../nutrition/widgets/profile_nutrition_section.dart';
import '../notifications/notifications_routes.dart';
import '../../stores/notification_store.dart';
import 'stores/profile_store.dart';
import 'widgets/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ProfileStore>();
    final session = Get.find<SessionStore>();
    return AppScaffold(
      title: context.l10n.profileTitle,
      body: Observer(builder: (_) {
        final user = store.currentUser;
        if (user == null) {
          // P3 — lẽ ra không xảy ra sau AuthGuard (§10.1).
          developer.log('ProfileScreen opened without currentUser',
              name: 'profile');
          return const _NoSessionView();
        }
        final colors = context.appColors;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.md, AppDimens.lg, AppDimens.md, AppDimens.lg),
          children: <Widget>[
            AppCard(
              child: Column(
                children: <Widget>[
                  ProfileAvatar(
                    avatarUrl: user.avatarUrl,
                    fullName: user.fullName,
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(
                    _displayName(context, user.fullName),
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    user.email ?? context.l10n.profileEmailMissing,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),
            AppButton(
              label: context.l10n.profileEdit,
              icon: Icons.edit_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => Get.toNamed(AppRoutes.profileEdit),
            ),
            // P2 — GUEST (email null) → gợi ý thiết lập email (#28).
            if (user.email == null || session.provider == 'GUEST') ...<Widget>[
              const SizedBox(height: AppDimens.md),
              _GuestUpgradeBanner(
                onTap: () => Get.toNamed(AppRoutes.profileUpgrade),
              ),
            ],
            // #64 — dinh dưỡng tuần hiện tại (nutrition-summary-widget.md §8.2).
            const SizedBox(height: AppDimens.lg),
            const ProfileNutritionSection(),
            const SizedBox(height: AppDimens.lg),
            // #48 — thông báo trong phiên + trạng thái quyền (fcm-notification-flow.md §8).
            if (Get.isRegistered<NotificationStore>()) ...<Widget>[
              Observer(builder: (_) {
                final unread = Get.find<NotificationStore>().unreadCount;
                return _ProfileNavigationTile(
                  key: const ValueKey<String>('profile-notifications'),
                  icon: Icons.notifications_none_rounded,
                  iconColor: AppColors.primary,
                  title: context.l10n.notificationsNavTitle,
                  badge: unread > 0
                      ? context.l10n.notificationsUnreadBadge(unread)
                      : null,
                  onPressed: () => Get.toNamed(NotificationsRoutes.list),
                );
              }),
              const SizedBox(height: AppDimens.sm),
            ],
            _ProfileNavigationTile(
              icon: Icons.favorite_outline,
              iconColor: AppColors.primaryDark,
              title: context.l10n.healthProfileTitle,
              onPressed: () => Get.toNamed(AppRoutes.profileHealth),
            ),
            const SizedBox(height: AppDimens.sm),
            _ProfileNavigationTile(
              icon: Icons.child_care_rounded,
              iconColor: AppColors.sage,
              title: context.l10n.dependentProfileNav,
              onPressed: () => Get.toNamed(AppRoutes.dependents),
            ),
            const SizedBox(height: AppDimens.sm),
            _ProfileNavigationTile(
              icon: Icons.group_outlined,
              iconColor: colors.info,
              title: context.l10n.familyTitle,
              onPressed: () => Get.toNamed(AppRoutes.family),
            ),
            const SizedBox(height: AppDimens.sm),
            _ProfileNavigationTile(
              icon: Icons.auto_awesome,
              iconColor: colors.warning,
              title: context.l10n.profileWeeklyRecapNav,
              onPressed: () => Get.toNamed(RecapRoutes.root),
            ),
            const SizedBox(height: AppDimens.sm),
            _ProfileNavigationTile(
              icon: Icons.menu_book_rounded,
              iconColor: colors.success,
              title: context.l10n.mealLogTitle,
              onPressed: () => Get.toNamed(CookingRoutes.mealLog),
            ),
            const SizedBox(height: AppDimens.sm),
            _ProfileNavigationTile(
              icon: Icons.insights_rounded,
              iconColor: AppColors.secondary,
              title: context.l10n.insightsHistoryTooltip,
              onPressed: () => Get.toNamed(InsightsRoutes.history),
            ),
            // Lối vào showcase widget library — chỉ build dev (design-system.md §8).
            if (EnvConfig.isDev) ...<Widget>[
              const SizedBox(height: AppDimens.sm),
              _ProfileNavigationTile(
                key: const ValueKey<String>('profile-widget-showcase'),
                icon: Icons.widgets_outlined,
                iconColor: AppColors.primary,
                title: context.l10n.showcaseEntry,
                onPressed: () => Get.toNamed(DevRoutes.widgetShowcase),
              ),
            ],
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: context.l10n.profileLogout,
              icon: Icons.logout,
              variant: AppButtonVariant.outline,
              onPressed: () => _logout(context, allDevices: false),
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              label: context.l10n.profileLogoutAll,
              icon: Icons.devices_other_outlined,
              variant: AppButtonVariant.text,
              onPressed: () => _logout(context, allDevices: true),
            ),
          ],
        );
      }),
    );
  }

  /// Xác nhận rồi đăng xuất. [allDevices] = true → `POST /auth/revoke-all`
  /// (mọi thiết bị); mặc định chỉ thu hồi refresh token của thiết bị này.
  ///
  /// Điều hướng bằng `Get.offAllNamed` vì guard chỉ chạy khi điều hướng — nếu
  /// chỉ đổi `SessionStore.status`, người dùng sẽ đứng lại trên màn hình
  /// profile đã bị chặn.
  Future<void> _logout(BuildContext context, {required bool allDevices}) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(
          allDevices ? l10n.profileLogoutAllConfirm : l10n.profileLogoutConfirm,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.profileLogoutCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              allDevices ? l10n.profileLogoutAll : l10n.profileLogout,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Get.find<AuthStore>().logout(allDevices: allDevices);
    Get.offAllNamed(AppRoutes.login);
  }
}

class _ProfileNavigationTile extends StatelessWidget {
  const _ProfileNavigationTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onPressed,
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            if (badge != null)
              Badge(
                key: const ValueKey<String>('profile-tile-badge'),
                label: Text(badge!),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      );
}

class _GuestUpgradeBanner extends StatelessWidget {
  const _GuestUpgradeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.infoSurface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            children: <Widget>[
              Icon(Icons.info_outline, color: colors.info),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(context.l10n.guestProfileBanner),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.info),
            ],
          ),
        ),
      ),
    );
  }
}

/// `fullName` null/trống (GUEST qr-join) → "Thành viên" (§10.1 P1/P2).
String _displayName(BuildContext context, String? fullName) {
  final name = fullName?.trim() ?? '';
  return name.isEmpty ? context.l10n.profileDefaultName : name;
}

/// P3 — không có session: thông báo + "Đăng nhập lại" → `/login`.
class _NoSessionView extends StatelessWidget {
  const _NoSessionView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return StateViewLayout(
      children: <Widget>[
        Icon(Icons.error_outline,
            size: AppDimens.stateIcon, color: theme.colorScheme.error),
        const SizedBox(height: AppDimens.md),
        Text(l10n.profileSessionMissingTitle,
            textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppDimens.sm),
        Text(l10n.profileSessionMissingMessage,
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppDimens.lg),
        AppButton(
          key: const ValueKey<String>('profile-relogin'),
          label: l10n.profileReLogin,
          icon: Icons.login,
          onPressed: () => Get.offAllNamed(AppRoutes.login),
        ),
      ],
    );
  }
}
