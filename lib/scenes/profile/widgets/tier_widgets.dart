import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../domain/household_tier.dart';

/// Tên hiển thị của tier — l10n, không đặt trong domain.
String tierLabel(AppLocalizations l10n, HouseholdTier tier) => switch (tier) {
      HouseholdTier.free => l10n.tierFree,
      HouseholdTier.premium => l10n.tierPremium,
      HouseholdTier.unknown => l10n.tierUnknown,
    };

/// Banner đọc-only cho chính người dùng REMOTE_VIEWER (tier-gate §10.1).
/// Nhận [visible] qua constructor, không tự đọc store — dùng lại được ở
/// module khác.
class RemoteViewerBanner extends StatelessWidget {
  const RemoteViewerBanner({
    super.key,
    required this.visible,
    this.margin = const EdgeInsets.only(bottom: AppDimens.sm),
  });

  final bool visible;

  /// Khoảng cách ngoài — chỉ chiếm chỗ khi banner hiện (ẩn → không để lại khe trống).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return FeatureBanner(
      key: const ValueKey<String>('remote-viewer-banner'),
      message: context.l10n.tierRemoteViewerBanner,
      isError: false,
      margin: margin,
    );
  }
}

/// "1/1 ghế Chỉ xem" — đỏ khi đã đầy (chỉ là hint, Guard 1).
class SeatUsageChip extends StatelessWidget {
  const SeatUsageChip({super.key, required this.used, required this.limit});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final full = used >= limit;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sm, vertical: AppDimens.xs),
      decoration: BoxDecoration(
        color: full ? AppColors.errorSurface : AppColors.sageLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Text(
        context.l10n.tierSeatUsage(used, limit),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: full ? AppColors.error : AppColors.sageDark,
        ),
      ),
    );
  }
}

/// Upsell dứt khoát khi BE trả `ERR_TIER_SEAT_LIMIT` (tier-gate §8.1 state 4).
class TierUpsellBanner extends StatelessWidget {
  const TierUpsellBanner({
    super.key,
    required this.limit,
    required this.onUpgrade,
    required this.onDismiss,
    this.isMaxTier = false,
  });

  final int limit;
  final VoidCallback? onUpgrade;
  final VoidCallback onDismiss;

  /// Đã ở gói cao nhất (PREMIUM) → không còn gì để nâng, ẩn CTA nâng cấp.
  final bool isMaxTier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey<String>('tier-upsell'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Icon(Icons.workspace_premium_outlined,
            size: AppDimens.stateIcon, color: AppColors.sage),
        const SizedBox(height: AppDimens.sm),
        Text(
          l10n.tierUpsellTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimens.xs),
        Text(
          isMaxTier
              ? l10n.tierUpsellBodyMaxed(limit)
              : l10n.tierUpsellBody(limit),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.md),
        if (onUpgrade != null && !isMaxTier) ...<Widget>[
          AppButton(
            key: const ValueKey<String>('tier-upsell-upgrade'),
            label: l10n.tierUpgradeToPremium,
            onPressed: onUpgrade,
          ),
          const SizedBox(height: AppDimens.sm),
        ],
        AppButton(
          label: l10n.tierClose,
          variant: AppButtonVariant.secondary,
          onPressed: onDismiss,
        ),
      ],
    );
  }
}
