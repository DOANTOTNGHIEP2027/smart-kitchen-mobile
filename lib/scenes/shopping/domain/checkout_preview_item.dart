import '../../../utils/date_format.dart';
import '../../inventory/domain/expiry_source.dart';

const Object _unset = Object();

/// Một dòng của màn "Cất vào kho" (#239) — dữ liệu preview của BE cộng phần
/// người dùng sửa ([selected], [quantity], [unit], [expiryDate]).
class CheckoutPreviewItem {
  const CheckoutPreviewItem({
    required this.shoppingItemId,
    required this.version,
    required this.name,
    this.category,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    required this.expirySource,
    required this.duplicate,
    this.existingItemId,
    this.selected = true,
    this.expiryEdited = false,
  });

  factory CheckoutPreviewItem.fromJson(Map<String, dynamic> json) =>
      CheckoutPreviewItem(
        shoppingItemId: json['shoppingItemId'] as String,
        version: (json['version'] as num).toInt(),
        name: json['name'] as String,
        category: json['category'] as String?,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        expiryDate: parseApiDate(json['suggestedExpiryDate']),
        expirySource: ExpirySource.fromJson(json['expirySource']),
        duplicate: json['duplicate'] as bool? ?? false,
        existingItemId: json['existingItemId'] as String?,
      );

  final String shoppingItemId;
  final int version;
  final String name;
  final String? category;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final ExpirySource expirySource;
  final bool duplicate;
  final String? existingItemId;
  final bool selected;

  /// Người dùng đã tự chọn/xoá hạn — chip thôi hiện chữ "gợi ý".
  final bool expiryEdited;

  bool get isExpirySuggested => !expiryEdited && expiryDate != null && expirySource.isSuggested;

  /// Payload một phần tử của `POST /inventory-items/batch`.
  Map<String, dynamic> toBatchPayload() => <String, dynamic>{
        'name': name,
        if (category != null) 'category': category,
        'quantity': quantity,
        'unit': unit,
        if (expiryDate != null) 'expiryDate': toApiDate(expiryDate!),
        'sourceShoppingItemId': shoppingItemId,
        'sourceShoppingItemVersion': version,
      };

  CheckoutPreviewItem copyWith({
    int? version,
    bool? selected,
    double? quantity,
    String? unit,
    Object? expiryDate = _unset,
    bool? expiryEdited,
  }) =>
      CheckoutPreviewItem(
        shoppingItemId: shoppingItemId,
        version: version ?? this.version,
        name: name,
        category: category,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        expiryDate: identical(expiryDate, _unset) ? this.expiryDate : expiryDate as DateTime?,
        expirySource: expirySource,
        duplicate: duplicate,
        existingItemId: existingItemId,
        selected: selected ?? this.selected,
        expiryEdited: expiryEdited ?? this.expiryEdited,
      );
}
