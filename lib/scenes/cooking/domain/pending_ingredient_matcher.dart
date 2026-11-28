import '../../shopping/domain/shopping_item.dart';

/// Món trong danh sách đi chợ còn chưa mua mà món sắp nấu cần dùng.
///
/// Khớp theo tên: bỏ dấu, chữ thường, gộp khoảng trắng; coi là khớp khi tên
/// này chứa tên kia ("Thịt ba chỉ" ↔ "ba chỉ"). Món đã mua hoặc đã cất kho bỏ
/// qua.
List<ShoppingItem> pendingItemsForIngredients(
  Iterable<String> ingredientNames,
  Iterable<ShoppingItem> shoppingItems,
) {
  final ingredients = ingredientNames
      .map(foldIngredientName)
      .where((n) => n.isNotEmpty)
      .toList(growable: false);
  if (ingredients.isEmpty) return const <ShoppingItem>[];
  return shoppingItems.where((item) {
    if (item.status != ShoppingItemStatus.pending) return false;
    final name = foldIngredientName(item.name);
    if (name.isEmpty) return false;
    return ingredients.any((i) => i.contains(name) || name.contains(i));
  }).toList(growable: false);
}

const String _withMarks =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const String _withoutMarks =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Chuẩn hoá tên để so: chữ thường, bỏ dấu tiếng Việt, gộp khoảng trắng.
String foldIngredientName(String raw) {
  final lower = raw.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final index = _withMarks.indexOf(ch);
    buffer.write(index >= 0 ? _withoutMarks[index] : ch);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
