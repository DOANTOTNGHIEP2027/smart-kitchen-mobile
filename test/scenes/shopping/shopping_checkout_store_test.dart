import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_batch_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/expiry_source.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/checkout_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/checkout_preview_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_checkout_store.dart';
import 'package:smart_kitchen_mobile/utils/date_format.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../inventory/fake_connectivity_service.dart';

class _FakeCheckoutApi implements CheckoutApi {
  List<List<CheckoutPreviewItem>> responses = <List<CheckoutPreviewItem>>[];
  int calls = 0;

  @override
  Future<List<CheckoutPreviewItem>> preview() async {
    final r = responses[calls < responses.length ? calls : responses.length - 1];
    calls++;
    return r;
  }
}

class _FakeBatchApi implements InventoryBatchApi {
  final List<List<Map<String, dynamic>>> payloads = <List<Map<String, dynamic>>>[];
  final List<String> keys = <String>[];
  List<Object> outcomes = <Object>[];

  @override
  Future<List<InventoryItemModel>> batchCreate(
    List<Map<String, dynamic>> items, {
    required String idempotencyKey,
  }) async {
    payloads.add(items);
    keys.add(idempotencyKey);
    final outcome = outcomes.isEmpty ? const <InventoryItemModel>[] : outcomes.removeAt(0);
    if (outcome is ApiException) throw outcome;
    return outcome as List<InventoryItemModel>;
  }
}

CheckoutPreviewItem _item(String id, {int version = 1, String? expiry, String unit = 'kg'}) =>
    CheckoutPreviewItem.fromJson(<String, dynamic>{
      'shoppingItemId': id,
      'version': version,
      'name': 'Món $id',
      'category': 'Rau củ',
      'quantity': 2,
      'unit': unit,
      'suggestedExpiryDate': expiry,
      'expirySource': expiry == null ? 'NONE' : 'CATEGORY_DEFAULT',
      'duplicate': false,
      'existingItemId': null,
    });

void main() {
  late _FakeCheckoutApi api;
  late _FakeBatchApi batch;
  late FakeConnectivityService connectivity;
  late int committed;
  late int keySeq;
  late ShoppingCheckoutStore store;

  setUp(() {
    api = _FakeCheckoutApi();
    batch = _FakeBatchApi();
    connectivity = FakeConnectivityService();
    committed = 0;
    keySeq = 0;
    store = ShoppingCheckoutStore(
      api: api,
      batchApi: batch,
      connectivity: connectivity,
      onCommitted: () async => committed++,
      idempotencyKeyGenerator: () => 'key-${++keySeq}',
    );
  });

  test('load: rỗng → EmptyState; có món → SuccessState, chọn sẵn, hạn là gợi ý', () async {
    api.responses = <List<CheckoutPreviewItem>>[<CheckoutPreviewItem>[]];
    await store.load();
    expect(store.state, isA<EmptyState<List<CheckoutPreviewItem>>>());

    api.responses = <List<CheckoutPreviewItem>>[
      <CheckoutPreviewItem>[_item('a', expiry: '2026-12-02')],
    ];
    api.calls = 0;
    await store.load();
    expect(store.state, isA<SuccessState<List<CheckoutPreviewItem>>>());
    final a = store.items.single;
    expect(a.selected, isTrue);
    expect(a.expirySource, ExpirySource.categoryDefault);
    expect(a.isExpirySuggested, isTrue);
    expect(toApiDate(a.expiryDate!), '2026-12-02');
  });

  test('submit: chỉ gửi món đã chọn, hạn đã sửa, đúng nguồn đi chợ', () async {
    api.responses = <List<CheckoutPreviewItem>>[
      <CheckoutPreviewItem>[_item('a', expiry: '2026-12-02'), _item('b', version: 3)],
    ];
    await store.load();
    store.toggleSelected('a');
    store.setExpiry('b', DateTime(2026, 12, 31));

    final count = await store.submit();

    expect(count, 0);
    expect(committed, 1);
    final sent = batch.payloads.single;
    expect(sent, hasLength(1));
    expect(sent.single['sourceShoppingItemId'], 'b');
    expect(sent.single['sourceShoppingItemVersion'], 3);
    expect(sent.single['expiryDate'], '2026-12-31');
    expect(store.items.firstWhere((i) => i.shoppingItemId == 'b').isExpirySuggested, isFalse);
  });

  test('lỗi mạng: bấm lại giữ nguyên idempotency key; sửa body thì key mới', () async {
    api.responses = <List<CheckoutPreviewItem>>[
      <CheckoutPreviewItem>[_item('a')],
    ];
    await store.load();
    batch.outcomes = <Object>[NetworkException(), NetworkException()];

    await store.submit();
    await store.submit();
    store.setExpiry('a', DateTime(2027, 1, 1));
    await store.submit();

    expect(batch.keys, <String>['key-1', 'key-1', 'key-2']);
    expect(committed, 1);
  });

  test('409 ALREADY_IN_INVENTORY: tải lại preview, giữ chỉnh sửa, tô đỏ dòng lỗi', () async {
    api.responses = <List<CheckoutPreviewItem>>[
      <CheckoutPreviewItem>[_item('a'), _item('b')],
      <CheckoutPreviewItem>[_item('a', version: 2), _item('b')],
    ];
    await store.load();
    store.setExpiry('a', DateTime(2026, 12, 20));
    batch.outcomes = <Object>[
      BusinessException('ERR_SHOP_ITEM_ALREADY_IN_INVENTORY', 'x',
          details: <String, dynamic>{'index': 1}),
    ];

    final count = await store.submit();

    expect(count, isNull);
    expect(api.calls, 2);
    expect(store.submitError?.code, 'ERR_SHOP_ITEM_ALREADY_IN_INVENTORY');
    expect(store.errorRowIds, <String>{'b'});
    final a = store.items.firstWhere((i) => i.shoppingItemId == 'a');
    expect(a.version, 2);
    expect(toApiDate(a.expiryDate!), '2026-12-20');
  });

  test('400 fieldErrors items[i]: tô đỏ dòng tương ứng, không tải lại', () async {
    api.responses = <List<CheckoutPreviewItem>>[
      <CheckoutPreviewItem>[_item('a'), _item('b')],
    ];
    await store.load();
    batch.outcomes = <Object>[
      ValidationException('ERR_VALIDATION_FAILED', 'x',
          fieldErrors: <String, String>{'items[0].unit': 'bad'}),
    ];

    await store.submit();

    expect(store.errorRowIds, <String>{'a'});
    expect(api.calls, 1);
  });

  test('canSubmit: offline, không chọn món nào, hoặc quả/cái lẻ → khoá', () async {
    api.responses = <List<CheckoutPreviewItem>>[
      <CheckoutPreviewItem>[_item('a', unit: 'quả')],
    ];
    await store.load();
    expect(store.canSubmit, isTrue);

    store.setQuantity('a', 1.5);
    expect(store.canSubmit, isFalse);
    store.setQuantity('a', 2);

    connectivity.set(false);
    expect(store.canSubmit, isFalse);
    connectivity.set(true);

    store.toggleSelected('a');
    expect(store.canSubmit, isFalse);
    expect(await store.submit(), isNull);
    expect(batch.payloads, isEmpty);
  });

  test('toApiDate dùng ngày local, không lùi ngày như toUtc()', () {
    expect(toApiDate(DateTime(2026, 11, 30)), '2026-11-30');
    expect(toApiDate(DateTime.utc(2026, 11, 30)), '2026-11-30');
    expect(parseApiDate('2026-11-30'), DateTime(2026, 11, 30));
    expect(parseApiDate(null), isNull);
  });
}
