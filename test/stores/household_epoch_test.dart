import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
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
import 'package:smart_kitchen_mobile/stores/household_scoped.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../helpers/secure_storage_channel.dart';
import '../scenes/inventory/fake_connectivity_service.dart';
import '../scenes/inventory/fake_inventory_api.dart';

/// OD-33: epoch dùng chung cho mọi tác vụ bất đồng bộ theo household.
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
  void switchTo(String? h) =>
      h == null ? session.householdId = null : session.applyHouseholdContext(householdId: h, role: 'OWNER');

  test('HouseholdScoped: epoch tăng mỗi lần đổi; A→B→A vẫn là epoch MỚI (stale)', () async {
    final scope = _Scope();
    var changes = 0;
    expect(scope.rebindHousehold(session, () => changes++), isTrue);
    final e1 = scope.householdEpoch;
    expect(scope.rebindHousehold(session, () => changes++), isFalse); // cùng household
    expect(scope.isStaleEpoch(e1), isFalse);
    switchTo('h2');
    switchTo('h1');
    expect(changes, 2);
    expect(scope.rebindHousehold(session, () {}), isFalse); // vẫn h1 so với lần bind trước
    // rebind sau mỗi lần đổi (như init() trong reaction) → epoch mới
    final s2 = _Scope()..rebindHousehold(session, () {});
    final before = s2.householdEpoch;
    switchTo('h2');
    s2.rebindHousehold(session, () {});
    switchTo('h1');
    s2.rebindHousehold(session, () {});
    expect(s2.isStaleEpoch(before), isTrue);
    scope.unbindHousehold();
    s2.unbindHousehold();
  });

  test('HouseholdScoped: dispose (unbind) → tác vụ đang bay coi như CŨ, không ghi state', () {
    final scope = _Scope()..rebindHousehold(session, () {});
    final running = scope.householdEpoch;
    scope.unbindHousehold();
    expect(scope.isStaleEpoch(running), isTrue);
  });

  group('InventoryStore', () {
    late InventoryDao dao;

    InventoryItemModel inv(String id, String household) => InventoryItemModel(
          id: id, householdId: household, name: id, category: null, quantity: 1, unit: 'GRAM',
          displayQuantity: 1, displayUnit: 'g', lowStockThreshold: null, expiryDate: null, note: null, version: 1,
          isLowStock: false, isExpiringSoon: false, createdBy: 'u', createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026), syncStatus: SyncStatus.synced,
        );
    setUp(() async {
      dao = InventoryDao(db);
      await dao.upsertItem(inv('h1-item', 'h1'));
    });

    test('A→B→A trong lúc sync bay → KHÔNG reconcile-xoá kho h1 theo dữ liệu lẫn token B', () async {
      final gate = Completer<void>();
      var calls = 0;
      final api = FakeInventoryApi()
        ..onList = ({int page = 0, int size = 100}) async {
          calls++;
          if (calls == 1) {
            await gate.future;
            return pageOf(<InventoryItemModel>[]); // trả về sau A→B→A, giả như trang của B
          }
          return pageOf(<InventoryItemModel>[if (session.householdId == 'h1') inv('h1-item', 'h1')]);
        };
      final store = InventoryStore(
          dao: dao, api: api, connectivity: FakeConnectivityService(online: true), sessionStore: session);
      await store.init();
      await settle();
      switchTo('h2');
      await settle();
      switchTo('h1');
      await settle();
      gate.complete();
      await settle();
      expect((await dao.watchAllItems('h1').first).map((i) => i.id), contains('h1-item'));
      await store.dispose();
    });

    test('sync household cũ xong muộn KHÔNG tắt cờ isSyncing của sync household mới', () async {
      final oldGate = Completer<void>();
      final newGate = Completer<void>();
      var calls = 0;
      final api = FakeInventoryApi()
        ..onList = ({int page = 0, int size = 100}) async {
          calls++;
          await (calls == 1 ? oldGate.future : newGate.future);
          return pageOf(<InventoryItemModel>[]);
        };
      final store = InventoryStore(
          dao: dao, api: api, connectivity: FakeConnectivityService(online: true), sessionStore: session);
      await store.init();
      await settle();
      switchTo('h2');
      await settle();
      expect(store.isSyncing, isTrue);
      oldGate.complete();
      await settle();
      expect(store.isSyncing, isTrue, reason: 'sync h2 vẫn đang chạy');
      newGate.complete();
      await settle();
      expect(store.isSyncing, isFalse);
      await store.dispose();
    });
  });

  group('ShoppingStore', () {
    late ShoppingDao dao;
    late _Api api;
    late FakeConnectivityService conn;
    late ShoppingStore store;

    ShoppingItem shop(String id, String household, {ShoppingSyncStatus sync = ShoppingSyncStatus.synced}) => ShoppingItem(
          id: id, householdId: household, name: id, quantity: 1, unit: 'kg', displayQuantity: 1, displayUnit: 'kg',
          status: ShoppingItemStatus.pending, source: ShoppingItemSource.manual, version: 1,
          createdAt: DateTime.utc(2026, 10, 20), updatedAt: DateTime.utc(2026, 10, 20), syncStatus: sync,
        );

    setUp(() {
      dao = ShoppingDao(db);
      api = _Api(dao);
      conn = FakeConnectivityService(online: true);
      store = ShoppingStore(dao: dao, api: api, connectivity: conn, session: session);
    });
    tearDown(() => store.dispose());

    test('drain h1 đang gửi → đổi sang h2: DỪNG gửi queue h1 bằng token h2, CHẠY BÙ queue h2', () async {
      for (final id in <String>['h1-a', 'h1-b']) {
        final i = shop(id, 'h1', sync: ShoppingSyncStatus.pendingCreate);
        await dao.upsert(i);
        await dao.enqueueCreate(i);
      }
      final h2 = shop('h2-a', 'h2', sync: ShoppingSyncStatus.pendingCreate);
      await dao.upsert(h2);
      await dao.enqueueCreate(h2);
      api.createGate = Completer<void>();

      unawaited(store.init()); // drain h1 → kẹt ở create 'h1-a'
      await settle();
      expect(api.created, <String>['h1-a']);
      switchTo('h2');
      await settle();
      api.createGate!.complete();
      await settle();
      await settle();
      expect(api.created, isNot(contains('h1-b')), reason: 'không gửi tiếp queue h1 bằng token h2');
      expect(api.created, contains('h2-a'), reason: 'queue h2 được chạy bù');
      expect((await dao.queue('h1')).map((e) => e.itemId), contains('h1-b'));
    });

    test('toggle đang bay → đổi household → lỗi của household cũ KHÔNG hiện ở household mới', () async {
      await dao.upsert(shop('h1-a', 'h1'));
      await store.init();
      await settle();
      api
        ..toggleGate = Completer<void>()
        ..toggleError = ServerException('ERR_INTERNAL', 'boom');
      final toggling = store.toggle(shop('h1-a', 'h1'), price: 1000);
      await settle();
      switchTo('h2');
      await settle();
      api.toggleGate!.complete();
      await toggling;
      expect(store.error, isNull);
    });
  });
}

InventoryListPage pageOf(List<InventoryItemModel> items) =>
    InventoryListPage(items: items, page: 0, size: 100, totalElements: items.length, totalPages: 1);

class _Scope with HouseholdScoped {}

class _Api implements ShoppingApi {
  _Api(this.dao);
  final ShoppingDao dao;
  final List<String> created = <String>[];
  Completer<void>? createGate;
  Completer<void>? toggleGate;
  Object? toggleError;

  @override
  Future<List<ShoppingItem>> list(String householdId) => dao.getAll(householdId);

  @override
  Future<ShoppingItem> create(Map<String, dynamic> payload, String householdId, {String? idempotencyKey}) async {
    created.add(idempotencyKey!);
    if (created.length == 1) await createGate?.future;
    final local = (await dao.getById(idempotencyKey))!;
    return local.copyWith(syncStatus: ShoppingSyncStatus.synced);
  }

  @override
  Future<ShoppingItem> toggle(String id, int version, String householdId, {double? price}) async {
    await toggleGate?.future;
    if (toggleError != null) throw toggleError!;
    return (await dao.getById(id))!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
