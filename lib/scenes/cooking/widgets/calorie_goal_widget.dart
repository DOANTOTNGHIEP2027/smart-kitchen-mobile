import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../scenes/profile/profile_family_routes.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';

/// Widget nhỏ trên đầu màn hình: "còn lại X kcal hôm nay" hoặc CTA "Đặt mục
/// tiêu calo" khi chưa setup (meal-log-screen §11.1).
class CalorieGoalWidget extends StatelessWidget {
  const CalorieGoalWidget({super.key, required this.remainingKcal});

  /// `null` → hiển thị CTA "Đặt mục tiêu calo".
  final int? remainingKcal;

  @override
  Widget build(BuildContext context) {
    final remaining = remainingKcal;
    if (remaining == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: AppButton(
          label: context.l10n.mealLogSetCalorieGoal,
          variant: AppButtonVariant.outline,
          onPressed: () => Get.toNamed(ProfileFamilyRoutes.profileHealth),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.l10n.mealLogGoalRemaining(remaining),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}