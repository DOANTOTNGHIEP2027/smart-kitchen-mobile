import '../domain/assistant_models.dart';

/// Parse `AssistantTurnStatusResponse` của BE (`kitchen-assistant.md` v2 §2).
AssistantTurnStatus mapTurnStatus(Map<String, dynamic> json) {
  final reply = json['result'] as Map<String, dynamic>?;
  return AssistantTurnStatus(
    turnId: json['turnId'] as String,
    status: switch (json['status']) {
      'ANSWERED' => TurnStatus.answered,
      'FAILED' => TurnStatus.failed,
      _ => TurnStatus.pending,
    },
    errorCode: json['errorCode'] as String?,
    reply: reply == null ? null : mapAssistantReply(reply),
  );
}

/// `data` của sự kiện `turn.failed` chỉ có `{turnId, errorCode}`.
AssistantTurnStatus mapFailedEvent(Map<String, dynamic> json) =>
    AssistantTurnStatus(
      turnId: json['turnId'] as String,
      status: TurnStatus.failed,
      errorCode: json['errorCode'] as String?,
    );

AssistantReply mapAssistantReply(Map<String, dynamic> json) {
  final cooking = json['cooking'] as Map<String, dynamic>?;
  final question = json['question'] as Map<String, dynamic>?;
  return AssistantReply(
    turnId: json['turnId'] as String,
    answer: json['answer'] as String? ?? '',
    agent: json['agent'] as String? ?? 'meal',
    allergenNote: json['allergenNote'] as String?,
    cooking: cooking == null ? null : _cooking(cooking),
    suspectedDishes: _list(json['suspectedDishes'], _suspected),
    question: question == null
        ? null
        : AssistantQuestion(
            text: question['text'] as String? ?? '',
            options: (question['options'] as List<dynamic>?)
                    ?.map((Object? e) => e.toString())
                    .toList(growable: false) ??
                const <String>[],
          ),
    needsInput: json['needsInput'] as bool? ?? false,
    fallback: json['fallback'] as bool? ?? false,
  );
}

CookingAnswer _cooking(Map<String, dynamic> json) => CookingAnswer(
      substitutes: _list(json['substitutes'], _substitute),
      blockedSubstitutes: _list(json['blockedSubstitutes'], _blocked),
      scaledIngredients: _list(json['scaledIngredients'], _scaled),
      stepRef: json['stepRef'] as int?,
    );

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

SuspectedDish _suspected(Map<String, dynamic> json) => SuspectedDish(
      name: json['name'] as String? ?? '',
      allergen: json['allergen'] as String? ?? '',
      ingredient: json['ingredient'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
