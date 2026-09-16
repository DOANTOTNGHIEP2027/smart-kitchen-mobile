import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import 'stores/profile_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ProfileStore>();
    return AppScaffold(
      title: context.l10n.profileTitle,
      body: Observer(builder: (_) {
        final user = store.currentUser;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline,
                    size: AppDimens.stateIcon, color: AppColors.error),
                const SizedBox(height: AppDimens.md),
                Text(context.l10n.stateErrorDefault),
              ],
            ),
          );
        }
        final avatar = user.avatarUrl;
        final initial = (user.fullName?.trim().isNotEmpty == true)
            ? user.fullName!.trim().characters.first.toUpperCase()
            : '?';
        return ListView(
          padding: const EdgeInsets.all(AppDimens.md),
          children: <Widget>[
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: avatar == null
                    ? null
                    : NetworkImage(avatar) as ImageProvider<Object>,
                child: avatar == null
                    ? Text(initial,
                        style: const TextStyle(
                            fontSize: 28, color: AppColors.primary))
                    : null,
              ),
            ),
            const SizedBox(height: AppDimens.md),
            Center(
                child: Text(user.displayName,
                    style: AppTextStyles.titleMedium)),
            const SizedBox(height: AppDimens.xs),
            Center(
              child: Text(
                user.email ?? context.l10n.profileEmailMissing,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: context.l10n.profileEdit,
              icon: Icons.edit_outlined,
              onPressed: () => Get.toNamed(AppRoutes.profileEdit),
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              label: context.l10n.healthProfileTitle,
              icon: Icons.favorite_outline,
              variant: AppButtonVariant.secondary,
              onPressed: () => Get.toNamed(AppRoutes.profileHealth),
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              label: context.l10n.familyTitle,
              icon: Icons.group_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => Get.toNamed(AppRoutes.family),
            ),
          ],
        );
      }),
    );
  }
}
