import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_transaction.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/widgets/waste_cause_sheet.dart';

void main() {
  test('transaction mapper dùng camelCase và giữ wasteCause', () {
    final value = inventoryTransactionFromJson(<String, dynamic>{
      'id': 'tx1',
      'inventoryItemId': 'i1',
      'actorId': 'u1',
      'reason': 'WASTE',
      'quantityDelta': -2.5,
      'unit': 'GRAM',
      'quantityAfter': 7.5,
      'note': null,
      'wasteCause': 'OVERBOUGHT',
      'createdAt': '2026-10-01T08:00:00Z',
    });

    expect(value.inventoryItemId, 'i1');
    expect(value.quantityDelta, -2.5);
    expect(value.quantityAfter, 7.5);
    expect(value.wasteCause, 'OVERBOUGHT');
  });

  test('waste picker clamp reason đúng cho PUT và DELETE', () {
    final put = wasteChoiceFor(WasteCause.forgotten, WasteEndpoint.put);
    final delete = wasteChoiceFor(WasteCause.forgotten, WasteEndpoint.delete);

    expect(put.reason, 'EXPIRED');
    expect(put.wasteCause, 'FORGOTTEN');
    expect(delete.reason, 'WASTE');
    expect(delete.wasteCause, 'FORGOTTEN');
  });
}
