import 'receipt_scan_result.dart';

class ReceiptMatchedItem {
  const ReceiptMatchedItem({
    required this.lineKey,
    required this.shoppingItemId,
    required this.shoppingItemName,
    required this.rawName,
    this.mappedName,
    required this.quantity,
    required this.unit,
    this.unitPrice,
    this.totalPrice,
    required this.matchConfidence,
  });

  /// Key riêng của DÒNG hoá đơn ('m0', 'm1', …) — sinh ở mapper theo vị trí.
  /// Chỉ dùng làm key UI/chọn; KHÔNG gửi BE. 2 dòng cùng shoppingItemId có 2
  /// lineKey (D23).
  final String lineKey;

  /// id thật của món trong danh sách đi chợ.
  final String shoppingItemId;

  /// Tên món trong danh sách — để người dùng biết đang đánh dấu cái gì.
  final String shoppingItemName;

  /// Chữ in trên hoá đơn.
  final String rawName;
  final String? mappedName;

  /// Chỉ hiển thị, không cập nhật số lượng món (Q7).
  final double quantity;

  /// Chuỗi tự do của hoá đơn, chỉ hiển thị.
  final String unit;
  final double? unitPrice;
  final double? totalPrice;

  /// Điểm giống tên với món trong danh sách (BE), không phải điểm catalog AI.
  final double matchConfidence;

  bool get needsReview => matchConfidence < kReceiptMatchReviewThreshold;
}
