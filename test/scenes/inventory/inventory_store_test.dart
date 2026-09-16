import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/realtime/ws_event_envelope.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/sync_status.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import 'fake_inventory_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();

  setUp(storageChannel.install);
  tearDown(storageChannel.uninstall);

  late AppDatabase db;
  late InventoryDao dao;
  late FakeInventoryApi api;
  late SessionStore session;
  late InventoryStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryDao(db);
    api = FakeInventoryApi();
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
        const UserSummary(id: 'self-actor', fullName: 'Me');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');

    store = InventoryStore(
      dao: dao,
      api: api,
      sessionStore: session,
    );
  });

  tearDown(() async {
    await store.dispose();
    await db.close();
  });

  InventoryItemModel serverItem({
    String id = 'srv-1',
    String name = 'Dầu ăn',
    int version = 2,
  }) {
    return InventoryItemModel(
      id: id,
      householdId: 'h1',
      name: name,
      category: 'Gia vị',
      quantity: 1000,
      unit: 'MILLILITER',
      displayQuantity: 1,
      displayUnit: 'l',
      lowStockThreshold: null,
      expiryDate: null,
      note: null,
      version: version,
      isLowStock: false,
      isExpiringSoon: false,
      createdBy: 'u2',
      createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
      updatedAt: DateTime.parse('2026-09-15T11:00:00Z'),
      syncStatus: SyncStatus.synced,
    );
  }

  WsEventEnvelope event({
    required String eventId,
    required String eventType,
    required Map<String, dynamic> data,
    String? actorId,
  }) {
    return WsEventEnvelope(
      eventId: eventId,
      eventType: eventType,
      householdId: 'h1',
      occurredAt: DateTime.parse('2026-09-15T11:30:00Z'),
      actorId: actorId,
      data: data,
    );
  }

  group('handleWsEvent', () {
    test('INVENTORY_ITEM_CREATED → upsert item từ server, synced', () async {
      final e = event(
        eventId: 'e1',
        eventType: 'INVENTORY_ITEM_CREATED',
        data: <String, dynamic>{
          'id': 'srv-1',
          'householdId': 'h1',
          'name': 'Dầu ăn',
          'category': 'Gia vị',
          'quantity': 1000,
          'unit': 'MILLILITER',
          'displayQuantity': 1,
          'displayUnit': 'l',
          'lowStockThreshold': null,
          'expiryDate': null,
          'note': null,
          'version': 2,
          'isLowStock': false,
          'isExpiringSoon': false,
          'createdBy': 'u2',
          'createdAt': '2026-09-15T10:00:00Z',
          'updatedAt': '2026-09-15T11:00:00Z',
        },
      );

      store.handleWsEvent(e);
      // cho async drain
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final got = await dao.getById('srv-1');
      expect(got, isNotNull);
      expect(got!.syncStatus, SyncStatus.synced);
      expect(got.name, 'Dầu ăn');
    });

    test('INVENTORY_ITEM_DELETED → xoá cứng row', () async {
      await dao.upsertItem(serverItem());
      final e = event(
        eventId: 'e2',
        eventType: 'INVENTORY_ITEM_DELETED',
        data: <String, dynamic>{'id': 'srv-1'},
      );

      store.handleWsEvent(e);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await dao.getById('srv-1'), isNull);
    });

    test('duplicate eventId → bỏ qua (dedupe §9.3)', () async {
      final e = event(
        eventId: 'e3',
        eventType: 'INVENTORY_ITEM_CREATED',
        data: <String, dynamic>{
          'id': 'srv-3',
          'householdId': 'h1',
          'name': 'Muối',
          'category': null,
          'quantity': 500,
          'unit': 'GRAM',
          'displayQuantity': 500,
          'displayUnit': 'g',
          'lowStockThreshold': null,
          'expiryDate': null,
          'note': null,
          'version': 1,
          'isLowStock': false,
          'isExpiringSoon': false,
          'createdBy': 'u2',
          'createdAt': '2026-09-15T10:00:00Z',
          'updatedAt': '2026-09-15T11:00:00Z',
        },
      );

      store.handleWsEvent(e);
      // Sửa content update để test — nếu không dedupe, đang PENDING_Update
      // sẽ không bị ghi đè.
      final e2 = event(
        eventId: 'e3', // trùng eventId
        eventType: 'INVENTORY_ITEM_DELETED',
        data: <String, dynamic>{'id': 'srv-3'},
      );
      store.handleWsEvent(e2);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // createdAt xảy ra trước delete nhưng cùng eventId → chỉ apply một lần
      final got = await dao.getById('srv-3');
      expect(got, isNotNull,
          reason: 'DELETE bị bỏ qua vì dedupe eventId');
    });

    test('actor guard D12 — không ghi đè row đang PENDING_* cục bộ', () async {
      // Seed item đang pending update (mình vừa sửa optimistic)
      await dao.upsertItem(serverItem(id: 'srv-x')
          .copyWith(syncStatus: SyncStatus.pendingUpdate, name: 'Của tôi'));

      // Event từ actor khác cập nhật item → phải bị bỏ qua
      final e = event(
        eventId: 'e4',
        eventType: 'INVENTORY_ITEM_UPDATED',
        data: <String, dynamic>{
          'id': 'srv-x',
          'householdId': 'h1',
          'name': 'Người khác sửa rồi',
          'category': 'Gia vị',
          'quantity': 2000,
          'unit': 'MILLILITER',
          'displayQuantity': 2,
          'displayUnit': 'l',
          'lowStockThreshold': null,
          'expiryDate': null,
          'note': null,
          'version': 5,
          'isLowStock': false,
          'isExpiringSoon': false,
          'createdBy': 'u2',
          'createdAt': '2026-09-15T10:00:00Z',
          'updatedAt': '2026-09-15T11:00:00Z',
        },
        actorId: 'user-khac',
      );

      store.handleWsEvent(e);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final got = await dao.getById('srv-x');
      expect(got!.name, 'Của tôi',
          reason: 'Pending row của mình phải được giữ, không bị server đè');
      expect(got.syncStatus, SyncStatus.pendingUpdate);
    });

    test('self-echo (actor là chính mình) → vẫn áp dụng', () async {
      // Item đang pending CREATE — tự BE xác nhận, actor=self → áp dụng
      await dao.upsertItem(serverItem(id: 'srv-self')
          .copyWith(syncStatus: SyncStatus.pendingUpdate, name: 'Cũ'));

      final e = event(
        eventId: 'e5',
        eventType: 'INVENTORY_ITEM_UPDATED',
        data: <String, dynamic>{
          'id': 'srv-self',
          'householdId': 'h1',
          'name': 'Đã xác nhận',
          'category': 'Gia vị',
          'quantity': 1000,
          'unit': 'MILLILITER',
          'displayQuantity': 1,
          'displayUnit': 'l',
          'lowStockThreshold': null,
          'expiryDate': null,
          'note': null,
          'version': 3,
          'isLowStock': false,
          'isExpiringSoon': false,
          'createdBy': 'self-actor',
          'createdAt': '2026-09-15T10:00:00Z',
          'updatedAt': '2026-09-15T11:00:00Z',
        },
        actorId: 'self-actor',
      );

      store.handleWsEvent(e);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final got = await dao.getById('srv-self');
      expect(got!.name, 'Đã xác nhận');
      expect(got.syncStatus, SyncStatus.synced);
    });

    test('household khác → bỏ qua toàn bộ event', () async {
      final e = WsEventEnvelope(
        eventId: 'e6',
        eventType: 'INVENTORY_ITEM_CREATED',
        householdId: 'h2', // khác household
        occurredAt: DateTime.parse('2026-09-15T11:30:00Z'),
        actorId: null,
        data: <String, dynamic>{
          'id': 'srv-other',
          'householdId': 'h2',
          'name': 'Của nhà khác',
          'category': null,
          'quantity': 1,
          'unit': 'PIECE',
          'displayQuantity': 1,
          'displayUnit': 'quả',
          'lowStockThreshold': null,
          'expiryDate': null,
          'note': null,
          'version': 1,
          'isLowStock': false,
          'isExpiringSoon': false,
          'createdBy': 'u3',
          'createdAt': '2026-09-15T10:00:00Z',
          'updatedAt': '2026-09-15T11:00:00Z',
        },
      );

      store.handleWsEvent(e);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await dao.getById('srv-other'), isNull,
          reason: 'Event household khác không được áp dụng');
    });
  });

  group('syncFromServer — không ghi đè optimistic row', () {
    test('item PENDING_UPDATE bị GET skip (Implementation Guard 4)', () async {
      await dao.upsertItem(serverItem(id: 'srv-1').copyWith(
        name: 'Của tôi (pending)',
        syncStatus: SyncStatus.pendingUpdate,
      ));

      api.onList = ({page = 0, size = 100}) async => InventoryListPage(
            items: <InventoryItemModel>[
              serverItem(id: 'srv-1', name: 'Bản server mới'),
            ],
            page: 0,
            size: 100,
            totalElements: 1,
            totalPages: 1,
          );

      await store.syncFromServer();

      final got = await dao.getById('srv-1');
      expect(got!.name, 'Của tôi (pending)',
          reason: 'syncFromServer phải skip row PENDING, không ghi đè');
      expect(got.syncStatus, SyncStatus.pendingUpdate);
    });

    test('item SYNCED được cập nhật từ server', () async {
      await dao.upsertItem(
          serverItem(id: 'srv-1', name: 'Bản cũ').copyWith());

      api.onList = ({page = 0, size = 100}) async => InventoryListPage(
            items: <InventoryItemModel>[
              serverItem(id: 'srv-1', name: 'Bản server mới', version: 3),
            ],
            page: 0,
            size: 100,
            totalElements: 1,
            totalPages: 1,
          );

      await store.syncFromServer();

      final got = await dao.getById('srv-1');
      expect(got!.name, 'Bản server mới');
      expect(got.syncStatus, SyncStatus.synced);
    });

    test('ApiException → syncError set, không chặn UI', () async {
      api.onListError = NetworkException();

      await store.syncFromServer();

      expect(store.syncError, isNotNull);
      expect(store.syncError!.code, 'ERR_NETWORK');
    });
  });
}
