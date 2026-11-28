import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_batch_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/checkout_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/checkout_preview_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/scenes/shopping_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_checkout_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';
import '../inventory/fake_connectivity_service.dart';

ShoppingItem _item(String id, String name,
        {ShoppingItemStatus status = ShoppingItemStatus.completed,
        bool inInventory = false,
        String? assignedTo}) =>
    ShoppingItem(
      id: id,
      householdId: 'h1',
      name: name,
      quantity: 1,
      unit: 'kg',
      displayQuantity: 1,
      displayUnit: 'kg',
      status: status,
      source: ShoppingItemSource.manual,
      version: 1,
      createdAt: DateTime.utc(2026, 11, 28),
      updatedAt: DateTime.utc(2026, 11, 28),
      inInventory: inInventory,
      assignedTo: assignedTo,
    );

class _ShoppingApi implements ShoppingApi {
  @override
  Future<ShoppingItem> update(String id, int version, String householdId, {required String name, required double quantity, required String unit}) => throw UnimplementedError();
  @override
  Future<void> delete(String id, int version) => throw UnimplementedError();
  List<ShoppingItem> rows = [];
  bool offline = false;

  @override
  Future<List<ShoppingItem>> list(String householdId) async {
    if (offline) throw NetworkException();
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _CheckoutApi implements CheckoutApi {
  _CheckoutApi(this.shopping);
  final _ShoppingApi shopping;

  @override
  Future<List<CheckoutPreviewItem>> preview() async => [
        for (final item in shopping.rows.where((i) => i.awaitsInventory))
          CheckoutPreviewItem.fromJson({
            'shoppingItemId': item.id,
            'version': item.version,
            'name': item.name,
            'quantity': item.quantity,
            'unit': item.unit,
          }),
      ];
}

class _BatchApi implements InventoryBatchApi {
  _BatchApi(this.shopping);
  final _ShoppingApi shopping;
  bool fail = false;

  @override
  Future<List<InventoryItemModel>> batchCreate(
      List<Map<String, dynamic>> items,
      {required String idempotencyKey}) async {
    if (fail) throw NetworkException();
    final ids = items.map((i) => i['sourceShoppingItemId']).toSet();
    shopping.rows = [
      for (final item in shopping.rows)
        if (ids.contains(item.id))
          item.copyWith(inInventory: true, version: item.version + 1)
        else
          item,
    ];
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  late AppDatabase db;
  late ShoppingDao dao;
  late _ShoppingApi api;
  late FakeConnectivityService connectivity;
  late ShoppingStore store;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ShoppingDao(db);
    api = _ShoppingApi();
    connectivity = FakeConnectivityService();
    final session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()))
      ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
      ..applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    store = ShoppingStore(
        dao: dao, api: api, connectivity: connectivity, session: session);
    Get.put<SessionStore>(session);
    Get.put<ShoppingStore>(store);
    Get.put<ConnectivityService>(connectivity);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await store.dispose();
    Get.reset();
    await connectivity.dispose();
    await db.close();
  });

  Future<void> showList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await store.init();
      await store.sync();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAppWidget(const ShoppingListScene(),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
  }

  testWidgets('ẩn món đã vào kho ở mọi bộ lọc, progress chỉ đếm món còn lại',
      (tester) async {
    api.rows = [
      _item('pending', 'Cà rốt', status: ShoppingItemStatus.pending),
      _item('bought', 'Dầu ăn', assignedTo: 'me'),
      _item('stored', 'Gạo đã cất', inInventory: true, assignedTo: 'me'),
    ];
    await showList(tester);

    expect(find.text('Gạo đã cất'), findsNothing);
    expect(find.text('Dầu ăn'), findsOneWidget);
    expect(find.text('Tất cả (2)'), findsOneWidget);
    expect(find.text('1 / 2 món đã hoàn thành (50%)'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator)).value, 0.5);
    expect(find.text('Cất vào kho (1)'), findsOneWidget);

    await tester.tap(find.text('Đã mua (1)').first);
    await tester.pumpAndSettle();
    expect(find.text('Dầu ăn'), findsOneWidget);
    expect(find.text('Cà rốt'), findsNothing);
    expect(find.text('Gạo đã cất'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('shopping-filter-mine')));
    await tester.pumpAndSettle();
    expect(find.text('Dầu ăn'), findsOneWidget);
    expect(find.text('Gạo đã cất'), findsNothing);
    expect(find.text('1 / 2 món đã hoàn thành (50%)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Put away một phần cập nhật danh sách, progress và nút cất',
      (tester) async {
    api.rows = [
      _item('pending', 'Cà rốt', status: ShoppingItemStatus.pending),
      _item('a', 'Dầu ăn'),
      _item('b', 'Muối'),
    ];
    await showList(tester);
    final batch = _BatchApi(api);
    final checkout = ShoppingCheckoutStore(
      api: _CheckoutApi(api),
      batchApi: batch,
      connectivity: connectivity,
      onCommitted: store.sync,
    );
    await checkout.load();
    checkout.toggleSelected('b');

    batch.fail = true;
    await tester.runAsync(() async => expect(await checkout.submit(), isNull));
    await tester.pumpAndSettle();
    expect(find.text('Dầu ăn'), findsOneWidget);
    expect(find.text('Cất vào kho (2)'), findsOneWidget);

    batch.fail = false;
    await tester.runAsync(() async {
      expect(await checkout.submit(), isNotNull);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.text('Dầu ăn'), findsNothing);
    expect(find.text('Muối'), findsOneWidget);
    expect(find.text('Tất cả (2)'), findsOneWidget);
    expect(find.text('1 / 2 món đã hoàn thành (50%)'), findsOneWidget);
    expect(find.text('Cất vào kho (1)'), findsOneWidget);
    expect((await dao.getById('a'))!.inInventory, isTrue);

    await checkout.load();
    checkout.toggleSelected('b');
    await tester.runAsync(() async {
      expect(await checkout.submit(), isNotNull);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(find.text('Muối'), findsNothing);
    expect(find.text('Cà rốt'), findsOneWidget);
    expect(find.text('Tất cả (1)'), findsOneWidget);
    expect(find.text('0 / 1 món đã hoàn thành (0%)'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('shopping-checkout-cta')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('chỉ còn món đã vào kho → trạng thái trống, kể cả cache offline',
      (tester) async {
    await dao.upsert(_item('stored', 'Gạo đã cất', inInventory: true));
    api.offline = true;
    await showList(tester);

    expect(find.text('Danh sách mua sắm trống'), findsOneWidget);
    expect(find.text('Gạo đã cất'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey<String>('shopping-checkout-cta')), findsNothing);
    expect(await dao.getById('stored'), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
