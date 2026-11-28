import '../../cooking/domain/pending_ingredient_matcher.dart';
import '../../inventory/domain/inventory_item.dart';
import '../../recipe/domain/recipe.dart';
import 'meal_suggestion.dart';

/// Nguyên liệu của công thức chọn thủ công mà kho chưa đủ — luồng thủ công
/// không có `missingIngredients` từ BE nên FE tự so với kho.
///
/// Khớp tên như [pendingItemsForIngredients] (bỏ dấu, chứa nhau). Không có
/// trong kho ⇒ thiếu đủ lượng công thức. Có trong kho cùng đơn vị nhưng ít hơn
/// ⇒ thiếu phần chênh. Đơn vị cùng nhóm quy đổi theo bảng [_unitFactors]
/// (g/kg, ml/l…); khác nhóm hoặc công thức không ghi lượng ⇒ coi là đủ
/// (không quy đổi được thì không đoán). Đây là đường dự phòng khi BE không
/// trả `missingIngredients`.
List<IngredientItem> inventoryShortfall(
  Iterable<RecipeIngredient> ingredients,
  Iterable<InventoryItemModel> stock,
) {
  final result = <IngredientItem>[];
  for (final ingredient in ingredients) {
    final name = foldIngredientName(ingredient.name);
    if (name.isEmpty) continue;
    final matches = stock.where((item) {
      final stockName = foldIngredientName(item.name);
      return stockName.isNotEmpty &&
          (stockName.contains(name) || name.contains(stockName));
    }).toList(growable: false);
    final unit = ingredient.unit?.trim() ?? '';
    final needed = ingredient.quantity;
    if (matches.isEmpty) {
      result.add(IngredientItem(
        name: ingredient.name.trim(),
        quantity: needed != null && needed > 0 ? needed : 1,
        unit: unit.isEmpty ? 'cái' : unit,
      ));
      continue;
    }
    if (needed == null || needed <= 0 || unit.isEmpty) continue;
    final need = _toCanonical(needed, unit);
    double? available = 0;
    for (final item in matches) {
      final have = need == null
          ? (item.unit.trim().toLowerCase() == unit.toLowerCase()
              ? (unit: '', value: item.quantity)
              : null)
          : _toCanonical(item.quantity, item.unit);
      if (have == null || (need != null && have.unit != need.unit)) {
        available = null;
        break;
      }
      available = available! + have.value;
    }
    if (available == null) continue;
    final needValue = need?.value ?? needed;
    if (available < needValue) {
      final factor = need == null ? 1.0 : needValue / needed;
      result.add(IngredientItem(
        name: ingredient.name.trim(),
        quantity: (needValue - available) / factor,
        unit: unit,
      ));
    }
  }
  return result;
}

/// Bản sao rút gọn bảng `UnitNormalizer` của BE: đơn vị → (đơn vị chuẩn, hệ số).
const Map<String, (String, double)> _unitFactors = <String, (String, double)>{
  'g': ('GRAM', 1),
  'gr': ('GRAM', 1),
  'gram': ('GRAM', 1),
  'kg': ('GRAM', 1000),
  'kilogram': ('GRAM', 1000),
  'ký': ('GRAM', 1000),
  'cân': ('GRAM', 1000),
  'lạng': ('GRAM', 100),
  'ml': ('MILLILITER', 1),
  'milliliter': ('MILLILITER', 1),
  'mililit': ('MILLILITER', 1),
  'cc': ('MILLILITER', 1),
  'l': ('MILLILITER', 1000),
  'lit': ('MILLILITER', 1000),
  'liter': ('MILLILITER', 1000),
  'lít': ('MILLILITER', 1000),
  'muỗng canh': ('MILLILITER', 15),
  'thìa canh': ('MILLILITER', 15),
  'tbsp': ('MILLILITER', 15),
  'muỗng cà phê': ('MILLILITER', 5),
  'thìa cà phê': ('MILLILITER', 5),
  'tsp': ('MILLILITER', 5),
  'cup': ('MILLILITER', 240),
  'piece': ('PIECE', 1),
  'quả': ('PIECE', 1),
  'trái': ('PIECE', 1),
  'củ': ('PIECE', 1),
  'con': ('PIECE', 1),
  'unit': ('UNIT', 1),
  'cái': ('UNIT', 1),
  'gói': ('UNIT', 1),
  'hộp': ('UNIT', 1),
  'chai': ('UNIT', 1),
  'túi': ('UNIT', 1),
  'bó': ('UNIT', 1),
  'lon': ('UNIT', 1),
  'hũ': ('UNIT', 1),
  'bịch': ('UNIT', 1),
  'vỉ': ('UNIT', 1),
  'khay': ('UNIT', 1),
};

({String unit, double value})? _toCanonical(double quantity, String unit) {
  final entry = _unitFactors[unit.trim().toLowerCase()];
  return entry == null ? null : (unit: entry.$1, value: quantity * entry.$2);
}
