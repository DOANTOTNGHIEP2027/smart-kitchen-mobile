import '../domain/cooking_assist.dart';

/// Parse `CookingAssistData` của OAS `cooking-assistant.yaml` (key camelCase).
CookingAssistData mapCookingAssistData(Map<String, dynamic> json) {
  return CookingAssistData(
    requestId: json['requestId'] as String,
    intent: _intent(json['intent'] as String),
    answer: json['answer'] as String,
    stepRef: json['stepRef'] as int?,
    substitutes: _list(json['substitutes'], _substitute),
    blockedSubstitutes: _list(json['blockedSubstitutes'], _blocked),
    scaledIngredients: _list(json['scaledIngredients'], _scaled),
    fallback: json['fallback'] as bool? ?? false,
    contextSource: json['contextSource'] == 'LIVE_RECIPE'
        ? AssistContextSource.liveRecipe
        : AssistContextSource.snapshot,
    allergenScope: _scope(json['allergenScope'] as Map<String, dynamic>?),
  );
}

AssistIntent _intent(String raw) => switch (raw) {
      'SUBSTITUTE' => AssistIntent.substitute,
      'SCALE' => AssistIntent.scale,
      _ => AssistIntent.stepQa,
    };

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) map) =>
    (raw as List<dynamic>?)
        ?.map((Object? e) => map(e as Map<String, dynamic>))
        .toList(growable: false) ??
    List<T>.empty();

SubstituteOption _substitute(Map<String, dynamic> json) => SubstituteOption(
      original: json['original'] as String,
      substitute: json['substitute'] as String,
      ratio: json['ratio'] as String,
      inStock: json['inStock'] as bool? ?? false,
      contextNote: json['contextNote'] as String?,
      // Giá trị lạ coi như LLM — an toàn hơn: luôn hiện nhãn chưa kiểm chứng.
      source: json['source'] == 'KB' ? AssistSource.kb : AssistSource.llm,
      allergenChecked: json['allergenChecked'] as bool? ?? false,
    );

BlockedSubstitute _blocked(Map<String, dynamic> json) => BlockedSubstitute(
      substitute: json['substitute'] as String,
      reason: json['reason'] as String,
    );

ScaledIngredient _scaled(Map<String, dynamic> json) => ScaledIngredient(
      name: json['name'] as String,
      originalQuantity: (json['originalQuantity'] as num?)?.toDouble(),
      scaledQuantity: (json['scaledQuantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      note: json['note'] as String?,
    );

// Thiếu field → giả định xấu nhất (khách chưa biết dị ứng).
AllergenScope _scope(Map<String, dynamic>? json) => AllergenScope(
      householdMembers: json?['householdMembers'] as bool? ?? true,
      dependents: json?['dependents'] as bool? ?? false,
      guestsUnknown: json?['guestsUnknown'] as bool? ?? true,
    );
