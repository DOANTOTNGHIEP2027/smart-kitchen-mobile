import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_dimens.dart';
import '../../../constants/app_colors.dart';
import '../../../domain/shared/budget_period.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/cards/app_card.dart';
import '../domain/household_tier.dart';
import '../stores/family_store.dart';
import '../stores/form_status.dart';
import 'tier_widgets.dart';

/// Dải "Household plan" trong FamilyScreen (tier-gate-screens.md §10.2) —
/// hiện cho MỌI vai trò. Nút đổi gói luôn hiện; người không phải OWNER thấy nút
/// disabled + tooltip giải thích (Guard 6), không ẩn.
class HouseholdPlanStrip extends StatelessWidget {
  const HouseholdPlanStrip({
    super.key,
    required this.store,
    required this.onChangePlan,
    required this.onEditBudget,
  });

  final FamilyStore store;
  final VoidCallback onChangePlan;
  final VoidCallback onEditBudget;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
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
            const Divider(height: AppDimens.lg),
            _budgetRow(context, l10n),
            // Lời mời PREMIUM chỉ phụ thuộc claim tier — độc lập trạng thái
            // ngân sách (§19.5 điểm chạm 1).
            if (seat.tier != HouseholdTier.premium)
              TextButton(
                key: const ValueKey<String>('budget-upsell'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: onChangePlan,
                child: Text(l10n.budgetUpsell),
              ),
          ],
        ),
      );
    });
  }

  /// 4 trạng thái LOẠI TRỪ NHAU P1–P4 (§19.7). Đọc `budgetLoadStatus` TRƯỚC
  /// `hasBudget`: tải lỗi KHÔNG BAO GIỜ hiện thành "chưa đặt" — nếu không, OWNER
  /// sẽ upsert ghi đè ngân sách đang tồn tại (Guard #12).
  Widget _budgetRow(BuildContext context, AppLocalizations l10n) {
    final status = store.budgetLoadStatus;
    final b = store.budget;
    final Widget text = switch (status) {
      FormStatus.failure => Row(
          children: <Widget>[
            Flexible(
              child: Text(l10n.budgetLoadFailed,
                  key: const ValueKey<String>('budget-load-failed'),
                  style: const TextStyle(color: AppColors.error)),
            ),
            TextButton(
              key: const ValueKey<String>('budget-retry'),
              onPressed: store.loadBudget,
              child: Text(l10n.retry),
            ),
          ],
        ),
      FormStatus.success when store.hasBudget => Text(
          b!.period == BudgetPeriod.monthly
              ? l10n.budgetCurrentMonthly(formatVnd(b.amount!))
              : l10n.budgetCurrentWeekly(formatVnd(b.amount!)),
          key: const ValueKey<String>('budget-current'),
        ),
      FormStatus.success => Text(l10n.budgetNotSet,
          key: const ValueKey<String>('budget-not-set')),
      _ => Text(l10n.budgetLoading,
          key: const ValueKey<String>('budget-loading')),
    };
    // Guard #14: nút LUÔN hiện; chỉ bấm được khi OWNER VÀ đã biết giá trị hiện tại.
    final button = AppButton(
      key: const ValueKey<String>('budget-edit'),
      label: store.hasBudget ? l10n.budgetEdit : l10n.budgetSet,
      variant: AppButtonVariant.secondary,
      expanded: false,
      onPressed: store.canEditBudget ? onEditBudget : null,
    );
    final tooltip = !store.isOwner
        ? l10n.budgetOwnerOnlyTooltip
        : switch (status) {
            FormStatus.success => null,
            FormStatus.failure => l10n.budgetLoadFailed,
            _ => l10n.budgetLoadingTooltip,
          };
    return Row(
      children: <Widget>[
        Expanded(child: text),
        const SizedBox(width: AppDimens.sm),
        if (tooltip == null) button else Tooltip(message: tooltip, child: button),
      ],
    );
  }
}
