import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/sync_status.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_form_store.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import 'fake_inventory_api.dart';
import 'fake_connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();

  setUp(storageChannel.install);
  tearDown(storageChannel.uninstall);

  late AppDatabase db;
  late InventoryDao dao;
  late FakeInventoryApi api;
  late FakeConnectivityService connectivity;
  late SessionStore session;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryDao(db);
    api = FakeInventoryApi();
    connectivity = FakeConnectivityService(online: true);
    // Dựng SessionStore thật bám pattern profile_store_test — userId/householdId
    // dùng qua cache key và identity actor trong form store.
    final tokenStorage = TokenStorage();
    session = SessionStore(
      tokenStorage,
      AuthRefreshUseCase(
        Dio(BaseOptions(baseUrl: 'https://test.local'))
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          ),
      ),
    );
    session.currentUser =
        const UserSummary(id: 'u1', fullName: 'Tester');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
  });

  tearDown(() => db.close());

  InventoryFormStore editStore(String itemId) {
    return InventoryFormStore(
      mode: InventoryFormMode.edit,
      itemId: itemId,
      dao: dao,
      api: api,
      connectivity: connectivity,
      sessionStore: session,
      localIdGen: () => 'local-test',
    );
  }

  InventoryFormStore createStore() {
    return InventoryFormStore(
      mode: InventoryFormMode.create,
      itemId: null,
      dao: dao,
      api: api,
      connectivity: connectivity,
      sessionStore: session,
      localIdGen: () => 'local-test',
    );
  }

  Future<InventoryItemModel> seedItem({
    String id = 'i1',
    int version = 1,
    double quantity = 500,
    SyncStatus status = SyncStatus.synced,
  }) async {
    final item = InventoryItemModel(
      id: id,
      householdId: 'h1',
      name: 'Cà chua',
      category: 'Rau',
      quantity: quantity,
      unit: 'g',
      displayQuantity: quantity,
      displayUnit: 'g',
      lowStockThreshold: 100,
      version: version,
      isLowStock: false,
      isExpiringSoon: false,
      createdBy: 'u1',
      createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
      updatedAt: DateTime.parse('2026-09-15T10:00:00Z'),
      syncStatus: status,
    );
    await dao.upsertItem(item);
    return item;
  }

  group('save CREATE — optimistic + remap', () {
    test('online success → remapAndMarkSynced với id server', () async {
      api.onCreate = (_) async => (await seedItem(id: 'server-uuid'))
          .copyWith(version: 1);

      final store = createStore();
      final ok = await store.save(name: 'Cà chua', quantity: 500, unit: 'g');

      expect(ok, isTrue);
      expect(await dao.getById('local-test'), isNull,
          reason: 'temp id phải bị thay bằng server id');
      expect(await dao.getById('server-uuid'), isNotNull);
      final got = await dao.getById('server-uuid');
      expect(got!.syncStatus, SyncStatus.synced);
    });

    test('online fail → rollback: xoá temp row, saveError set', () async {
      api.onCreateError = ValidationException(
        'ERR_VALIDATION_FAILED',
        'bad request',
        fieldErrors: const {'name': 'must not be blank'},
      );

      final store = createStore();
      final ok = await store.save(name: '', quantity: 500, unit: 'g');

      expect(ok, isFalse);
      expect(store.saveError, isNotNull);
      expect(store.saveError!.code, 'ERR_VALIDATION_FAILED');
      expect(await dao.getById('local-test'), isNull,
          reason: 'CREATE rollback = xoá temp row hoàn toàn');
    });

    test('offline → vẫn ghi optimistic, save returns true (offline echo)',
        () async {
      connectivity.set(false);

      final store = createStore();
      final ok = await store.save(name: 'Cà chua', quantity: 500, unit: 'g');

      expect(ok, isTrue, reason: 'offline echo = save interface thành công');
      final row = await dao.getById('local-test');
      expect(row, isNotNull);
      expect(row!.syncStatus, SyncStatus.pendingCreate);
      final queue = await dao.queuedOperations('h1');
      expect(queue, hasLength(1),
          reason: 'pending CREATE phải sống trong SQLite, không chỉ là nhãn UI');
      expect(queue.single.operation, 'CREATE');
    });
  });

  group('save EDIT — rollback đúng snapshot', () {
    test('offline edit → coalesce thành UPDATE trong durable queue', () async {
      await seedItem(id: 'i1', version: 4);
      connectivity.set(false);

      final store = editStore('i1');
      expect(await store.save(name: 'Lần một', quantity: 100, unit: 'g'), isTrue);
      expect(await store.save(name: 'Lần hai', quantity: 200, unit: 'g'), isTrue);

      final queue = await dao.queuedOperations('h1');
      expect(queue, hasLength(1));
      expect(queue.single.operation, 'UPDATE');
      expect(queue.single.baseVersion, 4);
      expect((await dao.getById('i1'))!.name, 'Lần hai');
    });
    test('online success → markSynced với server version mới', () async {
      final previous = await seedItem(id: 'i1', version: 1);
      api.onUpdate = (_, __, payload) async {
        return previous.copyWith(
          name: payload['name'] as String,
          quantity: (payload['quantity'] as num).toDouble(),
          version: previous.version + 1,
          updatedAt: DateTime.parse('2026-09-15T11:00:00Z'),
        );
      };

      final store = editStore('i1');
      final ok = await store.save(name: 'Cà chua cherry', quantity: 200, unit: 'g');

      expect(ok, isTrue);
      final got = await dao.getById('i1');
      expect(got!.name, 'Cà chua cherry');
      expect(got.quantity, 200);
      expect(got.version, 2);
      expect(got.syncStatus, SyncStatus.synced);
    });

    test(
        'rollback về đúng snapshot, không cleared field — Phase 0 US 2.1 AC',
        () async {
      // Seed item với nhiều field có giá trị để kiểm rollback không trả null
      await seedItem(id: 'i1', version: 5);
      // previous: name='Cà chua', category='Rau', qty=500, lowStock=100
      api.onUpdateError =
          BusinessException('ERR_INVENTORY_UNIT_INVALID', 'unit lỗi');

      final store = editStore('i1');
      final ok = await store.save(name: 'Đổi tên', quantity: 1, unit: 'BAD');

      expect(ok, isFalse);
      final got = await dao.getById('i1');
      expect(got!.name, 'Cà chua',
          reason: 'rollback phải khôi phục đúng snapshot trước đó');
      expect(got.category, 'Rau');
      expect(got.quantity, 500);
      expect(got.lowStockThreshold, 100);
      expect(got.version, 5);
      expect(got.syncStatus, SyncStatus.synced);
      expect(store.saveError!.code, 'ERR_INVENTORY_UNIT_INVALID');
    });

    test('409 ERR_INVENTORY_VERSION_CONFLICT → conflict set, không văng lỗi',
        () async {
      final previous = await seedItem(id: 'i1', version: 1);
      api.onUpdateError = BusinessException(
          'ERR_INVENTORY_VERSION_CONFLICT', 'concurrent write');
      api.onGetById = (id) async => previous.copyWith(
            name: 'Cà chua (server)',
            version: 2,
          );

      final store = editStore('i1');
      final ok = await store.save(name: 'Cà chua của tôi', quantity: 200, unit: 'g');

      expect(ok, isFalse, reason: 'conflict path — save trả false');
      expect(store.saveError, isNull,
          reason: 'conflict KHÔNG phải là saveError — nó là dialog riêng');
      expect(store.conflict, isNotNull);
      expect(store.conflict!.local.name, 'Cà chua của tôi');
      expect(store.conflict!.server.name, 'Cà chua (server)');
      expect(store.conflict!.server.version, 2);
    });

    test('404 ERR_INVENTORY_NOT_FOUND → xoá row local, không rollback',
        () async {
      await seedItem(id: 'i1');
      api.onUpdateError = BusinessException(
          'ERR_INVENTORY_NOT_FOUND', 'not found');

      final store = editStore('i1');
      final ok = await store.save(name: 'Đổi', quantity: 1, unit: 'g');

      expect(ok, isFalse);
      expect(await dao.getById('i1'), isNull,
          reason: 'Item không còn ở server — Fix HIGH-1, không rollback');
      expect(store.saveError!.code, 'ERR_INVENTORY_NOT_FOUND');
    });
  });

  group('delete — optimistic hide', () {
    test('online success → deleteItem cứng', () async {
      await seedItem(id: 'i1');
      api.onDelete = (_, __, ___) async {};

      final store = editStore('i1');
      final ok = await store.delete(reason: 'COOKED');

      expect(ok, isTrue);
      expect(await dao.getById('i1'), isNull);
    });

    test('404 trên delete → vẫn coi thành công (item đã không còn)', () async {
      await seedItem(id: 'i1');
      api.onDeleteError = BusinessException(
          'ERR_INVENTORY_NOT_FOUND', 'not found');

      final store = editStore('i1');
      final ok = await store.delete(reason: 'WASTE');

      expect(ok, isTrue, reason: 'item đã bị xoá từ nơi khác — cùng ý intent');
      expect(await dao.getById('i1'), isNull);
    });

    test('mọi lỗi khác → rollback — item hiện lại', () async {
      await seedItem(id: 'i1', version: 3);
      api.onDeleteError =
          BusinessException('ERR_INVENTORY_VERSION_CONFLICT', 'conflict');
      api.onGetById = (id) async =>
          (await dao.getById(id))!.copyWith(version: 4);

      final store = editStore('i1');
      final ok = await store.delete(reason: 'WASTE');

      expect(ok, isFalse);
      // markPendingDelete được rollback bằng upsertItem(previous)
      final row = await dao.getById('i1');
      expect(row, isNotNull, reason: 'rollback phải hiện lại item');
      expect(row!.syncStatus, isNot(SyncStatus.pendingDelete));
      expect(store.conflict, isNotNull);
    });
  });

  group('validate — Phase 0 AC 4 chặn input sai', () {
    test('quantity âm ở CREATE → lỗi', () {
      final e = InventoryFormStore.validateQuantity(
        '-5',
        mode: InventoryFormMode.create,
        mustBeWhole: false,
      );
      expect(e, isNotNull);
    });

    test('quantity rỗng → lỗi', () {
      final e = InventoryFormStore.validateQuantity(
        '',
        mode: InventoryFormMode.create,
        mustBeWhole: false,
      );
      expect(e, isNotNull);
    });

    test('quantity không phải số → lỗi', () {
      final e = InventoryFormStore.validateQuantity(
        'abc',
        mode: InventoryFormMode.create,
        mustBeWhole: false,
      );
      expect(e, isNotNull);
    });

    test('PIECE/UNIT phải là số nguyên', () {
      final e = InventoryFormStore.validateQuantity(
        '1.5',
        mode: InventoryFormMode.create,
        mustBeWhole: true,
      );
      expect(e, isNotNull);
    });

    test('EDIT cho phép quantity = 0 (đã dùng hết)', () {
      final e = InventoryFormStore.validateQuantity(
        '0',
        mode: InventoryFormMode.edit,
        mustBeWhole: false,
      );
      expect(e, isNull);
    });

    test('CREATE chặn quantity = 0', () {
      final e = InventoryFormStore.validateQuantity(
        '0',
        mode: InventoryFormMode.create,
        mustBeWhole: false,
      );
      expect(e, isNotNull);
    });

    test('name rỗng → lỗi', () {
      expect(InventoryFormStore.validateName(''), isNotNull);
      expect(InventoryFormStore.validateName('   '), isNotNull);
      expect(InventoryFormStore.validateName('Cà chua'), isNull);
    });
  });
}
