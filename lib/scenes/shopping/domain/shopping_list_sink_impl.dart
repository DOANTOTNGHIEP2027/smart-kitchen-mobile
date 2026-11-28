import '../stores/shopping_store.dart';
import '../../mealplan/domain/meal_shopping_sync.dart';
import '../../mealplan/domain/meal_suggestion.dart';
import '../../mealplan/domain/shopping_list_sink.dart';
import 'shopping_item.dart';

class ShoppingListSinkImpl implements ShoppingListSink {
  const ShoppingListSinkImpl(this._store);
  final ShoppingStore _store;
  @override
  Future<int> addItems(List<IngredientItem> items) => _addGrouped(_store, items);
}

/// "Hoàn thành thêm món" (thực đơn buổi) ↔ Đi chợ qua `sourceRefs` của BE.
class MealShoppingSyncImpl implements MealShoppingSync {
  const MealShoppingSyncImpl(this._store);
  final ShoppingStore _store;

  @override
  Future<List<SlotShoppingLine>?> linesOfSlot(DateTime slotDate, String mealTime) async {
    if (!await _store.refreshFromServer()) return null;
    final date = _isoDate(slotDate);
    final lines = <SlotShoppingLine>[];
    for (final item in await _store.snapshot()) {
      // Dòng AUTO do BE tự sinh không thuộc luồng này — không đụng.
      if (item.source != ShoppingItemSource.manual) continue;
      for (final ref in item.sourceRefs) {
        if (ref.slotDate != date || ref.mealTime != mealTime) continue;
        lines.add(SlotShoppingLine(
          id: item.id,
          dishId: ref.dishId,
          recipeName: ref.recipeName,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          bought: item.status == ShoppingItemStatus.completed || item.inInventory,
        ));
        break;
      }
    }
    return lines;
  }

  @override
  Future<int> addForDish(String dishId, List<IngredientItem> items) =>
      _addGrouped(_store, items, sourceDishId: dishId);

  @override
  Future<int> remove(List<String> ids) async {
    final byId = <String, ShoppingItem>{for (final e in await _store.snapshot()) e.id: e};
    var removed = 0;
    for (final id in ids) {
      final item = byId[id];
      if (item == null || await _store.remove(item) == null) removed++;
    }
    return removed;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Thiếu cùng một nguyên liệu nhiều lần cần thành một dòng mua sắm với tổng
/// lượng; không tạo các item MANUAL trùng nhau.
Future<int> _addGrouped(ShoppingStore store, List<IngredientItem> items, {String? sourceDishId}) async {
  final grouped = <String, IngredientItem>{};
  for (final item in items) {
    final name = item.name.trim();
    final unit = item.unit.trim();
    if (name.isEmpty || unit.isEmpty || item.quantity <= 0) continue;
    final key = '${name.toLowerCase()}|${unit.toLowerCase()}';
    final previous = grouped[key];
    grouped[key] = previous == null
        ? IngredientItem(name: name, quantity: item.quantity, unit: unit)
        : IngredientItem(
            name: previous.name,
            quantity: previous.quantity + item.quantity,
            unit: previous.unit,
          );
  }
  var added = 0;
  for (final item in grouped.values) {
    if (await store.add(item.name, item.quantity, item.unit, sourceDishId: sourceDishId)) {
      added++;
    }
  }
  return added;
}
