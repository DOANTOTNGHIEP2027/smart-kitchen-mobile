import '../domain/ocr_item.dart';
import '../domain/ocr_scan_result.dart';

abstract final class OcrMapper {
  static OcrScanResult scanResultFromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return OcrScanResult(
      scanId: json['scanId'] as String,
      items: rawItems
          .map((raw) => itemFromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(growable: false),
    );
  }

  static OcrItem itemFromJson(Map<String, dynamic> json) {
    return OcrItem(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      needsManualReview: json['needsManualReview'] as bool? ?? false,
      rawQuantity: (json['rawQuantity'] as num?)?.toDouble(),
      rawUnit: json['rawUnit'] as String?,
      expiryEstimate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      duplicate: json['duplicate'] as bool? ?? false,
      existingItemId: json['existingItemId'] as String?,
    );
  }
}
