import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/state_view_layout.dart';

/// 404 `ERR_DEP_001` / thiếu `:dependentId` — MỘT thông báo cho "không tồn
/// tại" và "thuộc household khác" (Guard 11). Nút về danh sách gọi
/// `backToDependentList()` (MEDIUM-3).
class DependentNotFoundView extends StatelessWidget {
  const DependentNotFoundView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return StateViewLayout(
      key: const ValueKey<String>('dependent-not-found'),
      children: <Widget>[
        Icon(Icons.error_outline,
            size: AppDimens.stateIcon, color: theme.colorScheme.error),
        const SizedBox(height: AppDimens.md),
        Text(l10n.dependentNotFoundTitle,
            textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppDimens.xs),
        Text(l10n.dependentNotFoundBody,
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppDimens.lg),
        AppButton(
          key: const ValueKey<String>('dependent-back-to-list'),
          label: l10n.dependentBackToList,
          variant: AppButtonVariant.secondary,
          expanded: false,
          onPressed: onBack,
        ),
      ],
    );
  }
}

/// S-D8 / S-A0 — chặn phòng thủ khi deep-link bởi user không có quyền.
class DependentBlockedView extends StatelessWidget {
  const DependentBlockedView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StateViewLayout(
      children: <Widget>[
        Icon(Icons.lock_outline,
            size: AppDimens.stateIcon, color: theme.colorScheme.error),
        const SizedBox(height: AppDimens.md),
        Text(context.l10n.dependentNoAccessTitle,
            textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppDimens.xs),
        Text(message,
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
