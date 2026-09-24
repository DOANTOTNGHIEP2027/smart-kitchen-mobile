import '../stores/shopping_store.dart';
import '../../mealplan/domain/meal_suggestion.dart';
import '../../mealplan/domain/shopping_list_sink.dart';

class ShoppingListSinkImpl implements ShoppingListSink {
  const ShoppingListSinkImpl(this._store);
  final ShoppingStore _store;
  @override
  Future<int> addItems(List<IngredientItem> items) async {
    // Thiếu cùng một nguyên liệu từ nhiều suggestion cần thành một dòng mua
    // sắm với tổng lượng; không tạo các item MANUAL trùng nhau.
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
      if (await _store.add(item.name, item.quantity, item.unit)) {
        added++;
      }
    }
    return added;
  }
}
