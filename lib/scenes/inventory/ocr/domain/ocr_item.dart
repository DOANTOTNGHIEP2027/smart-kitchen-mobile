import '../../domain/unit_option.dart';

enum OcrConfirmStatus { pending, confirming, confirmed, failed }

const Object _unset = Object();

class OcrItem {
  const OcrItem({
    required this.itemId,
    required this.name,
    this.category,
    required this.quantity,
    required this.unit,
    required this.needsManualReview,
    required this.rawQuantity,
    required this.rawUnit,
    this.expiryEstimate,
    required this.duplicate,
    this.existingItemId,
    this.confirmStatus = OcrConfirmStatus.pending,
    this.confirmError,
  });

  final String itemId;
  final String name;
  final String? category;
  final double? quantity;
  final String? unit;
  final bool needsManualReview;
  final double? rawQuantity;
  final String? rawUnit;
  final DateTime? expiryEstimate;
  final bool duplicate;
  final String? existingItemId;
  final OcrConfirmStatus confirmStatus;
  final String? confirmError;

  bool get isValidForConfirm {
    if (name.trim().isEmpty || quantity == null || unit == null) return false;
    if (quantity! <= 0) return false;
    final matches = unitOptions.where((option) => option.value == unit);
    if (matches.isEmpty) return false;
    return !matches.first.isWholeNumber || quantity! % 1 == 0;
  }

  OcrItem copyWith({
    String? name,
    Object? category = _unset,
    Object? quantity = _unset,
    Object? unit = _unset,
    bool? needsManualReview,
    Object? expiryEstimate = _unset,
    OcrConfirmStatus? confirmStatus,
    Object? confirmError = _unset,
  }) {
    return OcrItem(
      itemId: itemId,
      name: name ?? this.name,
      category:
          identical(category, _unset) ? this.category : category as String?,
      quantity:
          identical(quantity, _unset) ? this.quantity : quantity as double?,
      unit: identical(unit, _unset) ? this.unit : unit as String?,
      needsManualReview: needsManualReview ?? this.needsManualReview,
      rawQuantity: rawQuantity,
      rawUnit: rawUnit,
      expiryEstimate: identical(expiryEstimate, _unset)
          ? this.expiryEstimate
          : expiryEstimate as DateTime?,
      duplicate: duplicate,
      existingItemId: existingItemId,
      confirmStatus: confirmStatus ?? this.confirmStatus,
      confirmError: identical(confirmError, _unset)
          ? this.confirmError
          : confirmError as String?,
    );
  }
}
