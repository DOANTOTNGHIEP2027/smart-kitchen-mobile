import '../domain/cooking_session_step.dart';
import '../domain/cooking_session.dart';
import '../domain/cooking_session_result.dart';
import '../domain/ingredient_deduction.dart';

/// Parse 1 phần tử `recipes.steps[]` (#75) → [CookingSessionStep].
///
/// Quy đổi `duration_minutes` (PHÚT) → `durationSeconds` (GIÂY) tại ĐÂY
/// (Implementation Guard #10). Bỏ qua bước này = timer chạy nhanh × 60.
CookingSessionStep mapCookingSessionStep(Map<String, dynamic> json) {
  final durationMinutes = json['duration_minutes'] as int?;
  return CookingSessionStep(
    stepNumber: json['step_number'] as int,
    instruction: json['instruction'] as String,
    durationSeconds:
        durationMinutes == null ? null : durationMinutes * 60,
  );
}

/// Parse shape `CookingSessionData` của OAS cooking-session.yaml.
CookingSession mapCookingSession(Map<String, dynamic> json) {
  return CookingSession(
    id: json['id'] as String,
    householdId: json['householdId'] as String,
    recipeId: json['recipeId'] as String,
    recipeName: json['recipeName'] as String,
    startedBy: json['startedBy'] as String,
    status: CookingSessionStatusWireX.fromWire(json['status'] as String),
    currentStep: json['currentStep'] as int,
    totalSteps: json['totalSteps'] as int,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'] as String),
  );
}

/// Parse `IngredientDeduction` — field `shortfallQuantity` camelCase theo OAS.
IngredientDeduction mapIngredientDeduction(Map<String, dynamic> json) {
  return IngredientDeduction(
    ingredientName: json['ingredientName'] as String,
    requiredQuantity: (json['requiredQuantity'] as num).toDouble(),
    requiredUnit: json['requiredUnit'] as String,
    deductedQuantity: (json['deductedQuantity'] as num).toDouble(),
    shortfallQuantity: (json['shortfallQuantity'] as num).toDouble(),
    matchedItemCount: json['matchedItemCount'] as int,
  );
}

/// Parse `CompleteSessionData` (shape của `POST /complete` 200 và `GET /{id}`).
CookingSessionResult mapCompleteSessionData(Map<String, dynamic> json) {
  return CookingSessionResult(
    session: mapCookingSession(json['session'] as Map<String, dynamic>),
    deductions: ((json['ingredientDeductions'] as List<dynamic>?)
            ?.map((Object? e) =>
                mapIngredientDeduction(e as Map<String, dynamic>))
            .toList(growable: false) ??
        const <IngredientDeduction>[]),
  );
}
