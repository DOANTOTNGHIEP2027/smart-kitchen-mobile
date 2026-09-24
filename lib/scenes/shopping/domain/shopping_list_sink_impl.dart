import '../stores/shopping_store.dart';
import '../../mealplan/domain/meal_suggestion.dart';
import '../../mealplan/domain/shopping_list_sink.dart';

class ShoppingListSinkImpl implements ShoppingListSink {
  const ShoppingListSinkImpl(this._store);
  final ShoppingStore _store;
  @override Future<void> addItems(List<IngredientItem> items) async {
    for (final item in items) { await _store.add(item.name, item.quantity, item.unit); }
  }
}
