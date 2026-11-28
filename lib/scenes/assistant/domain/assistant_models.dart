/// Model trợ lý bếp (#204 — `kitchen-assistant.md` v2 §2, BE gọi job agent).
///
/// Key JSON camelCase; mapper nằm ở `data/assistant_mapper.dart`. Thay model
/// của trợ lý nấu ăn cũ #157 (`cooking_assist.dart`).
enum AssistantContextType { global, cooking, planning }

extension AssistantContextTypeWire on AssistantContextType {
  String get wire => switch (this) {
        AssistantContextType.global => 'GLOBAL',
        AssistantContextType.cooking => 'COOKING',
        AssistantContextType.planning => 'PLANNING',
      };
}

/// `KB` = bảng thay thế đã kiểm dị ứng; `LLM` = gợi ý dự phòng, chưa kiểm.
enum AssistSource { kb, llm }

enum AssistRole { user, assistant }

enum TurnStatus { pending, answered, failed }

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

  /// Có trong kho theo TÊN — KHÔNG có nghĩa là đủ dùng.
  final bool inStock;
  final String? contextNote;
  final AssistSource source;
  final bool allergenChecked;

  /// Nhãn "chưa kiểm chứng dị ứng" bắt buộc khi LLM hoặc chưa kiểm.
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

/// `result.cooking` — chỉ có khi agent nấu ăn trả lời.
class CookingAnswer {
  const CookingAnswer({
    required this.substitutes,
    required this.blockedSubstitutes,
    required this.scaledIngredients,
    this.stepRef,
  });

  final List<SubstituteOption> substitutes;
  final List<BlockedSubstitute> blockedSubstitutes;
  final List<ScaledIngredient> scaledIngredients;

  /// `stepNumber` (KHÔNG phải vị trí) — đổi sang vị trí bằng `indexWhere`.
  final int? stepRef;

  /// Câu hỏi về bước (không thay, không tính khẩu phần) ⇒ hiện lưu ý an toàn.
  bool get isStepAnswer => substitutes.isEmpty && scaledIngredients.isEmpty;
}

/// Món agent đã tạm loại vì nghi có chất gây dị ứng (chưa có bằng chứng).
class SuspectedDish {
  const SuspectedDish({
    required this.name,
    required this.allergen,
    required this.ingredient,
    required this.reason,
  });

  final String name;
  final String allergen;
  final String ingredient;
  final String reason;
}

/// Thẻ món AI gợi ý (S4). `kbRecipeId` là id món trong kho tri thức AI, chưa
/// phải `recipes.id` của BE.
class RecipeCard {
  const RecipeCard({
    required this.kbRecipeId,
    required this.name,
    this.reason,
    this.missingIngredients = const <String>[],
    this.allergenTags = const <String>[],
  });

  final String kbRecipeId;
  final String name;
  final String? reason;
  final List<String> missingIngredients;
  final List<String> allergenTags;
}

/// Một bữa trong thực đơn nhiều ngày (`mealPlan`), `day` tính từ 1.
class PlanSlot {
  const PlanSlot(
      {required this.day, required this.mealType, required this.dishes});

  final int day;
  final String mealType;
  final List<RecipeCard> dishes;
}

enum ActionStatus { pending, executing, done, failed, expired, rejected }

/// Đề xuất ghi của AI chờ người dùng xác nhận (S6/S7) — `MEALPLAN_ADD_DISH`
/// hoặc `SHOPPING_ADD_ITEMS`. Không gì được ghi trước khi người dùng bấm xác
/// nhận.
class AssistantAction {
  static const String shoppingAddItems = 'SHOPPING_ADD_ITEMS';

  const AssistantAction({
    required this.actionId,
    required this.type,
    required this.summary,
    required this.status,
    this.expiresAt,
  });

  final String actionId;
  final String type;
  final String summary;
  final ActionStatus status;
  final DateTime? expiresAt;
}

/// Kết quả `POST /assistant/actions/{id}/confirm|reject`.
class ActionResult {
  const ActionResult({required this.status, this.code});

  final ActionStatus status;

  /// Mã lỗi khi `failed` (vd. `ERR_PLAN_003` — thực đơn đã chốt).
  final String? code;
}

/// Một dòng của `GET /assistant/sessions` — đủ để mở lại phiên gần nhất.
class AssistantSessionSummary {
  const AssistantSessionSummary({
    required this.id,
    required this.contextType,
    required this.updatedAt,
  });

  final String id;
  final String contextType;
  final DateTime updatedAt;
}

/// AI cần hỏi lại (`NEEDS_INPUT`); mỗi option là một câu trả lời nhanh.
class AssistantQuestion {
  const AssistantQuestion({required this.text, required this.options});

  final String text;
  final List<String> options;
}

/// `result` của một lượt đã ANSWERED.
class AssistantReply {
  const AssistantReply({
    required this.turnId,
    required this.answer,
    required this.agent,
    required this.suspectedDishes,
    required this.needsInput,
    required this.fallback,
    this.allergenNote,
    this.cooking,
    this.question,
    this.recipeCards = const <RecipeCard>[],
    this.mealPlan = const <PlanSlot>[],
    this.actions = const <AssistantAction>[],
  });

  final String turnId;
  final String answer;

  /// `meal` | `cooking`.
  final String agent;

  /// Câu template về lọc dị ứng — hiện đúng nguyên văn, dòng riêng.
  final String? allergenNote;
  final CookingAnswer? cooking;
  final List<SuspectedDish> suspectedDishes;
  final AssistantQuestion? question;
  final bool needsInput;

  /// Job kết thúc `DEGRADED` (BE gửi kèm header `X-AI-Fallback`).
  final bool fallback;

  /// Thẻ món (S4) — FE hiện tối đa 5.
  final List<RecipeCard> recipeCards;

  /// Thực đơn nhiều ngày của phiên PLANNING.
  final List<PlanSlot> mealPlan;

  /// Đề xuất chờ xác nhận, trạng thái theo BE lúc tải.
  final List<AssistantAction> actions;
}

/// Trạng thái một lượt — từ POST messages, GET turns, hoặc sự kiện SSE.
class AssistantTurnStatus {
  const AssistantTurnStatus({
    required this.turnId,
    required this.status,
    this.errorCode,
    this.reply,
  });

  final String turnId;
  final TurnStatus status;
  final String? errorCode;
  final AssistantReply? reply;
}

/// Sự kiện SSE `…/turns/{turnId}/events` (BE §2.1).
sealed class AssistantTurnEvent {
  const AssistantTurnEvent();
}

/// AI đang chạy một tool — chỉ tên tool, không có nội dung.
class TurnProgress extends AssistantTurnEvent {
  const TurnProgress(this.tool);

  final String tool;
}

/// `turn.completed` / `turn.failed` — sự kiện cuối, stream đóng sau đó.
class TurnFinished extends AssistantTurnEvent {
  const TurnFinished(this.status);

  final AssistantTurnStatus status;
}

/// Một tin hiển thị trong sheet. `reply` chỉ có ở tin ASSISTANT.
class AssistMessage {
  AssistMessage({required this.role, required this.text, this.reply});

  final AssistRole role;
  final String text;
  final AssistantReply? reply;
}
