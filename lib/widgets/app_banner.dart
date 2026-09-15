import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_text_styles.dart';

enum AppBannerVariant { info, warning, error }

/// Banner thông báo trong luồng — dùng cho các state **không chặn** như nhắc
/// nâng cấp GUEST (S9.1), giới hạn resend OTP (S4.4), khóa đăng nhập (S5.4).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.variant = AppBannerVariant.info,
    this.action,
    this.onDismiss,
  });

  final String message;
  final AppBannerVariant variant;
  final Widget? action;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final dismiss = onDismiss;
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: _foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(_icon, size: 20, color: _foreground),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message, style: AppTextStyles.bodyMedium),
                if (action != null) ...<Widget>[
                  const SizedBox(height: AppDimens.sm),
                  action!,
                ],
              ],
            ),
          ),
          if (dismiss != null)
            IconButton(
              onPressed: dismiss,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Color get _background => switch (variant) {
        AppBannerVariant.info => AppColors.primaryLight.withValues(alpha: 0.30),
        AppBannerVariant.warning => AppColors.warning.withValues(alpha: 0.12),
        AppBannerVariant.error => AppColors.error.withValues(alpha: 0.10),
      };

  Color get _foreground => switch (variant) {
        AppBannerVariant.info => AppColors.primaryDark,
        AppBannerVariant.warning => AppColors.warning,
        AppBannerVariant.error => AppColors.error,
      };

  IconData get _icon => switch (variant) {
        AppBannerVariant.info => Icons.info_outline,
        AppBannerVariant.warning => Icons.schedule,
        AppBannerVariant.error => Icons.error_outline,
      };
}
