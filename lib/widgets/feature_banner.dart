import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

/// Banner thông báo/lỗi inline dùng chung (icon + `Semantics.liveRegion`).
/// [isError] = tông đỏ cảnh báo, ngược lại là tông thông tin.
class FeatureBanner extends StatelessWidget {
  const FeatureBanner({
    super.key,
    required this.message,
    this.isError = true,
    this.margin = EdgeInsets.zero,
  });

  final String message;
  final bool isError;

  /// Khoảng cách ngoài — mặc định 0 để giữ nguyên layout các màn auth/household.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          margin: margin,
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFFEEEE) : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: isError ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
}
