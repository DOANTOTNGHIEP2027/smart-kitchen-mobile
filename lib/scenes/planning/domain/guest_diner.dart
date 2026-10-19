import '../../profile/domain/allergen.dart';

/// Khách ăn tạm thời (flexible-meal-planning-screens.md §5.2).
///
/// `mealPlanId` là id KẾ HOẠCH TUẦN (`meal_plans`) — BE thật
/// (`GuestDinerServiceImpl.requirePlan`) tra `MealPlanRepository`, không phải
/// `MealPlanSlot.id` như giả định D1 của thiết kế. Xem OPEN_DECISIONS OD-06.
class GuestDiner {
  const GuestDiner({
    required this.id,
    required this.mealPlanId,
    this.displayName,
    required this.allergens,
    required this.addedBy,
    required this.createdAt,
  });

  final String id;
  final String mealPlanId;
  final String? displayName;
  final List<Allergen> allergens;
  final String addedBy;
  final DateTime createdAt;

  factory GuestDiner.fromJson(Map<String, dynamic> json) => GuestDiner(
        id: json['id'] as String,
        mealPlanId: json['mealPlanId'] as String,
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
