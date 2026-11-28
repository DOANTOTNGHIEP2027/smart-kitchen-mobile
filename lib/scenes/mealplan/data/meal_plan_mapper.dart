import '../../../data/network/api_exception.dart';
import '../domain/meal_plan_slot.dart';
import '../domain/meal_suggestion.dart';
import '../domain/recipe_check.dart';

/// Cú pháp map JSON ↔ domain. Khác inventory-management, map ở tầng API class
/// trực tiếp ( không tách file mapper) vì response shape của plan vs vote khác
/// nhau hoàn toàn — tách ra chỉ dài thêm. Bám pattern profile_api.dart.

class MealPlanMapper {
  MealPlanMapper._();

  static MealPlanDto planFromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? const <dynamic>[];
    return MealPlanDto(
      status: json['status'] as String? ?? 'DRAFT',
      id: json['id'] as String,
      householdId: json['householdId'] as String,
      weekStart: DateTime.parse('${json['weekStart']}T00:00:00Z'),
      slots: slotsJson
          .map((Object? s) => slotFromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static MealPlanSlot slotFromJson(Map<String, dynamic> json) {
    final dishesJson = json['dishes'] as List<dynamic>? ?? const <dynamic>[];
    return MealPlanSlot(
      id: json['id'] as String,
      slotDate: DateTime.parse('${json['slotDate']}T00:00:00Z'),
      mealTime: json['mealTime'] as String,
      dishes: dishesJson
          .map((Object? d) => dishFromJson(d as Map<String, dynamic>))
          .toList(growable: false),
      // Field mới (khung bữa theo template + khoá bữa) — server cũ không trả
      // thì để null, tầng trên tự fallback theo mealTime/ngày.
      slotKey: _string(json['slotKey']),
      label: _string(json['label']),
      scheduledTime: _string(json['scheduledTime']),
      sortOrder: json['sortOrder'] is num
          ? (json['sortOrder'] as num).toInt()
          : null,
      locked: _bool(json['locked']),
      allCooked: _bool(json['allCooked']),
    );
  }

  static String? _string(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;

  static bool? _bool(Object? raw) => raw is bool ? raw : null;

  /// `cookedAt` ISO-8601 → giờ máy; sai định dạng coi như chưa nấu.
  static DateTime? _dateTime(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

  /// `GET .../recipe-check` — parse khoan dung, thiếu field ⇒ rỗng.
  static RecipeCheckResult recipeCheckFromJson(Map<String, dynamic> json) {
    final conflicts =
        json['allergenConflicts'] as List<dynamic>? ?? const <dynamic>[];
    final missing =
        json['missingIngredients'] as List<dynamic>? ?? const <dynamic>[];
    return RecipeCheckResult(
      recipeId: _string(json['recipeId']) ?? '',
      allergenVerified: _bool(json['allergenVerified']) ?? false,
      allergenConflicts: conflicts
          .whereType<Map<String, dynamic>>()
          .map((c) => RecipeAllergenConflict(
                personType: _string(c['personType']) ?? 'MEMBER',
                personId: _string(c['personId']),
                name: _string(c['name']) ?? '',
                allergens: (c['allergens'] as List<dynamic>? ??
                        const <dynamic>[])
                    .whereType<Map<String, dynamic>>()
                    .map((a) => RecipeCheckAllergen(
                          // BE trả id allergen là số (SERIAL), không phải uuid.
                          id: a['id']?.toString(),
                          name: _string(a['name']) ?? '',
                        ))
                    .where((a) => a.name.isNotEmpty)
                    .toList(growable: false),
              ))
          .toList(growable: false),
      missingIngredients: missing
          .whereType<Map<String, dynamic>>()
          .map(_shortageFromJson)
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
      sortOrder:
          (json['sortOrder'] as num?)?.toInt() ?? MealPlanDish.unknownSortOrder,
      status: _parseDishStatus(json['status'] as String?),
      recipe: recipeJson == null
          ? null
          : AssignedRecipeSummary(
              recipeId: recipeJson['recipeId'] as String,
              recipeName: recipeJson['recipeName'] as String,
              source: recipeJson['source'] as String? ?? 'AI',
            ),
      missingIngredients: (json['missingIngredients'] as List<dynamic>?)
          ?.map((Object? m) => _shortageFromJson(m as Map<String, dynamic>))
          .toList(growable: false),
      cookedAt: _dateTime(json['cookedAt']),
      cookedSessionId: _string(json['cookedSessionId']),
    );
  }

  /// `DishIngredientShortage` (#201) — lượng ở đơn vị chuẩn của BE; đổi về
  /// literal đơn vị mà kho/đi chợ dùng (`unitOptions`).
  static IngredientItem _shortageFromJson(Map<String, dynamic> json) =>
      IngredientItem(
        name: json['ingredientName'] as String? ?? '',
        quantity: (json['shortfallQuantity'] as num?)?.toDouble() ?? 0,
        unit: switch (json['unit'] as String?) {
          'GRAM' => 'g',
          'MILLILITER' => 'ml',
          'PIECE' => 'quả',
          'UNIT' => 'cái',
          final other => other ?? '',
        },
      );

  static DishUiStatus _parseDishStatus(String? raw) {
    switch (raw) {
      case 'EMPTY':
        return DishUiStatus.empty;
      case 'SUGGESTED':
        return DishUiStatus.suggested;
      case 'VOTING':
        return DishUiStatus.suggested;
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
