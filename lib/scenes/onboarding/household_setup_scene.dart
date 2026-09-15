import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import 'onboarding_routes.dart';

/// S6.2 — chọn cách thiết lập household.
///
/// Theo Decision D1 màn hình này **không có** hành động "bỏ qua": mọi phiên
/// đã xác thực đều phải kết thúc với một `household_id` (open question Q1 ghi
/// nhận khả năng đảo ngược quyết định này).
class HouseholdSetupScene extends StatelessWidget {
  const HouseholdSetupScene({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(Icons.groups_outlined,
                    size: 64, color: AppColors.primary),
                const SizedBox(height: AppDimens.lg),
                Text(
                  context.l10n.householdSetupTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  context.l10n.householdSetupSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppDimens.xl),
                AppButton(
                  label: context.l10n.householdCreateCta,
                  icon: Icons.add_home_outlined,
                  onPressed: () =>
                      Get.toNamed<void>(OnboardingRoutes.createHousehold),
                ),
                const SizedBox(height: AppDimens.sm),
                AppButton(
                  label: context.l10n.householdJoinCta,
                  icon: Icons.qr_code_scanner,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      Get.toNamed<void>(OnboardingRoutes.inviteCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
