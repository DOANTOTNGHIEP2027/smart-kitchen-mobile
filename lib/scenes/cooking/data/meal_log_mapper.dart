import '../domain/food_item_detected.dart';
import '../domain/meal_log_entry.dart';
import '../domain/meal_nutrition_macros.dart';

/// Parse `MealLogResponse` (#77) — CAMELCASE theo OAS `meal-log-nutrition.yaml`
/// và BE `MealLogResponse.java` thật.
///
/// ⚠️ Một số đoạn design doc cũ (meal-log-screen §5.1/§6) viết snake_case
/// (`household_id`, `calories_kcal`...) — đã đối chiếu OAS + BE 2026-09-15,
/// camelCase là đúng. Parse sai key không throw, chỉ lặng lẽ về `null`.
class MealLogMapper {
  static MealLogEntry fromJson(
    Map<String, dynamic> json, {
    required MealEntryStatus status,
  }) {
    return MealLogEntry(
      id: json['id'] as String,
      householdId: json['householdId'] as String,
      memberId: json['memberId'] as String,
      loggedBy: json['loggedBy'] as String,
      sessionId: json['sessionId'] as String?,
      description: json['description'] as String?,
      // Guard #11: coerce qua num — `as double?` throw khi jsonDecode parse int.
      caloriesKcal: (json['caloriesKcal'] as num?)?.toDouble(),
      nutrition: json['nutrition'] == null
          ? null
          : MealNutritionMacros.fromJson(
              json['nutrition'] as Map<String, dynamic>),
      foodItemsDetected: (json['foodItemsDetected'] as List?)
          ?.map((e) => FoodItemDetected.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiresConfirmation: json['requiresConfirmation'] as bool,
      confirmedByUser: json['confirmedByUser'] as bool,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      status: status,
    );
  }
}