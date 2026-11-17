/// Model trợ lý nấu ăn (#157 — OAS `cooking-assistant.yaml`, FE design §14).
///
/// Key JSON camelCase; mapper nằm ở `data/cooking_assist_mapper.dart`.
enum AssistIntent { substitute, scale, stepQa }

/// `KB` = bảng thay thế đã kiểm dị ứng; `LLM` = gợi ý dự phòng, chưa kiểm.
enum AssistSource { kb, llm }

enum AssistContextSource { snapshot, liveRecipe }

enum AssistRole { user, assistant }

extension AssistRoleWire on AssistRole {
  String get wire => this == AssistRole.user ? 'USER' : 'ASSISTANT';
}

class SubstituteOption {
  const SubstituteOption({
    required this.original,
    required this.substitute,
    required this.ratio,
    required this.inStock,
    required this.source,
    required this.allergenChecked,
    this.contextNote,
  });

  final String original;
  final String substitute;
  final String ratio;

  /// Có trong kho theo TÊN — KHÔNG có nghĩa là đủ dùng (§14.4).
  final bool inStock;
  final String? contextNote;
  final AssistSource source;
  final bool allergenChecked;

  /// Guard §14.7.3 — nhãn "chưa kiểm chứng dị ứng" bắt buộc.
  bool get isAllergenUnverified =>
      source == AssistSource.llm || !allergenChecked;
}

class BlockedSubstitute {
  const BlockedSubstitute({required this.substitute, required this.reason});

  final String substitute;
  final String reason;
}

class ScaledIngredient {
  const ScaledIngredient({
    required this.name,
    this.originalQuantity,
    this.scaledQuantity,
    this.unit,
    this.note,
  });

  final String name;
  final double? originalQuantity;
  final double? scaledQuantity;
  final String? unit;
  final String? note;
}

class AllergenScope {
  const AllergenScope({
    required this.householdMembers,
    required this.dependents,
    required this.guestsUnknown,
  });

  final bool householdMembers;
  final bool dependents;
  final bool guestsUnknown;
}

class CookingAssistData {
  const CookingAssistData({
    required this.requestId,
    required this.intent,
    required this.answer,
    required this.substitutes,
    required this.blockedSubstitutes,
    required this.scaledIngredients,
    required this.fallback,
    required this.contextSource,
    required this.allergenScope,
    this.stepRef,
  });

  final String requestId;
  final AssistIntent intent;
  final String answer;

  /// `stepNumber` (KHÔNG phải vị trí) — đổi sang vị trí bằng `indexWhere`.
  final int? stepRef;
  final List<SubstituteOption> substitutes;
  final List<BlockedSubstitute> blockedSubstitutes;
  final List<ScaledIngredient> scaledIngredients;
  final bool fallback;
  final AssistContextSource contextSource;
  final AllergenScope allergenScope;

  /// §14.4: cảnh báo khách chỉ đi kèm khi có gợi ý thay thế.
  bool get showGuestsWarning =>
      allergenScope.guestsUnknown && substitutes.isNotEmpty;
}

/// Một tin trong `chatHistory` gửi lên BE.
class ChatTurn {
  const ChatTurn({required this.role, required this.text});

  final AssistRole role;
  final String text;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'role': role.wire, 'text': text};
}

/// Một tin hiển thị trong sheet. `data` chỉ có ở tin ASSISTANT.
class AssistMessage {
  AssistMessage({required this.role, required this.text, this.data});

  final AssistRole role;
  final String text;
  final CookingAssistData? data;
}
