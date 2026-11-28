import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/receipt_matched_item.dart';
import 'receipt_summary_header.dart';
import '../../../utils/unit_label.dart';

/// Kết quả của 1 dòng sau `commitMatched()` (§9.1).
enum ReceiptLineOutcome { none, marked, failed, skipped }

/// 1 dòng hoá đơn khớp danh sách đi chợ (§13.2). 2 dòng cùng món vẫn là 2 tile
/// (key theo lineKey, D23). Badge "Kiểm tra lại" CHỈ khi matchConfidence < 0.9.
class ReceiptMatchedLineTile extends StatelessWidget {
  const ReceiptMatchedLineTile({
    super.key,
    required this.line,
    required this.currency,
    required this.selected,
    required this.locked,
    required this.outcome,
    required this.onToggle,
  });

  final ReceiptMatchedItem line;
  final String currency;
  final bool selected;
  final bool locked;
  final ReceiptLineOutcome outcome;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final price = line.totalPrice;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.xs,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Checkbox(
            key: ValueKey<String>('receipt-line-check-${line.lineKey}'),
            value: selected,
            onChanged: locked ? null : (_) => onToggle(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(line.shoppingItemName, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${context.l10n.receiptOnReceipt(line.rawName)} · '
                  '${formatQuantityWithUnitLabel(context.l10n, line.quantity, line.unit)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (line.needsReview || outcome != ReceiptLineOutcome.none)
                  Padding(
                    padding: const EdgeInsets.only(top: AppDimens.xs),
                    child: Wrap(
                      spacing: AppDimens.xs,
                      runSpacing: AppDimens.xs,
                      children: <Widget>[
                        if (line.needsReview)
                          ReceiptBadge(
                            key: ValueKey<String>(
                              'receipt-review-badge-${line.lineKey}',
                            ),
                            label: context.l10n.receiptBadgeReview,
                            background: AppColors.warningSurface,
                            foreground: AppColors.warning,
                          ),
                        if (outcome != ReceiptLineOutcome.none)
                          _outcomeBadge(context),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (price != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
              child: Text(
                formatReceiptAmount(price, currency),
                style: textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  Widget _outcomeBadge(BuildContext context) {
    final l10n = context.l10n;
    final key = ValueKey<String>('receipt-line-outcome-${line.lineKey}');
    return switch (outcome) {
      ReceiptLineOutcome.marked => ReceiptBadge(
          key: key,
          label: l10n.receiptMarkedBought,
          background: AppColors.successSurface,
          foreground: AppColors.success,
        ),
      ReceiptLineOutcome.failed => ReceiptBadge(
          key: key,
          label: l10n.receiptNotUpdated,
          background: AppColors.errorSurface,
          foreground: AppColors.error,
        ),
      _ => ReceiptBadge(
          key: key,
          label: l10n.receiptSkipped,
          background: AppColors.surfaceSubtle,
          foreground: AppColors.textSecondary,
        ),
    };
  }
}

/// Nhãn nhỏ dùng chung trong màn kết quả quét.
class ReceiptBadge extends StatelessWidget {
  const ReceiptBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
