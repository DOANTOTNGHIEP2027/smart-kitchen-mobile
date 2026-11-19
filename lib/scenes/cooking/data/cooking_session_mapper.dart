import '../domain/cooking_session_step.dart';
import '../domain/cooking_session.dart';
import '../domain/cooking_session_result.dart';
import '../domain/ingredient_deduction.dart';
import '../domain/missing_ingredient.dart';

/// Parse 1 phần tử `recipes.steps[]` (#75) → [CookingSessionStep].
///
/// Quy đổi `durationMinutes` (PHÚT) → `durationSeconds` (GIÂY) tại ĐÂY
/// (Implementation Guard #10). Bỏ qua bước này = timer chạy nhanh × 60.
CookingSessionStep mapCookingSessionStep(Map<String, dynamic> json) {
  // `Step` của recipe-core được serialize camelCase (recipe-core.yaml).
  // Không dùng snake_case ở đây: endpoint GET steps trả trực tiếp DTO này.
  final durationMinutes = json['durationMinutes'] as int?;
  return CookingSessionStep(
    stepNumber: json['stepNumber'] as int,
    instruction: json['instruction'] as String,
    durationSeconds: durationMinutes == null ? null : durationMinutes * 60,
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
    totalSteps: json['totalSteps'] as int,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'] as String),
    // `StepSnapshot` (cooking-session.yaml) cùng shape camelCase với Step
    // của recipe-core → dùng chung mapper, vẫn quy đổi phút → giây.
    stepsSnapshot: (json['stepsSnapshot'] as List<dynamic>?)
        ?.map((Object? e) => mapCookingSessionStep(e as Map<String, dynamic>))
        .toList(growable: false),
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

/// Parse `error.details` của 409 `ERR_INSUFFICIENT_STOCK_FOR_RECIPE`
/// (`InsufficientStockDetails`, OD-36).
///
/// Chịu lỗi: `details` thiếu/sai kiểu → list rỗng; item hỏng bị bỏ qua. Màn
/// nấu vẫn phải hiện sheet "thiếu nguyên liệu" kể cả khi list rỗng, nên ở đây
/// KHÔNG được throw.
List<MissingIngredient> mapMissingIngredients(Map<String, dynamic>? details) {
  final raw = details?['missingIngredients'];
  if (raw is! List) return List<MissingIngredient>.unmodifiable(const []);
  final result = <MissingIngredient>[];
  for (final Object? item in raw) {
    if (item is! Map) continue;
    final name = item['ingredientName'];
    final required = item['requiredQuantity'];
    final available = item['availableQuantity'];
    final shortfall = item['shortfallQuantity'];
    final unit = item['unit'];
    if (name is! String ||
        required is! num ||
        available is! num ||
        shortfall is! num ||
        unit is! String) {
      continue;
    }
    result.add(MissingIngredient(
      ingredientName: name,
      requiredQuantity: required.toDouble(),
      availableQuantity: available.toDouble(),
      shortfallQuantity: shortfall.toDouble(),
      unit: unit,
    ));
  }
  return List<MissingIngredient>.unmodifiable(result);
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
