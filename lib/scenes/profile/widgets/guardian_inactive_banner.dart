import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';

/// Banner cảnh báo `guardianActive:false` (§9.3 state 3, §16.3) — KHÔNG phải
/// error state; nội dung phía dưới vẫn render. Copy phủ CẢ 2 nguyên nhân
/// (rời gia đình HOẶC bị hạ Remote Viewer — OD-84). [showOwnerHint] thêm gợi ý
/// cho OWNER.
class GuardianInactiveBanner extends StatelessWidget {
  const GuardianInactiveBanner({super.key, this.showOwnerHint = false});

  final bool showOwnerHint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.dependentGuardianInactiveBanner,
                      style: theme.textTheme.bodyMedium),
                  if (showOwnerHint) ...<Widget>[
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      l10n.dependentGuardianInactiveOwnerHint,
                      key: const ValueKey<String>(
                          'dependent-guardian-owner-hint'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
