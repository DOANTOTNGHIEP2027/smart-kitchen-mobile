import 'package:flutter/material.dart';

import '../../constants/app_dimens.dart';
import '../../constants/app_icons.dart';
import '../../utils/l10n_x.dart';
import '../buttons/app_button.dart';
import 'state_view_layout.dart';

/// Trạng thái lỗi + retry dùng chung (fe-app-shell.md §10.3, design-system.md §7.4).
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return StateViewLayout(
      children: <Widget>[
        Icon(
          AppIcons.error,
          size: AppDimens.stateIcon,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: AppDimens.md),
        Text(
          message ?? context.l10n.stateErrorDefault,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (retry != null) ...<Widget>[
          const SizedBox(height: AppDimens.lg),
          AppButton(
            label: context.l10n.commonRetry,
            onPressed: retry,
            variant: AppButtonVariant.secondary,
            expanded: false,
            icon: AppIcons.retry,
          ),
        ],
      ],
    );
  }
}
