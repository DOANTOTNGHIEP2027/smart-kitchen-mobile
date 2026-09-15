import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

/// Card dùng chung (fe-app-shell.md §10.2). Bo góc + viền lấy từ theme token;
/// có ripple khi [onTap] khác null.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimens.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppDimens.radiusMd);
    return Material(
      color: AppColors.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
