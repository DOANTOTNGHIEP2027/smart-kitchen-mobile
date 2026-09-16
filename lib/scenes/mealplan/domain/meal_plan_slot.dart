/// Tóm tắt 1 recipe đã được gán cho 1 dish (FE-7 §5.1).
class AssignedRecipeSummary {
  const AssignedRecipeSummary({
    required this.recipeId,
    required this.recipeName,
    required this.source,
  });

  final String recipeId;
  final String recipeName;
  final String source; // 'AI' | 'MANUAL'
}

/// Status của 1 `MealPlanDish` (FE-7 §5.1). Đọc TRỰC TIẾP từ field `status` JSON
/// BE trả (DishStatusResolver phía BE tính tại thời điểm đọc), KHÔNG suy dẫn
/// lại ở FE cho "giá trị tĩnh" này — khác [SlotUiStatus] bên dưới.
enum DishUiStatus { empty, suggested, voting, confirmed }

/// 1 món ăn trong 1 slot (FE-7 §5.1, [AMEND] 1 slot có N dish).
class MealPlanDish {
  const MealPlanDish({
    required this.id,
    required this.slotId,
    required this.sortOrder,
    required this.status,
    this.recipe,
  });

  final String id;
  final String slotId;
  final int sortOrder;

  /// Sentinel khi response không có `sort_order` (HIGH-1 fix review v2) — KHÔNG
  /// hiển thị, chỉ báo "không tin cậy" cho tầng reconcile.
  static const int unknownSortOrder = -1;

  final DishUiStatus status;
  final AssignedRecipeSummary? recipe;

  MealPlanDish copyWith({
    DishUiStatus? status,
    AssignedRecipeSummary? recipe,
    bool clearRecipe = false,
  }) =>
      MealPlanDish(
        id: id,
        slotId: slotId,
        sortOrder: sortOrder,
        status: status ?? this.status,
        recipe: clearRecipe ? null : (recipe ?? this.recipe),
      );
}

/// Status aggregate của 1 SLOT — suy dẫn tại client từ `dishes` (FE-7 §5.1,
/// mirror `SlotStatusResolver` BE). KHÔNG đọc thẳng field `status` mà BE trả
/// kèm slot (lệch ngay sau optimistic-update/WS nếu không có lượt GET mới).
enum SlotUiStatus { empty, voting, inProgress, confirmed }

/// 1 bữa trong tuần — giờ chứa danh sách dish (FE-7 §5.1, [AMEND]).
class MealPlanSlot {
  const MealPlanSlot({
    required this.id,
    required this.slotDate,
    required this.mealTime,
    required this.dishes,
  });

  final String id;
  final DateTime slotDate;
  final String mealTime; // BREAKFAST | LUNCH | DINNER
  final List<MealPlanDish> dishes;

  MealPlanSlot copyWith({List<MealPlanDish>? dishes}) => MealPlanSlot(
        id: id,
        slotDate: slotDate,
        mealTime: mealTime,
        dishes: dishes ?? this.dishes,
      );
}

/// 1 meal plan (DTO + aggregate, FE-7 §6).
class MealPlanDto {
  const MealPlanDto({
    required this.id,
    required this.householdId,
    required this.weekStart,
    required this.slots,
  });

  final String id;
  final String householdId;
  final DateTime weekStart;
  final List<MealPlanSlot> slots;
}
