import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/secure_storage_channel.dart';

ShoppingItem _item(
  String id, {
  ShoppingItemStatus status = ShoppingItemStatus.pending,
  ShoppingSyncStatus syncStatus = ShoppingSyncStatus.synced,
  int version = 1,
  double? price,
}) =>
    ShoppingItem(
      id: id,
      householdId: 'h1',
      name: 'Món $id',
      quantity: 1,
      unit: 'kg',
      displayQuantity: 1,
      displayUnit: 'kg',
      status: status,
      source: ShoppingItemSource.manual,
      version: version,
      createdAt: DateTime.utc(2026, 11, 20),
      updatedAt: DateTime.utc(2026, 11, 20),
      price: price,
      syncStatus: syncStatus,
    );

class _FakeApi implements ShoppingApi {
  final List<(String, int, double?)> toggles = <(String, int, double?)>[];
  bool offline = false;
  final Map<String, ApiException> rejectById = <String, ApiException>{};

  @override
  Future<ShoppingItem> toggle(
    String id,
    int version,
    String householdId, {
    double? price,
  }) async {
    if (offline) throw NetworkException();
    final reject = rejectById[id];
    if (reject != null) throw reject;
    toggles.add((id, version, price));
    return _item(
      id,
      status: ShoppingItemStatus.completed,
      version: version + 1,
      price: price,
    );
  }

