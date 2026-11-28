import 'meal_suggestion.dart';

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
    this.missingIngredients,
    this.cookedAt,
    this.cookedSessionId,
  });

  final String id;
  final String slotId;
  final int sortOrder;

  /// Thời điểm món đã được nấu xong (phiên nấu gắn `mealPlanDishId` hoàn
  /// thành). `null` = chưa nấu HOẶC server cũ không trả field này.
  final DateTime? cookedAt;

  /// Id phiên nấu đã hoàn thành của món (nếu có).
  final String? cookedSessionId;

  /// Món đã nấu xong — không cho mở lại màn nấu.
  bool get isCooked => cookedAt != null;

  /// Chỉ có ở response gán món tay (#201): nguyên liệu kho đang thiếu, rỗng
  /// khi đủ. `null` = response không mang field này (không suy ra "đủ").
  final List<IngredientItem>? missingIngredients;

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
        cookedAt: cookedAt,
        cookedSessionId: cookedSessionId,
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
    this.slotKey,
    this.label,
    this.scheduledTime,
    this.sortOrder,
    this.locked,
    this.allCooked,
  });

  final String id;
  final DateTime slotDate;
  final String mealTime; // BREAKFAST | LUNCH | DINNER
  final List<MealPlanDish> dishes;

  /// Khoá khung bữa theo template (`BREAKFAST`, `SNACK`, `CUSTOM_2`…) —
  /// `null` khi server cũ chưa trả.
  final String? slotKey;

  /// Tên bữa người dùng đặt trong template (vd "Ăn khuya").
  final String? label;

  /// Giờ dự kiến `HH:mm[:ss]` từ server; `null` ⇒ dùng giờ mặc định theo
  /// `mealTime`.
  final String? scheduledTime;

  /// Thứ tự hiển thị trong ngày; `null` ⇒ sắp theo `mealTime`.
  final int? sortOrder;

  /// Server đã khoá bữa (quá giờ + 2h hoặc đã nấu món). `null` = server cũ —
  /// tầng gọi tự fallback theo ngày.
  final bool? locked;

  /// Mọi món của bữa đã nấu xong. `null` = server cũ.
  final bool? allCooked;

  /// Phút trong ngày của [scheduledTime]; `null` khi thiếu/sai định dạng.
  int? get scheduledMinutes {
    final raw = scheduledTime;
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  /// Bữa đã nấu xong hết: ưu tiên cờ server, thiếu thì suy từ `cookedAt`
  /// của các món đã gán công thức.
  bool get isAllCooked {
    final flag = allCooked;
    if (flag != null) return flag;
    final planned = dishes.where((d) => d.recipe != null);
    return planned.isNotEmpty && planned.every((d) => d.isCooked);
  }

  MealPlanSlot copyWith({List<MealPlanDish>? dishes, bool? locked}) =>
      MealPlanSlot(
        id: id,
        slotDate: slotDate,
        mealTime: mealTime,
        dishes: dishes ?? this.dishes,
        slotKey: slotKey,
        label: label,
        scheduledTime: scheduledTime,
        sortOrder: sortOrder,
        locked: locked ?? this.locked,
        allCooked: allCooked,
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
