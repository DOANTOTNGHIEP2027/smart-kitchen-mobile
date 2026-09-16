import '../../../data/network/api_exception.dart';
import '../domain/meal_plan_slot.dart';

/// Cú pháp map JSON ↔ domain. Khác inventory-management, map ở tầng API class
/// trực tiếp ( không tách file mapper) vì response shape của plan vs vote khác
/// nhau hoàn toàn — tách ra chỉ dài thêm. Bám pattern profile_api.dart.

class MealPlanMapper {
  MealPlanMapper._();

  static MealPlanDto planFromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? const <dynamic>[];
    return MealPlanDto(
      id: json['id'] as String,
      householdId: json['householdId'] as String,
      weekStart: DateTime.parse('${json['weekStart']}T00:00:00Z'),
      slots: slotsJson
          .map((Object? s) => slotFromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static MealPlanSlot slotFromJson(Map<String, dynamic> json) {
    final dishesJson =
        json['dishes'] as List<dynamic>? ?? const <dynamic>[];
    return MealPlanSlot(
      id: json['id'] as String,
      slotDate: DateTime.parse('${json['slotDate']}T00:00:00Z'),
      mealTime: json['mealTime'] as String,
      dishes: dishesJson
          .map((Object? d) => dishFromJson(d as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Đọc `status`/`recipe` từ response `POST`/`PUT .../dishes`. HIGH-1:
  /// `sortOrder` parse khoan dung — không throw nếu thiếu.
  static MealPlanDish dishFromJson(Map<String, dynamic> json) {
    final recipeJson = json['recipe'] as Map<String, dynamic>?;
    return MealPlanDish(
      id: json['id'] as String,
      slotId: json['slotId'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ??
          MealPlanDish.unknownSortOrder,
      status: _parseDishStatus(json['status'] as String?),
      recipe: recipeJson == null
          ? null
          : AssignedRecipeSummary(
              recipeId: recipeJson['recipeId'] as String,
              recipeName: recipeJson['recipeName'] as String,
              source: recipeJson['source'] as String? ?? 'AI',
            ),
    );
  }

  static DishUiStatus _parseDishStatus(String? raw) {
    switch (raw) {
      case 'EMPTY':
        return DishUiStatus.empty;
      case 'SUGGESTED':
        return DishUiStatus.suggested;
      case 'VOTING':
        return DishUiStatus.voting;
      case 'CONFIRMED':
        return DishUiStatus.confirmed;
      default:
        return DishUiStatus.empty;
    }
  }

  /// Reason Romantic: kế thừa pattern từ inventory `_unwrap`.
  static Never throwFromError(Object? err) {
    if (err is ApiException) throw err;
    throw ServerException('ERR_UNKNOWN', err.toString());
  }
}
