import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/cards/app_card.dart';
import '../stores/family_store.dart';
import 'tier_widgets.dart';

/// Dải "Household plan" trong FamilyScreen (tier-gate-screens.md §10.2) —
/// hiện cho MỌI vai trò. Nút đổi gói luôn hiện; người không phải OWNER thấy nút
/// disabled + tooltip giải thích (Guard 6), không ẩn.
class HouseholdPlanStrip extends StatelessWidget {
  const HouseholdPlanStrip({
    super.key,
    required this.store,
    required this.onChangePlan,
  });

  final FamilyStore store;
  final VoidCallback onChangePlan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final seat = store.seatInfo;
      // Roster chưa tải → ẩn im lặng, không phải lỗi.
      if (seat == null) return const SizedBox.shrink();
      final isOwner = store.isOwner;
      final button = AppButton(
        key: const ValueKey<String>('household-plan-change'),
        label: l10n.tierChangePlan,
        variant: AppButtonVariant.secondary,
        expanded: false,
        onPressed: isOwner ? onChangePlan : null,
      );
      return AppCard(
        key: const ValueKey<String>('household-plan-strip'),
        child: Wrap(
          spacing: AppDimens.sm,
          runSpacing: AppDimens.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              l10n.tierPlanCurrent(tierLabel(l10n, seat.tier)),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SeatUsageChip(used: seat.used, limit: seat.limit),
            if (isOwner)
              button
            else
              Tooltip(
                message: store.isRemoteViewer
                    ? l10n.tierViewerOnlyTooltip
                    : l10n.tierOwnerOnlyTooltip,
                child: button,
              ),
          ],
        ),
      );
    });
  }
}
