import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../l10n/app_localizations.dart';
import '../../stores/session_store.dart';
import '../../utils/l10n_x.dart';
import '../../utils/api_error_l10n.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/feature_banner.dart';
import '../../widgets/states/app_empty_view.dart';
import '../../widgets/states/view_state.dart';
import 'domain/household_roster.dart';
import 'domain/household_tier.dart';
import 'stores/family_store.dart';
import 'stores/form_status.dart';
import 'widgets/tier_widgets.dart';

/// Tự nâng/hạ gói household — công tắc demo/QA, KHÔNG phải mua hàng thật
/// (tier-gate-screens.md §9). Disclaimer hiện ở banner cố định VÀ trong dialog
/// xác nhận (Guard 8). Tự guard OWNER ngay tại build (Guard 7).
class TierUpgradeScreen extends StatefulWidget {
  const TierUpgradeScreen({super.key});

  @override
  State<TierUpgradeScreen> createState() => _TierUpgradeScreenState();
}

class _TierUpgradeScreenState extends State<TierUpgradeScreen> {
  late final FamilyStore _store = Get.find<FamilyStore>();
  late final SessionStore _session = Get.find<SessionStore>();
  bool _isRefreshingClaims = false;
  bool _refreshClaimsFailed = false;

  @override
  void initState() {
    super.initState();
    // Lần trước rời màn khi đang submit → dispose không xoá được kết quả cũ.
    _store.clearTierUpdateStatus();
    // Deep-link thẳng vào đây → cần roster để biết isOwner + số ghế.
    if (_store.rosterState is! SuccessState<HouseholdRoster>) {
      unawaited(_store.loadRoster());
    }
  }

  @override
  void dispose() {
    _store.clearTierUpdateStatus();
    super.dispose();
  }

  Future<void> _retryLoadTier() async {
    setState(() {
      _isRefreshingClaims = true;
      _refreshClaimsFailed = false;
    });
    await _session.refreshClaims();
    if (!mounted) return;
    setState(() {
      _isRefreshingClaims = false;
      _refreshClaimsFailed = _store.tier == HouseholdTier.unknown;
    });
  }

  Future<void> _changeTo(HouseholdTier target) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tierConfirmTitle(tierLabel(l10n, target))),
        content: Text(l10n.tierDisclaimer, key: const ValueKey<String>('tier-dialog-disclaimer')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey<String>('tier-dialog-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.tierConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _store.updateTier(target);
    if (!ok || !mounted) return;
    // Nhãn lấy từ `target` (BE đã nhận), không từ `_store.tier`: refreshClaims()
    // có thể đã thất bại im lặng và claim vẫn là tier cũ (Guard 4).
    // Claim chưa đổi theo (refresh lỗi) → nói rõ thay vì để màn hình hiện gói
    // cũ mà toast lại báo gói mới (người dùng dễ bấm đổi lần nữa).
    final label = tierLabel(l10n, target);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_store.tier == target
          ? l10n.tierUpdated(label)
          : l10n.tierUpdatedClaimStale(label)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.tierUpgradeTitle,
      body: Observer(builder: (_) {
        if (!_store.isOwner) {
          return AppEmptyView(
            key: const ValueKey<String>('tier-owner-only'),
            icon: Icons.lock_outline,
            message: l10n.tierOwnerOnlyBlocked,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppDimens.md),
          children: <Widget>[
            FeatureBanner(
              key: const ValueKey<String>('tier-disclaimer'),
              message: l10n.tierDisclaimer,
              isError: false,
              margin: const EdgeInsets.only(bottom: AppDimens.md),
            ),
            ..._body(l10n),
          ],
        );
      }),
    );
  }

  List<Widget> _body(AppLocalizations l10n) {
    final tier = _store.tier;
    final submitting = _store.isSubmittingTierUpdate;
    if (tier == HouseholdTier.unknown) {
      return <Widget>[
        AppCard(
          key: const ValueKey<String>('tier-unknown'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l10n.tierUnknownBody),
              const SizedBox(height: AppDimens.sm),
              AppButton(
                key: const ValueKey<String>('tier-retry'),
                label: l10n.tierRetryLoad,
                isLoading: _isRefreshingClaims,
                onPressed: _retryLoadTier,
              ),
              if (_refreshClaimsFailed) ...<Widget>[
                const SizedBox(height: AppDimens.sm),
                Text(
                  l10n.tierRetryFailed,
                  key: const ValueKey<String>('tier-retry-failed'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ];
    }
    final seat = _store.seatInfo;
    final isFree = tier == HouseholdTier.free;
    return <Widget>[
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.tierPlanCurrent(tierLabel(l10n, tier)),
              key: const ValueKey<String>('tier-current'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.sm),
            for (final line in <String>[
              l10n.tierCompareFree,
              l10n.tierComparePremium,
              l10n.tierCompareSpend,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: AppColors.sage),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(child: Text(line)),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppDimens.md),
      // Roster cần cho cảnh báo vượt ghế khi hạ cấp — không im lặng khi lỗi.
      if (!isFree && _store.rosterState is LoadingState<HouseholdRoster>)
        const Padding(
          padding: EdgeInsets.only(bottom: AppDimens.md),
          child: LinearProgressIndicator(
              key: ValueKey<String>('tier-roster-loading')),
        ),
      if (!isFree && _store.rosterState is ErrorState<HouseholdRoster>) ...<Widget>[
        FeatureBanner(
          key: const ValueKey<String>('tier-roster-error'),
          message: l10n.tierRosterFailed,
          margin: const EdgeInsets.only(bottom: AppDimens.xs),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _store.loadRoster,
            child: Text(l10n.retry),
          ),
        ),
      ],
      if (!isFree &&
          seat != null &&
          seat.used > HouseholdTier.free.remoteViewerSeatLimit)
        FeatureBanner(
          key: const ValueKey<String>('tier-downgrade-warning'),
          message: l10n.tierDowngradeWarning(seat.used),
          isError: false,
          margin: const EdgeInsets.only(bottom: AppDimens.md),
        ),
      if (_store.tierUpdateStatus == FormStatus.failure &&
          _store.tierUpdateError != null)
        FeatureBanner(
          key: const ValueKey<String>('tier-update-error'),
          message: apiErrorMessage(l10n, _store.tierUpdateError),
          margin: const EdgeInsets.only(bottom: AppDimens.md),
        ),
      AppButton(
        key: const ValueKey<String>('tier-change'),
        label: isFree ? l10n.tierUpgradeToPremium : l10n.tierDowngradeToFree,
        variant:
            isFree ? AppButtonVariant.primary : AppButtonVariant.secondary,
        isLoading: submitting,
        onPressed: () =>
            _changeTo(isFree ? HouseholdTier.premium : HouseholdTier.free),
      ),
    ];
  }
}
