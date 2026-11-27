import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/demo/demo_backend_adapter.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_batch_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/checkout_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';

import '../helpers/secure_storage_channel.dart';

/// Demo Mode phải chạy được 2 luồng mới (#133 giá, #134 gán) bằng chính
/// ShoppingApi production.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  late ShoppingApi api;
  late CheckoutApi checkout;
  late InventoryBatchApi batch;

  setUp(() {
    storage.install();
    final client = DioClient.build(
      tokenStorage: TokenStorage(),
      dio: Dio(BaseOptions(baseUrl: 'https://demo.local')),
    )..dio.httpClientAdapter = DemoBackendAdapter();
    api = ShoppingApiImpl(client);
    checkout = CheckoutApiImpl(client);
    batch = InventoryBatchApiImpl(client);
  });
  tearDown(storage.uninstall);

  test('tick kèm giá → giá lưu; bỏ tick → giá sticky; gán / bỏ giao', () async {
    final first = (await api.list('h1')).firstWhere((i) => i.status == ShoppingItemStatus.pending);

    final done = await api.toggle(first.id, first.version, 'h1', price: 55000);
    expect(done.status, ShoppingItemStatus.completed);
    expect(done.price, 55000);

    final undone = await api.toggle(done.id, done.version, 'h1');
    expect(undone.price, 55000);

    final assigned = await api.assign(undone.id, undone.version, 'h1', assigneeId: 'u-1');
    expect(assigned.assignedTo, 'u-1');
    final cleared = await api.assign(assigned.id, assigned.version, 'h1', assigneeId: null);
    expect(cleared.assignedTo, isNull);
  });

  test('#239 cất vào kho: preview món đã mua → batch → món inInventory, không toggle lại', () async {
    final first = (await api.list('h1')).firstWhere((i) => i.status == ShoppingItemStatus.pending);
    final done = await api.toggle(first.id, first.version, 'h1');

    final preview = await checkout.preview();
    final row = preview.firstWhere((p) => p.shoppingItemId == done.id);
    expect(row.version, done.version);

    final created = await batch.batchCreate(
      <Map<String, dynamic>>[row.toBatchPayload()],
      idempotencyKey: 'k-1',
    );
    expect(created.single.name, row.name);

    final after = (await api.list('h1')).firstWhere((i) => i.id == done.id);
    expect(after.inInventory, isTrue);
    expect((await checkout.preview()).any((p) => p.shoppingItemId == done.id), isFalse);
    await expectLater(
      api.toggle(after.id, after.version, 'h1'),
      throwsA(isA<BusinessException>()
          .having((e) => e.code, 'code', 'ERR_SHOP_ITEM_ALREADY_IN_INVENTORY')),
    );
  });
}
