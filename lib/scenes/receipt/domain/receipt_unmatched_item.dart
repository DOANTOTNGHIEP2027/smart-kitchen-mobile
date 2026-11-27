import '../../inventory/domain/expiry_source.dart';
import '../../inventory/domain/unit_option.dart';

enum ReceiptConfirmStatus { pending, confirming, confirmed, failed }

const Object _unset = Object();

class ReceiptUnmatchedItem {
  const ReceiptUnmatchedItem({
    required this.itemId,
    required this.name,
    this.category,
    this.quantity,
    this.unit,
    required this.rawName,
    required this.rawQuantity,
    required this.rawUnit,
    this.unitPrice,
    this.totalPrice,
    this.matchConfidence,
    this.expiryDate,
    this.suggestedExpiry,
    this.expirySource = ExpirySource.none,
    this.confirmStatus = ReceiptConfirmStatus.pending,
    this.confirmError,
  });

  /// UUID tạm của BE, chỉ làm key danh sách.
  final String itemId;

  /// Sửa được — mặc định mappedName ?? rawName.
  final String name;

  /// Sửa được — mặc định suggestedCategory.
  final String? category;

  /// Sửa được — mặc định = rawQuantity.
  final double? quantity;

  /// BẮT ĐẦU null, phải chọn từ unitOptions (D9).
  final String? unit;
  final String rawName;
  final double rawQuantity;
  final String rawUnit;
  final double? unitPrice;
  final double? totalPrice;

  /// Điểm catalog AI — chỉ nhãn xám tham khảo, không phải badge cảnh báo.
  final double? matchConfidence;

  /// #239: hạn gửi khi lưu — mặc định là [suggestedExpiry] BE gợi ý, sửa được.
  final DateTime? expiryDate;
  final DateTime? suggestedExpiry;
  final ExpirySource expirySource;
  final ReceiptConfirmStatus confirmStatus;

  /// MÃ lỗi, không phải câu chữ: 'INVALID_RECEIPT_ITEM', 'SAVE_FAILED' hoặc
  /// ApiException.code. Scene map sang l10n (§13.4).
  final String? confirmError;

  /// Cùng luật với OcrItem.isValidForConfirm (#57) — không viết khác đi.
  bool get isValidForConfirm {
    if (name.trim().isEmpty || quantity == null || unit == null) return false;
    if (quantity! <= 0) return false;
    final matches = unitOptions.where((option) => option.value == unit);
    if (matches.isEmpty) return false;
    return !matches.first.isWholeNumber || quantity! % 1 == 0;
  }

  /// Ngày đang hiện vẫn là ngày BE gợi ý (người dùng chưa đổi).
  bool get isExpirySuggested =>
      expirySource.isSuggested && expiryDate != null && expiryDate == suggestedExpiry;

  /// Đang ghi hoặc đã ghi — khoá mọi field và nút.
  bool get isLocked =>
      confirmStatus == ReceiptConfirmStatus.confirming ||
      confirmStatus == ReceiptConfirmStatus.confirmed;

  /// Sentinel `_unset` như OcrItem.copyWith: truyền null là XOÁ field.
  ReceiptUnmatchedItem copyWith({
    String? name,
    Object? category = _unset,
    Object? quantity = _unset,
    Object? unit = _unset,
    Object? expiryDate = _unset,
    ReceiptConfirmStatus? confirmStatus,
    Object? confirmError = _unset,
  }) {
    return ReceiptUnmatchedItem(
      itemId: itemId,
      name: name ?? this.name,
      category:
          identical(category, _unset) ? this.category : category as String?,
      quantity: identical(quantity, _unset)
          ? this.quantity
          : (quantity as num?)?.toDouble(),
      unit: identical(unit, _unset) ? this.unit : unit as String?,
      rawName: rawName,
      rawQuantity: rawQuantity,
      rawUnit: rawUnit,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      matchConfidence: matchConfidence,
      expiryDate: identical(expiryDate, _unset)
          ? this.expiryDate
          : expiryDate as DateTime?,
      suggestedExpiry: suggestedExpiry,
      expirySource: expirySource,
      confirmStatus: confirmStatus ?? this.confirmStatus,
      confirmError: identical(confirmError, _unset)
          ? this.confirmError
          : confirmError as String?,
    );
  }
}
