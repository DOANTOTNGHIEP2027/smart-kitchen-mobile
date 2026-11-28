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
enum DishUiStatus { empty, suggested, confirmed }

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
enum SlotUiStatus { empty, inProgress, confirmed }

/// 1 bữa trong tuần — giờ chứa danh sách dish (FE-7 §5.1, [AMEND]).
class MealPlanSlot {
  const MealPlanSlot({
    required this.id,
    required this.slotDate,
    required this.mealTime,
    required this.dishes,
    String? slotKey,
    this.label,
    this.scheduledTime,
    this.sortOrder,
  }) : slotKey = slotKey ?? mealTime;

  final String id;
  final DateTime slotDate;
  final String mealTime; // BREAKFAST | LUNCH | DINNER | SNACK (bữa tự đặt)
  final List<MealPlanDish> dishes;

  /// Khoá bữa trong ngày theo cấu hình household (vd `CUSTOM_1`); duy nhất
  /// trong 1 ngày nên nhiều bữa SNACK không đè nhau. Thiếu thì = [mealTime].
  final String slotKey;

  /// Tên / giờ (`HH:mm[:ss]`) / thứ tự bữa chụp từ cấu hình lúc tạo plan.
  final String? label;
  final String? scheduledTime;
  final int? sortOrder;

  MealPlanSlot copyWith({List<MealPlanDish>? dishes}) => MealPlanSlot(
        id: id,
        slotDate: slotDate,
        mealTime: mealTime,
        dishes: dishes ?? this.dishes,
        slotKey: slotKey,
        label: label,
        scheduledTime: scheduledTime,
        sortOrder: sortOrder,
      );
}

/// 1 meal plan (DTO + aggregate, FE-7 §6).
class MealPlanDto {
  const MealPlanDto({
    required this.id,
    required this.householdId,
    required this.weekStart,
    required this.slots,
    this.status = 'DRAFT',
  });

  final String id;
  final String householdId;
  final DateTime weekStart;
  final List<MealPlanSlot> slots;
  final String status;
}
