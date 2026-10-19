import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/demo/demo_backend_adapter.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';

import '../helpers/secure_storage_channel.dart';

/// Demo Mode phải chạy được 2 luồng mới (#133 giá, #134 gán) bằng chính
/// ShoppingApi production.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  late ShoppingApi api;

  setUp(() {
    storage.install();
    final client = DioClient.build(
      tokenStorage: TokenStorage(),
      dio: Dio(BaseOptions(baseUrl: 'https://demo.local')),
    )..dio.httpClientAdapter = DemoBackendAdapter();
    api = ShoppingApiImpl(client);
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
}
