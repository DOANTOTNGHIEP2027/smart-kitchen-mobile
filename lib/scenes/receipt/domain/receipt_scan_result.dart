import 'receipt_matched_item.dart';
import 'receipt_unmatched_item.dart';

/// D-A: dòng matched có matchConfidence < 0.9 hiện badge "Kiểm tra lại".
/// BE bảo đảm matched ≥ 0.85, nên dải có badge là [0.85, 0.9).
const double kReceiptMatchReviewThreshold = 0.9;

class ReceiptScanMeta {
  const ReceiptScanMeta({
    required this.scanId,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    required this.currency,
  });

  final String scanId;
  final String? storeName;
  final DateTime? purchaseDate; // ngày local, parse từ 'yyyy-MM-dd'
  final double? totalAmount;
  final String currency;

  bool get isVnd => currency.toUpperCase() == 'VND';
}

class ReceiptScanResult {
  const ReceiptScanResult({
    required this.meta,
    required this.matchedItems,
    required this.unmatchedItems,
  });

  final ReceiptScanMeta meta;
  final List<ReceiptMatchedItem> matchedItems;
  final List<ReceiptUnmatchedItem> unmatchedItems;
}
