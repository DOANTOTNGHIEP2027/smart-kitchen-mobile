import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_list_sink_impl.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/secure_storage_channel.dart';

ShoppingItem item(String id,
        {ShoppingItemStatus status = ShoppingItemStatus.pending,
        int version = 1,
        ShoppingSyncStatus sync = ShoppingSyncStatus.synced,
        ShoppingItemSource source = ShoppingItemSource.manual,
        List<ShoppingSourceRef> refs = const <ShoppingSourceRef>[]}) =>
    ShoppingItem(
      id: id, householdId: 'h1', name: 'Món $id', quantity: 1, unit: 'kg', displayQuantity: 1, displayUnit: 'kg',
      status: status, source: source, version: version,
      createdAt: DateTime.utc(2026, 11, 28), updatedAt: DateTime.utc(2026, 11, 28), syncStatus: sync, sourceRefs: refs,
    );

class _FakeApi implements ShoppingApi {
  List<ShoppingItem> serverItems = <ShoppingItem>[];
  final List<(String, int, String, double, String)> updates = <(String, int, String, double, String)>[];
  final List<(String, int)> deletes = <(String, int)>[];
  final List<Map<String, dynamic>> creates = <Map<String, dynamic>>[];
  ApiException? updateError;
  ApiException? deleteError;
  int listCalls = 0;

  @override
  Future<List<ShoppingItem>> list(String householdId) async {
    listCalls++;
    return serverItems;
  }

  @override
  Future<ShoppingItem> create(Map<String, dynamic> payload, String householdId, {String? idempotencyKey}) async {
    creates.add(payload);
    final dishId = payload['sourceDishId'] as String?;
    final created = item('srv-${creates.length}').copyWith(
      name: payload['name'] as String,
      sourceRefs: dishId == null
          ? null
          : <ShoppingSourceRef>[ShoppingSourceRef(dishId: dishId, slotDate: '2026-11-28', mealTime: 'LUNCH')],
    );
    serverItems = <ShoppingItem>[...serverItems, created];
    return created;
  }

  @override
  Future<ShoppingItem> update(String id, int version, String householdId, {required String name, required double quantity, required String unit}) async {
    updates.add((id, version, name, quantity, unit));
    if (updateError != null) throw updateError!;
    return item(id, version: version + 1).copyWith(name: name, quantity: quantity, unit: unit);
  }

  @override
  Future<void> delete(String id, int version) async {
    deletes.add((id, version));
    if (deleteError != null) throw deleteError!;
    serverItems = serverItems.where((e) => e.id != id).toList();
  }

  @override
  Future<ShoppingItem> toggle(String id, int version, String householdId, {double? price}) => throw UnimplementedError();
  @override
  Future<ShoppingItem> assign(String id, int version, String householdId, {required String? assigneeId}) => throw UnimplementedError();
}

