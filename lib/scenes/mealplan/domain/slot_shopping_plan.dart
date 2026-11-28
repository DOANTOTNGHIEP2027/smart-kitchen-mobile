import 'meal_plan_slot.dart';
import 'meal_shopping_sync.dart';

/// Kết quả so dòng đi chợ của 1 buổi với các món đang có trong buổi đó.
class SlotShoppingDiff {
  const SlotShoppingDiff({required this.staleLines, required this.uncoveredDishes});

  /// Dòng CHƯA MUA của món đã bị xoá / đã đổi công thức → xoá.
  final List<SlotShoppingLine> staleLines;

  /// Món có công thức nhưng chưa có dòng đi chợ nào còn đúng → tính đồ thiếu.
  final List<MealPlanDish> uncoveredDishes;
}

/// Dòng đã mua không bao giờ bị xoá (tiền đã tiêu) và vẫn tính là "đã có"
/// cho món của nó — không đẩy lại lần nữa.
SlotShoppingDiff diffSlotShopping(
  List<MealPlanDish> dishes,
  List<SlotShoppingLine> lines,
) {
  final recipeByDish = <String, String>{
    for (final d in dishes)
      if (d.recipe != null) d.id: d.recipe!.recipeName,
  };
  bool matches(SlotShoppingLine line) {
    final recipe = recipeByDish[line.dishId];
    if (recipe == null) return false;
    return line.recipeName == null || line.recipeName == recipe;
  }

  final covered = <String>{
    for (final line in lines)
      if (matches(line)) line.dishId,
  };
  return SlotShoppingDiff(
    staleLines: <SlotShoppingLine>[
      for (final line in lines)
        if (!line.bought && !matches(line)) line,
    ],
    uncoveredDishes: <MealPlanDish>[
      for (final d in dishes)
        if (d.recipe != null && !covered.contains(d.id)) d,
    ],
  );
}
