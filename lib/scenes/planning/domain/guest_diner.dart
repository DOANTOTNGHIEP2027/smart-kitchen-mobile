import '../../profile/domain/allergen.dart';

/// Khách ăn tạm thời (flexible-meal-planning-screens.md §5.2).
///
/// `mealPlanId` là id KẾ HOẠCH TUẦN (`meal_plans`). #201: khách có thể gắn
/// riêng một bữa — `slotId` khác `null`; `null` = khách cả tuần (OD-06 đã
/// đóng).
class GuestDiner {
  const GuestDiner({
    required this.id,
    required this.mealPlanId,
    this.slotId,
    this.displayName,
    required this.allergens,
    required this.addedBy,
    required this.createdAt,
  });

  final String id;
  final String mealPlanId;

  /// #201: bữa mà khách ăn cùng; `null` = cả tuần.
  final String? slotId;
  final String? displayName;
  final List<Allergen> allergens;
  final String addedBy;
  final DateTime createdAt;

  factory GuestDiner.fromJson(Map<String, dynamic> json) => GuestDiner(
        id: json['id'] as String,
        mealPlanId: json['mealPlanId'] as String,
        slotId: json['slotId'] as String?,
        displayName: json['displayName'] as String?,
        allergens: ((json['allergens'] as List?) ?? const <dynamic>[])
            .map((Object? e) => Allergen.fromJson(e! as Map<String, dynamic>))
            .toList(growable: false),
        addedBy: json['addedBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Tên đã trim, `null` nếu khách chưa đặt tên — UI tự dùng chuỗi l10n fallback.
  String? get trimmedName {
    final name = displayName?.trim();
    return name == null || name.isEmpty ? null : name;
  }
}
