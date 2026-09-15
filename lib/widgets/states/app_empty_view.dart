import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/l10n_x.dart';

/// Trạng thái rỗng dùng chung (fe-app-shell.md §10.3).
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, this.message, this.icon});

  final String? message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon ?? Icons.inbox_outlined,
                size: AppDimens.stateIcon,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                message ?? context.l10n.stateEmptyDefault,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
}
