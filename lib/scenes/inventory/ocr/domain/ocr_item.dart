import '../../domain/expiry_source.dart';
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
    this.expirySource = ExpirySource.none,
    this.suggestedExpiry,
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

  /// #239: nguồn của hạn BE trả ([suggestedExpiry]) — AI hoặc BE tự gợi ý.
  final ExpirySource expirySource;
  final DateTime? suggestedExpiry;
  final bool duplicate;
  final String? existingItemId;
  final OcrConfirmStatus confirmStatus;
  final String? confirmError;

  /// Ngày đang hiện vẫn là ngày BE gợi ý (người dùng chưa đổi).
  bool get isExpirySuggested =>
      expirySource.isSuggested && expiryEstimate != null && expiryEstimate == suggestedExpiry;

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
      expirySource: expirySource,
      suggestedExpiry: suggestedExpiry,
      duplicate: duplicate,
      existingItemId: existingItemId,
      confirmStatus: confirmStatus ?? this.confirmStatus,
      confirmError: identical(confirmError, _unset)
          ? this.confirmError
          : confirmError as String?,
    );
  }
}
