import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/pending_ingredient_matcher.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';

ShoppingItem _item(
  String name, {
  ShoppingItemStatus status = ShoppingItemStatus.pending,
  String? assignedTo,
}) {
  final now = DateTime(2026, 11, 28);
  return ShoppingItem(
    id: name,
    householdId: 'h1',
    name: name,
    quantity: 1,
    unit: 'PIECE',
    displayQuantity: 1,
    displayUnit: 'PIECE',
    status: status,
    source: ShoppingItemSource.auto,
    version: 0,
    createdAt: now,
    updatedAt: now,
    assignedTo: assignedTo,
  );
}

void main() {
  test('foldIngredientName bỏ dấu, chữ thường, gộp khoảng trắng', () {
    expect(foldIngredientName('  Thịt  Ba Chỉ '), 'thit ba chi');
    expect(foldIngredientName('Đậu phụ'), 'dau phu');
  });

  test('chỉ lấy món PENDING khớp tên nguyên liệu (bỏ dấu, chứa nhau)', () {
    final items = <ShoppingItem>[
      _item('Ba chỉ'),
      _item('Hành lá', status: ShoppingItemStatus.completed),
      _item('Sữa tươi'),
      _item('ca chua'),
    ];

    final pending = pendingItemsForIngredients(
      <String>['Thịt ba chỉ', 'Hành lá', 'Cà chua'],
      items,
    );

    expect(pending.map((i) => i.name), <String>['Ba chỉ', 'ca chua']);
  });

  test('không có nguyên liệu → rỗng', () {
    expect(pendingItemsForIngredients(<String>[], <ShoppingItem>[_item('Gạo')]),
        isEmpty);
  });
}
