import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/money_format.dart';
import '../domain/receipt_scan_result.dart';

/// Tiền trên hoá đơn: `formatVnd` khi VND, ngược lại số + mã tiền tệ (§13.2).
String formatReceiptAmount(double amount, String currency) {
  if (currency.toUpperCase() == 'VND') return formatVnd(amount);
  return '${NumberFormat.decimalPattern().format(amount)} $currency';
}

/// Đầu màn kết quả (§13.2): cửa hàng, ngày, tổng tiền — MỖI field null ẩn
/// riêng; cả 3 null thì chỉ còn dòng đếm.
class ReceiptSummaryHeader extends StatelessWidget {
  const ReceiptSummaryHeader({
    super.key,
    required this.meta,
    required this.matchedLines,
    required this.unmatchedCount,
  });

  final ReceiptScanMeta? meta;
  final int matchedLines;
  final int unmatchedCount;

  @override
  Widget build(BuildContext context) {
    final storeName = meta?.storeName?.trim();
    final date = meta?.purchaseDate;
    final total = meta?.totalAmount;
    final details = <String>[
      if (date != null) DateFormat('dd/MM/yyyy').format(date),
      if (total != null)
        context.l10n.receiptSummaryTotal(
          formatReceiptAmount(total, meta?.currency ?? 'VND'),
        ),
    ];
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (storeName != null && storeName.isNotEmpty)
            Text(
              storeName,
              key: const ValueKey<String>('receipt-header-store'),
              style: textTheme.titleMedium,
            ),
          if (details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.xs),
              child: Text(
                details.join(' · '),
                key: const ValueKey<String>('receipt-header-details'),
                style: textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              top: (storeName?.isNotEmpty ?? false) || details.isNotEmpty
                  ? AppDimens.xs
                  : 0,
            ),
            child: Text(
              context.l10n.receiptSummaryCounts(matchedLines, unmatchedCount),
              key: const ValueKey<String>('receipt-header-counts'),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
