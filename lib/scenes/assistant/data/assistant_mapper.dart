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
    recipeCards: _list(json['recipeCards'], _recipeCard),
    mealPlan: _list(json['mealPlan'], _planSlot),
    actions: _list(json['actions'], _action),
  );
}

ActionStatus actionStatusOf(String? raw) => switch (raw) {
      'DONE' => ActionStatus.done,
      'FAILED' => ActionStatus.failed,
      'EXPIRED' => ActionStatus.expired,
      'REJECTED' => ActionStatus.rejected,
      'EXECUTING' => ActionStatus.executing,
      _ => ActionStatus.pending,
    };

AssistantAction _action(Map<String, dynamic> json) => AssistantAction(
      actionId: json['actionId'] as String,
      type: json['type'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      status: actionStatusOf(json['status'] as String?),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.tryParse(json['expiresAt'] as String),
    );

/// `data` của confirm/reject: `{actionId, type, status, result}`.
ActionResult mapActionResult(Map<String, dynamic> json) => ActionResult(
      status: actionStatusOf(json['status'] as String?),
      code: (json['result'] as Map<String, dynamic>?)?['code'] as String?,
    );

RecipeCard _recipeCard(Map<String, dynamic> json) => RecipeCard(
      kbRecipeId: json['kbRecipeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String?,
      missingIngredients: _strings(json['missingIngredients']),
      allergenTags: _strings(json['allergenTags']),
    );

PlanSlot _planSlot(Map<String, dynamic> json) => PlanSlot(
      day: json['day'] as int? ?? 1,
      mealType: json['mealType'] as String? ?? '',
      dishes: _list(json['dishes'], _recipeCard),
    );

List<String> _strings(Object? raw) =>
    (raw as List<dynamic>?)
        ?.map((Object? e) => e.toString())
        .toList(growable: false) ??
    const <String>[];

/// Một phiên của `GET /assistant/sessions`.
AssistantSessionSummary mapSessionSummary(Map<String, dynamic> json) =>
    AssistantSessionSummary(
      id: json['id'] as String,
      contextType: json['contextType'] as String? ?? 'GLOBAL',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

/// Một message của `GET /assistant/sessions/{id}/messages`. Message USER chưa
/// được trả lời vẫn hiện như câu đã gửi; message AI mang `turn` như lượt live.
AssistMessage mapHistoryMessage(Map<String, dynamic> json) {
  final turn = json['turn'] as Map<String, dynamic>?;
  final isAi = json['role'] == 'AI';
  return AssistMessage(
    role: isAi ? AssistRole.assistant : AssistRole.user,
    text: json['text'] as String? ?? '',
    reply: isAi && turn != null ? mapAssistantReply(turn) : null,
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