class _Conn extends ConnectivityService {
  bool online = true;
  @override
  Future<bool> isOnline() async => online;
  @override
  Stream<void> get onConnectivityRestored => const Stream<void>.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  late AppDatabase db;
  late ShoppingDao dao;
  late _FakeApi api;
  late _Conn conn;
  late ShoppingStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ShoppingDao(db);
    api = _FakeApi();
    conn = _Conn();
    final session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))))
      ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
      ..applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    store = ShoppingStore(dao: dao, api: api, connectivity: conn, session: session);
  });
  tearDown(() => db.close());

  group('edit', () {
    test('gửi PATCH đúng version, ghi bản server vào Drift', () async {
      await dao.upsert(item('a', version: 3));
      expect(await store.edit(item('a'), name: ' Cà chua ', quantity: 2, unit: 'kg'), isNull);
      expect(api.updates.single, ('a', 3, 'Cà chua', 2.0, 'kg'));
      final row = await dao.getById('a');
      expect(row!.name, 'Cà chua');
      expect(row.version, 4);
    });

    test('offline / row chưa đồng bộ → NetworkException, không gọi API', () async {
      await dao.upsert(item('a'));
      conn.online = false;
      expect(await store.edit(item('a'), name: 'x', quantity: 1, unit: 'kg'), isA<NetworkException>());
      conn.online = true;
      await dao.upsert(item('b', sync: ShoppingSyncStatus.pendingToggle));
      expect(await store.edit(item('b'), name: 'x', quantity: 1, unit: 'kg'), isA<NetworkException>());
      expect(api.updates, isEmpty);
    });

    test('409 → trả lỗi + sync lại', () async {
      await dao.upsert(item('a'));
      api.serverItems = <ShoppingItem>[item('a', version: 5)];
      api.updateError = BusinessException('ERR_SHOP_ITEM_VERSION_CONFLICT', 'stale');
      final e = await store.edit(item('a'), name: 'x', quantity: 1, unit: 'kg');
      expect(e?.code, 'ERR_SHOP_ITEM_VERSION_CONFLICT');
      expect(api.listCalls, 1);
      expect((await dao.getById('a'))!.version, 5);
    });
  });

  group('remove', () {
    test('gửi DELETE kèm version, xoá row cục bộ', () async {
      await dao.upsert(item('a', version: 2));
      expect(await store.remove(item('a')), isNull);
      expect(api.deletes.single, ('a', 2));
      expect(await dao.getById('a'), isNull);
    });

    test('404 → coi như đã xoá', () async {
      await dao.upsert(item('a'));
      api.deleteError = BusinessException('ERR_SHOP_ITEM_NOT_FOUND', 'gone');
      expect(await store.remove(item('a')), isNull);
      expect(await dao.getById('a'), isNull);
    });

    test('403 món tự sinh → trả lỗi, GIỮ row', () async {
      await dao.upsert(item('a', source: ShoppingItemSource.auto));
      api.deleteError = BusinessException('ERR_SHOP_ITEM_DELETE_FORBIDDEN', 'no');
      expect((await store.remove(item('a')))?.code, 'ERR_SHOP_ITEM_DELETE_FORBIDDEN');
      expect(await dao.getById('a'), isNotNull);
    });

    test('offline → NetworkException, không xoá', () async {
      await dao.upsert(item('a'));
      conn.online = false;
      expect(await store.remove(item('a')), isA<NetworkException>());
      expect(api.deletes, isEmpty);
      expect(await dao.getById('a'), isNotNull);
    });
  });

  group('mapper sources (camelCase)', () {
    Map<String, dynamic> json(Object? refs) => <String, dynamic>{
          'id': 'x', 'name': 'Hành', 'quantity': 1, 'unit': 'cu', 'displayQuantity': 1, 'displayUnit': 'cu',
          'status': 'PENDING', 'source': 'MANUAL', 'version': 1,
          'createdAt': '2026-11-28T00:00:00Z', 'updatedAt': '2026-11-28T00:00:00Z',
          if (refs != null) 'sources': refs,
        };

    test('parse sourceRefs; thiếu key / phần tử hỏng → bỏ qua, không ném', () {
      final parsed = shoppingItemFromJson(json(<Object?>[
        <String, dynamic>{'dishId': 'd1', 'slotDate': '2026-11-28', 'mealTime': 'LUNCH', 'recipeName': 'Phở'},
        <String, dynamic>{'slotDate': '2026-11-28'},
        'hong',
      ]), 'h1');
      final ref = parsed.sourceRefs.single;
      expect((ref.dishId, ref.slotDate, ref.mealTime, ref.recipeName), ('d1', '2026-11-28', 'LUNCH', 'Phở'));
      expect(shoppingItemFromJson(json(null), 'h1').sourceRefs, isEmpty);
    });

    test('payload tạo gửi sourceDishId chỉ khi gắn món', () {
      expect(shoppingCreatePayload(item('a')).containsKey('sourceDishId'), isFalse);
      expect(
        shoppingCreatePayload(item('a', refs: const <ShoppingSourceRef>[ShoppingSourceRef(dishId: 'd1')]))['sourceDishId'],
        'd1',
      );
    });
  });

  group('MealShoppingSyncImpl', () {
    test('addForDish gắn dishId; linesOfSlot lọc đúng buổi, bỏ dòng AUTO', () async {
      final sync = MealShoppingSyncImpl(store);
      expect(
        await sync.addForDish('d1', const <IngredientItem>[
          IngredientItem(name: 'Hành', quantity: 1, unit: 'cu'),
          IngredientItem(name: 'hành', quantity: 2, unit: 'cu'),
        ]),
        1,
      );
      expect(api.creates.single['sourceDishId'], 'd1');
      expect(api.creates.single['quantity'], 3);
      api.serverItems = <ShoppingItem>[
        ...api.serverItems,
        item('other-meal', refs: const <ShoppingSourceRef>[
          ShoppingSourceRef(dishId: 'd9', slotDate: '2026-11-28', mealTime: 'DINNER'),
        ]),
        item('auto', source: ShoppingItemSource.auto, refs: const <ShoppingSourceRef>[
          ShoppingSourceRef(dishId: 'd1', slotDate: '2026-11-28', mealTime: 'LUNCH'),
        ]),
        item('bought', status: ShoppingItemStatus.completed, refs: const <ShoppingSourceRef>[
          ShoppingSourceRef(dishId: 'd2', slotDate: '2026-11-28', mealTime: 'LUNCH'),
        ]),
      ];
      final lines = (await sync.linesOfSlot(DateTime.utc(2026, 11, 28), 'LUNCH'))!;
      expect(
        lines.map((l) => (l.id, l.dishId, l.bought)).toList(),
        <(String, String, bool)>[('srv-1', 'd1', false), ('bought', 'd2', true)],
      );
    });

    test('linesOfSlot offline → null (không đọc cache cũ)', () async {
      conn.online = false;
      expect(await MealShoppingSyncImpl(store).linesOfSlot(DateTime.utc(2026, 11, 28), 'LUNCH'), isNull);
    });

    test('remove xoá qua API, đếm dòng đã xoá', () async {
      await dao.upsert(item('a'));
      await dao.upsert(item('b'));
      expect(await MealShoppingSyncImpl(store).remove(<String>['a', 'b']), 2);
      expect(api.deletes.map((d) => d.$1).toList(), <String>['a', 'b']);
    });
  });
}
