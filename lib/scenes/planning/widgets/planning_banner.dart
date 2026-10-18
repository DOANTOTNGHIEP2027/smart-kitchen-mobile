import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';

/// Banner thông tin/lỗi inline dùng chung cho các màn module planning.
class PlanningBanner extends StatelessWidget {
  const PlanningBanner({
    super.key,
    required this.text,
    required this.color,
    this.textColor = AppColors.textPrimary,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppDimens.sm),
        padding: const EdgeInsets.all(AppDimens.sm),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
        child: Text(text, style: TextStyle(color: textColor)),
      );
}
