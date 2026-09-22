import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../auth/stores/auth_store.dart';
import 'stores/profile_store.dart';

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline,
                        size: AppDimens.stateIcon, color: AppColors.error),
                    const SizedBox(height: AppDimens.md),
                    Text(context.l10n.stateErrorDefault),
                  ],
                ),
              ),
            ),
          );
        }
        final avatar = user.avatarUrl;
        final initial = (user.fullName?.trim().isNotEmpty == true)
            ? user.fullName!.trim().characters.first.toUpperCase()
            : '?';
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.md, AppDimens.lg, AppDimens.md, AppDimens.lg),
          children: <Widget>[
            AppCard(
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: avatar == null
                        ? null
                        : NetworkImage(avatar) as ImageProvider<Object>,
                    child: avatar == null
                        ? Text(initial,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary))
                        : null,
                  ),
                  const SizedBox(height: AppDimens.md),
                  Text(user.displayName, style: AppTextStyles.titleMedium),
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
            if (session.provider == 'GUEST') ...<Widget>[
              const SizedBox(height: AppDimens.md),
              _GuestUpgradeBanner(
                onTap: () => Get.toNamed(AppRoutes.profileUpgrade),
              ),
            ],
            const SizedBox(height: AppDimens.lg),
            _ProfileNavigationTile(
              icon: Icons.favorite_outline,
              iconColor: const Color(0xFFE85F2A),
              title: context.l10n.healthProfileTitle,
              onPressed: () => Get.toNamed(AppRoutes.profileHealth),
            ),
            const SizedBox(height: AppDimens.sm),
            _ProfileNavigationTile(
              icon: Icons.group_outlined,
              iconColor: const Color(0xFF6A5AE0),
              title: context.l10n.familyTitle,
              onPressed: () => Get.toNamed(AppRoutes.family),
            ),
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
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onPressed;

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
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      );
}

class _GuestUpgradeBanner extends StatelessWidget {
  const _GuestUpgradeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline, color: Color(0xFF2952CC)),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(context.l10n.guestProfileBanner),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF2952CC)),
              ],
            ),
          ),
        ),
      );
}
