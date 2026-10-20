import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/sync_status.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../helpers/secure_storage_channel.dart';
import '../scenes/inventory/fake_connectivity_service.dart';
import '../scenes/inventory/fake_inventory_api.dart';

/// OD-32: store `permanent` (sống qua logout) phải bám đúng household hiện tại —
/// đổi household / logout → login tài khoản khác KHÔNG được còn dữ liệu cũ.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  late AppDatabase db;
  late SessionStore session;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))))
      ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
      ..applyHouseholdContext(householdId: 'h1', role: 'OWNER');
  });
  tearDown(() => db.close());

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  group('ShoppingStore', () {
    late ShoppingDao dao;
    late _MirrorShoppingApi api;
    late ShoppingStore store;

    ShoppingItem shop(String id, String household) => ShoppingItem(
          id: id, householdId: household, name: id, quantity: 1, unit: 'kg', displayQuantity: 1, displayUnit: 'kg',
          status: ShoppingItemStatus.pending, source: ShoppingItemSource.manual, version: 1,
          createdAt: DateTime.utc(2026, 10, 20), updatedAt: DateTime.utc(2026, 10, 20),
        );

    setUp(() async {
      dao = ShoppingDao(db);
      api = _MirrorShoppingApi(dao);
      store = ShoppingStore(dao: dao, api: api, connectivity: FakeConnectivityService(online: false), session: session);
      await dao.upsert(shop('h1-item', 'h1'));
      await dao.upsert(shop('h2-item', 'h2'));
    });
    tearDown(() => store.dispose());

    test('đổi household → chỉ còn món household mới; ghi vào household cũ KHÔNG lọt lại', () async {
      await store.init();
      await settle();
      expect(store.items.map((i) => i.id), <String>['h1-item']);

      session.applyHouseholdContext(householdId: 'h2', role: 'MEMBER');
      await settle();
      expect(store.items.map((i) => i.id), <String>['h2-item']);

      // Ghi lại MỌI lần danh sách đổi — luồng household cũ còn sống sẽ ghi đè
      // `_items` dù ngay sau đó luồng mới ghi lại.
      final seen = <String>[];
      final stop = autorun((_) => seen.addAll(store.items.map((i) => i.id)));
      await dao.upsert(shop('h1-new', 'h1'));
      await settle();
      stop();
      expect(seen, isNot(contains('h1-new')));
      expect(store.items.map((i) => i.id), <String>['h2-item']);
    });

    test('logout (householdId null) → xoá sạch, không loading mãi; login household khác → dữ liệu mới', () async {
      await store.init();
      await settle();
      session.householdId = null;
      await settle();
      expect(store.items, isEmpty);
      expect(store.isLoading, isFalse);

      session.applyHouseholdContext(householdId: 'h2', role: 'OWNER');
      await settle();
      expect(store.items.map((i) => i.id), <String>['h2-item']);
    });

    test('init() lặp lại cùng household (scene dựng lại) → no-op, không mở luồng/sync thêm', () async {
      await store.init();
      await store.init();
      await store.init();
      await settle();
      expect(api.listCalls, 1);
      expect(store.items.map((i) => i.id), <String>['h1-item']);
    });
  });

  group('InventoryStore', () {
    late InventoryDao dao;
    late InventoryStore store;

    InventoryItemModel inv(String id, String household) => InventoryItemModel(
          id: id, householdId: household, name: id, category: 'Gia vị', quantity: 1, unit: 'GRAM',
          displayQuantity: 1, displayUnit: 'g', lowStockThreshold: null, expiryDate: null, note: null, version: 1,
          isLowStock: false, isExpiringSoon: false, createdBy: 'u', createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026), syncStatus: SyncStatus.synced,
        );

    setUp(() async {
      dao = InventoryDao(db);
      store = InventoryStore(
        dao: dao,
        api: FakeInventoryApi(),
        connectivity: FakeConnectivityService(online: false),
        sessionStore: session,
      );
      await dao.upsertItem(inv('h1-item', 'h1'));
      await dao.upsertItem(inv('h2-item', 'h2'));
    });
    tearDown(() => store.dispose());

    test('đổi household → chỉ còn đồ kho household mới, bộ lọc cũ bị xoá; luồng cũ KHÔNG lọt lại', () async {
      await store.init();
      await settle();
      store
        ..setSearchQuery('h1')
        ..setCategory('Gia vị');
      expect(store.items.map((i) => i.id), <String>['h1-item']);

      session.applyHouseholdContext(householdId: 'h2', role: 'MEMBER');
      await settle();
      expect(store.items.map((i) => i.id), <String>['h2-item']);
      expect((store.searchQuery, store.selectedCategory), ('', null));

      final seen = <String>[];
      final stop = autorun((_) => seen.addAll(store.items.map((i) => i.id)));
      await dao.upsertItem(inv('h1-new', 'h1'));
      await settle();
      stop();
      expect(seen, isNot(contains('h1-new')));
      expect(store.items.map((i) => i.id), <String>['h2-item']);
    });

    test('sync household cũ về MUỘN sau khi đã đổi household → KHÔNG reconcile-xoá kho household mới', () async {
      final gate = Completer<void>();
      var calls = 0;
      final api = FakeInventoryApi()
        ..onList = ({int page = 0, int size = 100}) async {
          calls++;
          if (calls == 1) {
            await gate.future; // list của h1 (server rỗng) về muộn
            return const InventoryListPage(items: <InventoryItemModel>[], page: 0, size: 100, totalElements: 0, totalPages: 1);
          }
          return InventoryListPage(items: <InventoryItemModel>[inv('h2-item', 'h2')], page: 0, size: 100, totalElements: 1, totalPages: 1);
        };
      final online = InventoryStore(
        dao: dao,
        api: api,
        connectivity: FakeConnectivityService(online: true),
        sessionStore: session,
      );
      await online.init();
      await settle();
      session.applyHouseholdContext(householdId: 'h2', role: 'MEMBER');
      await settle();
      gate.complete();
      await settle();
      expect((await dao.watchAllItems('h2').first).map((i) => i.id), contains('h2-item'));
      await online.dispose();
    });

    test('logout → kho trống, trạng thái ready (không loading mãi)', () async {
      await store.init();
      await settle();
      session.householdId = null;
      await settle();
      expect(store.items, isEmpty);
      expect(store.status, InventoryLoadStatus.ready);
    });
  });
}

class _MirrorShoppingApi implements ShoppingApi {
  _MirrorShoppingApi(this.dao);
  final ShoppingDao dao;
  int listCalls = 0;

  @override
  Future<List<ShoppingItem>> list(String householdId) async {
    listCalls++;
    return dao.getAll(householdId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
