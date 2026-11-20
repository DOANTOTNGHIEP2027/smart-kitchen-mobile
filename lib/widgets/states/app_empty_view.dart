import 'package:flutter/material.dart';

import '../../constants/app_colors_extension.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_icons.dart';
import '../../utils/l10n_x.dart';
import 'state_view_layout.dart';

/// Trạng thái rỗng dùng chung (fe-app-shell.md §10.3, design-system.md §7.4).
///
/// [illustration] (nếu có) thay chỗ icon; [action] (nếu có) đặt dưới message.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    this.message,
    this.icon,
    this.illustration,
    this.action,
  });

  final String? message;
  final IconData? icon;
  final Widget? illustration;
  final Widget? action;

  static const double _illustrationMaxHeight = 160;

  @override
  Widget build(BuildContext context) {
    final illustrationWidget = illustration;
    final actionWidget = action;
    return StateViewLayout(
      children: <Widget>[
        if (illustrationWidget != null)
          ConstrainedBox(
            constraints:
                const BoxConstraints(maxHeight: _illustrationMaxHeight),
            child: illustrationWidget,
          )
        else
          Icon(
            icon ?? AppIcons.empty,
            size: AppDimens.stateIcon,
            color: context.appColors.textDisabled,
          ),
        const SizedBox(height: AppDimens.md),
        Text(
          message ?? context.l10n.stateEmptyDefault,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (actionWidget != null) ...<Widget>[
          const SizedBox(height: AppDimens.lg),
          actionWidget,
        ],
      ],
    );
  }
}
