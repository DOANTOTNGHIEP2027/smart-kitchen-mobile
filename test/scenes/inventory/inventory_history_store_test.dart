import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_transaction.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_history_store.dart';

import 'fake_inventory_api.dart';

void main() {
  InventoryTransactionModel transaction(String id) => InventoryTransactionModel(
        id: id,
        inventoryItemId: 'i1',
        actorId: 'u1',
        reason: 'BOUGHT',
        quantityDelta: 1,
        unit: 'PIECE',
        quantityAfter: 1,
        createdAt: DateTime.parse('2026-10-01T08:00:00Z'),
      );

  test('load và loadMore nối trang theo thứ tự backend', () async {
    final api = FakeInventoryApi()
      ..onTransactions = (id, page, size) async => InventoryTransactionPage(
            items: <InventoryTransactionModel>[transaction('tx-$page')],
            page: page,
            size: size,
            totalElements: 2,
            totalPages: 2,
          );
    final store = InventoryHistoryStore(itemId: 'i1', api: api);

    await store.load();
    expect(store.status, InventoryHistoryStatus.ready);
    expect(store.items.map((value) => value.id), <String>['tx-0']);
    expect(store.canLoadMore, isTrue);

    await store.loadMore();
    expect(store.items.map((value) => value.id), <String>['tx-0', 'tx-1']);
    expect(store.canLoadMore, isFalse);
  });

  test('ApiException chuyển sang error state', () async {
    final api = FakeInventoryApi()..onTransactionsError = NetworkException();
    final store = InventoryHistoryStore(itemId: 'i1', api: api);

    await store.load();

    expect(store.status, InventoryHistoryStatus.error);
    expect(store.error?.code, 'ERR_NETWORK');
  });
}
