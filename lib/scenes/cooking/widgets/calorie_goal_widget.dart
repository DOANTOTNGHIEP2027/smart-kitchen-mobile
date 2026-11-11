import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../scenes/profile/profile_family_routes.dart';
import '../../../scenes/insights/scenes/insights_routes.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';

/// Widget tổng hợp tiến độ Calo & Dinh dưỡng trong ngày trên màn hình Nhật ký bữa ăn.
/// Thiết kế chuẩn UI/UX Pro Max & DESIGN_SYSTEM.md:
/// Bo tròn mềm mại, hiển thị trực quan tỷ lệ nạp calo (Consumed vs Target),
/// các chỉ số Macro (Đạm, Carbs, Béo) và liên kết nhanh tới biểu đồ xu hướng 30 ngày.
class CalorieGoalWidget extends StatelessWidget {
  const CalorieGoalWidget({
    super.key,
    required this.remainingKcal,
    this.targetKcal,
    this.consumedKcal = 0,
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatG = 0.0,
  });

  /// `null` → hiển thị CTA "Đặt mục tiêu calo".
  final int? remainingKcal;
  final int? targetKcal;
  final int consumedKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    final remaining = remainingKcal;
    final target = targetKcal;

    if (remaining == null || target == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: AppButton(
          label: context.l10n.mealLogSetCalorieGoal,
          icon: Icons.track_changes_rounded,
          variant: AppButtonVariant.outline,
          onPressed: () => Get.toNamed(ProfileFamilyRoutes.profileHealth),
        ),
      );
    }

    final ratio = (consumedKcal / target).clamp(0.0, 1.0);
    final isOver = consumedKcal > target;
    final overAmount = consumedKcal - target;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Mục Tiêu Năng Lượng Hôm Nay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Đích calo: $target kcal / ngày',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Get.toNamed(InsightsRoutes.history),
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Xu hướng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.md),

          // Calorie Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Numbers Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _StatItem(
                label: 'Đã nạp',
                value: '$consumedKcal',
                unit: 'kcal',
                valueColor: AppColors.textPrimary,
              ),
              _StatItem(
                label: isOver ? 'Vượt quá' : 'Còn lại',
                value: '${isOver ? overAmount : remaining}',
                unit: 'kcal',
                valueColor: isOver ? AppColors.error : AppColors.primary,
              ),
              _StatItem(
                label: 'Mục tiêu',
                value: '$target',
                unit: 'kcal',
                valueColor: AppColors.textSecondary,
              ),
            ],
          ),

          // Macro Breakdown (nếu đã có món ăn được nạp)
          if (consumedKcal > 0) ...<Widget>[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MacroTag(
                    label: 'Đạm',
                    grams: proteinG,
                    color: const Color(0xFF10B981),
                    containerColor: const Color(0xFFEAF7EE),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MacroTag(
                    label: 'Carbs',
                    grams: carbsG,
                    color: const Color(0xFFF59E0B),
                    containerColor: const Color(0xFFFEF7EA),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MacroTag(
                    label: 'Béo',
                    grams: fatG,
                    color: const Color(0xFFEF4444),
                    containerColor: const Color(0xFFFDECEC),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 1),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroTag extends StatelessWidget {
  const _MacroTag({
    required this.label,
    required this.grams,
    required this.color,
    required this.containerColor,
  });

  final String label;
  final double grams;
  final Color color;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            '${grams.toStringAsFixed(1)}g',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
