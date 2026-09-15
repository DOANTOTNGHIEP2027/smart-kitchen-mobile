import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/l10n_x.dart';
import '../buttons/app_button.dart';

/// Trạng thái lỗi + retry dùng chung (fe-app-shell.md §10.3).
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: AppDimens.stateIcon,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              message ?? context.l10n.stateErrorDefault,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            if (retry != null) ...<Widget>[
              const SizedBox(height: AppDimens.lg),
              AppButton(
                label: context.l10n.commonRetry,
                onPressed: retry,
                variant: AppButtonVariant.secondary,
                expanded: false,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
