import '../domain/receipt_matched_item.dart';
import '../domain/receipt_scan_result.dart';
import '../domain/receipt_unmatched_item.dart';

/// Parse `data` của `POST /api/v1/receipts/scan` — key camelCase
/// (receipt-scan.yaml `ReceiptScanResponse`).
class ReceiptMapper {
  const ReceiptMapper._();

  static ReceiptScanResult scanResultFromJson(Map<String, dynamic> json) {
    final matched = json['matchedItems'] as List<dynamic>? ?? const <dynamic>[];
    final unmatched =
        json['unmatchedItems'] as List<dynamic>? ?? const <dynamic>[];
    return ReceiptScanResult(
      meta: ReceiptScanMeta(
        scanId: json['scanId'] as String,
        storeName: _nonBlank(json['storeName']),
        purchaseDate: _date(json['purchaseDate'] as String?),
        totalAmount: (json['totalAmount'] as num?)?.toDouble(),
        currency: _nonBlank(json['currency']) ?? 'VND',
      ),
      matchedItems: <ReceiptMatchedItem>[
        for (var i = 0; i < matched.length; i++)
          _matched(Map<String, dynamic>.from(matched[i] as Map), i),
      ],
      unmatchedItems: <ReceiptUnmatchedItem>[
        for (final raw in unmatched)
          _unmatched(Map<String, dynamic>.from(raw as Map)),
      ],
    );
  }

  /// 'yyyy-MM-dd' → DateTime local (không có giờ/múi giờ).
  static DateTime? _date(String? value) =>
      value == null ? null : DateTime.tryParse(value);

  /// Contract: chuỗi rỗng coi như null (`mappedName` rỗng → null).
  static String? _nonBlank(Object? value) {
    final text = value as String?;
    return text == null || text.trim().isEmpty ? null : text;
  }

  static ReceiptMatchedItem _matched(Map<String, dynamic> json, int index) =>
      ReceiptMatchedItem(
        lineKey: 'm$index',
        shoppingItemId: json['shoppingItemId'] as String,
        shoppingItemName: json['shoppingItemName'] as String,
        rawName: json['rawName'] as String,
        mappedName: _nonBlank(json['mappedName']),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        totalPrice: (json['totalPrice'] as num?)?.toDouble(),
        matchConfidence: (json['matchConfidence'] as num).toDouble(),
      );

  static ReceiptUnmatchedItem _unmatched(Map<String, dynamic> json) {
    final rawName = json['rawName'] as String;
    final quantity = (json['quantity'] as num).toDouble();
    return ReceiptUnmatchedItem(
      itemId: json['itemId'] as String,
      name: _nonBlank(json['mappedName']) ?? rawName,
      category: _nonBlank(json['suggestedCategory']),
      quantity: quantity,
      unit: null, // D9 — không lấy rawUnit
      rawName: rawName,
      rawQuantity: quantity,
      rawUnit: json['unit'] as String,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble(),
    );
  }
}
