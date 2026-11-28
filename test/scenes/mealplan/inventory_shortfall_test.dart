import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/inventory_shortfall.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';

InventoryItemModel _stock(String name, double qty, String unit) =>
    InventoryItemModel(
      id: name,
      householdId: 'h',
      name: name,
      quantity: qty,
      unit: unit,
      version: 1,
      isLowStock: false,
      isExpiringSoon: false,
      createdBy: 'u',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('thiếu hẳn hoặc thiếu lượng cùng đơn vị thì báo, đủ thì bỏ qua', () {
    final missing = inventoryShortfall(
      const <RecipeIngredient>[
        RecipeIngredient(name: 'Bánh phở', quantity: 500, unit: 'g'),
        RecipeIngredient(name: 'Thịt bò', quantity: 300, unit: 'g'),
        RecipeIngredient(name: 'Hành lá', quantity: 1, unit: 'bó'),
        RecipeIngredient(name: 'Gừng'),
      ],
      <InventoryItemModel>[
        _stock('thit bo', 100, 'G'),
        _stock('Hành lá', 2, 'bó'),
      ],
    );
    expect(missing.map((i) => (i.name, i.quantity, i.unit)), [
      ('Bánh phở', 500.0, 'g'),
      ('Thịt bò', 200.0, 'g'),
      ('Gừng', 1.0, 'cái'),
    ]);
  });

  test('khác đơn vị không quy đổi được thì không đoán là thiếu', () {
    final missing = inventoryShortfall(
      const <RecipeIngredient>[
        RecipeIngredient(name: 'Sữa', quantity: 500, unit: 'ml'),
      ],
      <InventoryItemModel>[_stock('Sữa tươi', 1, 'hộp')],
    );
    expect(missing, isEmpty);
  });

  test('quy đổi cùng nhóm đơn vị: kg ↔ g, l ↔ ml, đơn vị chuẩn của BE', () {
    final missing = inventoryShortfall(
      const <RecipeIngredient>[
        RecipeIngredient(name: 'Thịt bò', quantity: 1.5, unit: 'kg'),
        RecipeIngredient(name: 'Gạo', quantity: 500, unit: 'g'),
        RecipeIngredient(name: 'Nước dùng', quantity: 2, unit: 'l'),
      ],
      <InventoryItemModel>[
        _stock('Thịt bò', 500, 'g'),
        _stock('Gạo', 1, 'kg'),
        _stock('Nước dùng', 1500, 'MILLILITER'),
      ],
    );
    expect(missing.map((i) => (i.name, i.quantity, i.unit)), [
      ('Thịt bò', 1.0, 'kg'),
      ('Nước dùng', 0.5, 'l'),
    ]);
  });
}