  @override
  Future<ShoppingItem> create(
    Map<String, dynamic> payload,
    String householdId, {
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<ShoppingItem> assign(
    String id,
    int version,
    String householdId, {
    required String? assigneeId,
  }) =>
      throw UnimplementedError();

  /// Dùng cho sync() sau 409 — trả bản server chưa đổi.
  List<ShoppingItem> serverItems = <ShoppingItem>[];
  int listCalls = 0;
  Object? listError;

  @override
  Future<List<ShoppingItem>> list(String householdId) async {
    listCalls++;
    if (listError != null) throw listError!;
    return serverItems;
  }
}

class _FakeConnectivity extends ConnectivityService {
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
  late _FakeConnectivity conn;
  late ShoppingStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ShoppingDao(db);
    api = _FakeApi();
    conn = _FakeConnectivity();
    final session = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
    )..applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    store = ShoppingStore(
      dao: dao,
      api: api,
      connectivity: conn,
      session: session,
    );
  });
  tearDown(() => db.close());

  test('PENDING → COMPLETED, giá truyền đúng xuống ShoppingApi.toggle',
      () async {
    await dao.upsert(_item('a'));
    await dao.upsert(_item('b'));

    final failed = await store.bulkCheck(<String, double?>{
      'a': 45000,
      'b': null,
    });

    expect(failed, isEmpty);
    expect(api.toggles, <(String, int, double?)>[
      ('a', 1, 45000.0),
      ('b', 1, null),
    ]);
    expect((await dao.getById('a'))!.status, ShoppingItemStatus.completed);
    expect((await dao.getById('a'))!.price, 45000);
    expect((await dao.getById('b'))!.status, ShoppingItemStatus.completed);
  });

  test('món COMPLETED sẵn → không gọi toggle, không failed (Guard 1)',
      () async {
    await dao.upsert(_item('a', status: ShoppingItemStatus.completed));

    final failed = await store.bulkCheck(<String, double?>{'a': 10000});

    expect(failed, isEmpty);
    expect(api.toggles, isEmpty);
    expect((await dao.getById('a'))!.status, ShoppingItemStatus.completed);
  });

  test('id trùng trong lần gọi chỉ toggle 1 lần (Map đã dedupe từ store)',
      () async {
    await dao.upsert(_item('a'));
    // Map không thể có 2 key trùng — gọi 2 lần liên tiếp mô phỏng chạy lại:
    // lần 2 thấy COMPLETED nên không đảo về PENDING.
    await store.bulkCheck(<String, double?>{'a': null});
    final failed = await store.bulkCheck(<String, double?>{'a': null});

    expect(failed, isEmpty);
    expect(api.toggles, hasLength(1));
    expect((await dao.getById('a'))!.status, ShoppingItemStatus.completed);
  });

  test('row không tồn tại kể cả sau sync 1 lần → failed', () async {
    await dao.upsert(_item('a'));
    api.serverItems = <ShoppingItem>[_item('a')];

    final failed = await store.bulkCheck(<String, double?>{
      'missing': null,
      'other-missing': null,
      'a': null,
    });

    expect(failed, <String>['missing', 'other-missing']);
    expect(api.listCalls, 1); // sync đúng 1 lần dù thiếu 2 id
    expect(api.toggles.map((t) => t.$1), <String>['a']);
  });

  test('id chưa có trong Drift nhưng có ở server → sync rồi toggle', () async {
    api.serverItems = <ShoppingItem>[_item('fresh')];

    final failed = await store.bulkCheck(<String, double?>{'fresh': 30000});

    expect(failed, isEmpty);
    expect(api.listCalls, 1);
    expect(api.toggles, <(String, int, double?)>[('fresh', 1, 30000.0)]);
    expect((await dao.getById('fresh'))!.status, ShoppingItemStatus.completed);
  });

  test('đủ id trong Drift → không sync', () async {
    await dao.upsert(_item('a'));

    await store.bulkCheck(<String, double?>{'a': null});

    expect(api.listCalls, 0);
  });

  for (final (label, error) in <(String, Object)>[
    ('ApiException', NetworkException()),
    ('lỗi không phải ApiException', StateError('list crashed')),
  ]) {
    test('sync() ném $label → bulkCheck không throw, id thiếu thành failed',
        () async {
      await dao.upsert(_item('a'));
      api.listError = error;

      final failed = await store.bulkCheck(<String, double?>{
        'missing': 10000,
        'a': null,
      });

      expect(failed, <String>['missing']);
      expect(api.listCalls, 1);
      expect(api.toggles.map((t) => t.$1), <String>['a']);
      expect((await dao.getById('a'))!.status, ShoppingItemStatus.completed);
    });
  }

  test('offline + thiếu id → không sync, failed', () async {
    conn.online = false;

    final failed = await store.bulkCheck(<String, double?>{'missing': null});

    expect(failed, <String>['missing']);
    expect(api.listCalls, 0);
  });

  test('row pendingCreate → failed, không toggle', () async {
    await dao.upsert(
      _item('a', syncStatus: ShoppingSyncStatus.pendingCreate),
    );

    final failed = await store.bulkCheck(<String, double?>{'a': null});

    expect(failed, <String>['a']);
    expect(api.toggles, isEmpty);
  });

  test('API 409 → toggle rollback → failed; món khác vẫn thành công', () async {
    await dao.upsert(_item('a'));
    await dao.upsert(_item('b'));
    api.serverItems = <ShoppingItem>[_item('a', version: 2), _item('b')];
    api.rejectById['a'] =
        BusinessException('ERR_SHOP_ITEM_VERSION_CONFLICT', 'conflict');

    final failed = await store.bulkCheck(<String, double?>{
      'a': null,
      'b': null,
    });

    expect(failed, <String>['a']);
    expect((await dao.getById('a'))!.status, ShoppingItemStatus.pending);
    expect((await dao.getById('b'))!.status, ShoppingItemStatus.completed);
  });

  test('offline → enqueue, row COMPLETED (pendingToggle) → không failed',
      () async {
    conn.online = false;
    await dao.upsert(_item('a'));

    final failed = await store.bulkCheck(<String, double?>{'a': 20000});

    expect(failed, isEmpty);
    expect(api.toggles, isEmpty);
    final row = (await dao.getById('a'))!;
    expect(row.status, ShoppingItemStatus.completed);
    expect(row.syncStatus, ShoppingSyncStatus.pendingToggle);
    expect(await dao.queue('h1'), hasLength(1));
  });

  test(
      'pending + pendingToggle (vừa bỏ tick offline) → không failed; '
      'huỷ cặp → giá hoá đơn KHÔNG được ghi (hành vi hiện có, chấp nhận)',
      () async {
    conn.online = false;
    final completed =
        _item('a', status: ShoppingItemStatus.completed, price: 10000);
    await dao.upsert(completed);
    await store.toggle(completed); // bỏ tick offline → PENDING/pendingToggle

    final failed = await store.bulkCheck(<String, double?>{'a': 50000});

    expect(failed, isEmpty);
    final row = (await dao.getById('a'))!;
    expect(row.status, ShoppingItemStatus.completed);
    expect(row.syncStatus, ShoppingSyncStatus.synced);
    expect(row.price, 10000); // giá server cũ, không phải 50000
    expect(await dao.queue('h1'), isEmpty);
    expect(api.toggles, isEmpty);
  });
}
