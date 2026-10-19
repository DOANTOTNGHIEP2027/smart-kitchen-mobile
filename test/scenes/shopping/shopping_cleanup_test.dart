import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/widgets/assignee_widgets.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

ShoppingItem item(String id, {ShoppingItemStatus status = ShoppingItemStatus.pending, int version = 1, ShoppingSyncStatus sync = ShoppingSyncStatus.synced, String? assignedTo}) => ShoppingItem(
      id: id, householdId: 'h1', name: 'Món $id', quantity: 1, unit: 'kg', displayQuantity: 1, displayUnit: 'kg',
      status: status, source: ShoppingItemSource.manual, version: version,
      createdAt: DateTime.utc(2026, 10, 19), updatedAt: DateTime.utc(2026, 10, 19), syncStatus: sync, assignedTo: assignedTo,
    );

class _FakeApi implements ShoppingApi {
  List<ShoppingItem> serverItems = <ShoppingItem>[];
  final Map<String, ApiException> toggleErrors = <String, ApiException>{};
  final List<String> toggled = <String>[];
  Completer<void>? toggleGate;
  Completer<void>? listGate;
  /// Status server theo món — mỗi toggle đảo chiều (mặc định PENDING).
  final Map<String, ShoppingItemStatus> serverStatus = <String, ShoppingItemStatus>{};

  @override
  Future<ShoppingItem> toggle(String id, int version, String householdId, {double? price}) async {
    toggled.add(id);
    await toggleGate?.future;
    final e = toggleErrors[id];
    if (e != null) throw e;
    final next = serverStatus[id] == ShoppingItemStatus.completed ? ShoppingItemStatus.pending : ShoppingItemStatus.completed;
    serverStatus[id] = next;
    return item(id, status: next, version: version + 1);
  }

  @override
  Future<List<ShoppingItem>> list(String householdId) async {
    final snapshot = serverItems; // chụp lúc gửi request, như server thật
    await listGate?.future;
    return snapshot;
  }
  ApiException? createError;
  @override
  Future<ShoppingItem> create(Map<String, dynamic> payload, String householdId, {String? idempotencyKey}) async {
    if (createError != null) throw createError!;
    throw UnimplementedError();
  }
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

  test('reconcile: row SYNCED mà server không còn → xoá; row PENDING giữ cho drain', () async {
    await dao.upsert(item('gone'));
    await dao.upsert(item('local-new', sync: ShoppingSyncStatus.pendingCreate));
    api.serverItems = <ShoppingItem>[item('keep')];
    // pendingCreate không có entry nên drain bỏ qua; sync chỉ reconcile.
    await store.sync();
    expect(await dao.getById('gone'), isNull);
    expect(await dao.getById('keep'), isNotNull);
    expect(await dao.getById('local-new'), isNotNull);
  });

  test('drain: NOT_FOUND / LIST_NOT_ACTIVE → bỏ entry, KHÔNG kẹt các entry sau', () async {
    await dao.upsert(item('a'));
    await dao.upsert(item('b'));
    conn.online = false;
    await store.toggle(item('a'));
    await store.toggle(item('b'));
    conn.online = true;
    api.toggleErrors['a'] = BusinessException('ERR_SHOP_ITEM_NOT_FOUND', 'gone');
    api.serverItems = <ShoppingItem>[item('b', status: ShoppingItemStatus.completed, version: 2)];
    await store.sync();
    expect(api.toggled, <String>['a', 'b']); // b vẫn được gửi
    expect(await dao.queue('h1'), isEmpty);
    expect(await dao.getById('a'), isNull);
  });

  test('reconcile: row thành SYNCED trong lúc list() bay (remap add() online) → KHÔNG xoá', () async {
    api.listGate = Completer<void>();
    final syncing = store.sync();
    await Future<void>.delayed(Duration.zero);
    // add() online vừa remap xong — bản chụp list() của server chưa có món này.
    await dao.upsert(item('fresh'));
    api.listGate!.complete();
    await syncing;
    expect(await dao.getById('fresh'), isNotNull);
  });

  test('toggle online: NOT_FOUND → xoá row, không rollback (§10)', () async {
    await dao.upsert(item('a'));
    api.toggleErrors['a'] = BusinessException('ERR_SHOP_ITEM_NOT_FOUND', 'gone');
    await store.toggle(item('a'));
    expect(await dao.getById('a'), isNull);
  });

  test('race: bỏ tick đúng lúc drain đang gửi lần tick → toggle đảo lại tới server ngay', () async {
    await dao.upsert(item('x'));
    conn.online = false;
    await store.toggle(item('x')); // T1 vào hàng đợi
    conn.online = true;
    api.toggleGate = Completer<void>();
    final draining = store.sync(); // T1 đang bay
    await Future<void>.delayed(Duration.zero);
    // Người dùng bỏ tick → huỷ cặp, xoá entry T1 trong lúc nó đang bay.
    await store.toggle((await dao.getById('x'))!);
    api.toggleGate!.complete();
    api.serverItems = <ShoppingItem>[item('x', version: 3)];
    await draining;
    expect(api.toggled, <String>['x', 'x'], reason: 'phải gửi toggle đảo lại server');
    expect(await dao.queue('h1'), isEmpty);
    final row = (await dao.getById('x'))!;
    expect(row.status, ShoppingItemStatus.pending);
    expect(row.syncStatus, ShoppingSyncStatus.synced);
  });

  testWidgets('picker: chính mình là REMOTE_VIEWER → KHÔNG có "Tôi nhận"', (tester) async {
    await tester.pumpAppWidget(AssigneePickerSheet(
      item: item('x'),
      familyStore: null,
      currentUserId: 'me',
      selfRole: 'REMOTE_VIEWER',
    ));
    expect(find.byKey(const ValueKey<String>('assignee-me')), findsNothing);

    await tester.pumpAppWidget(AssigneePickerSheet(
      item: item('x'),
      familyStore: null,
      currentUserId: 'me',
      selfRole: 'MEMBER',
    ));
    expect(find.byKey(const ValueKey<String>('assignee-me')), findsOneWidget);
  });

  test('drain: CREATE bị từ chối vĩnh viễn → bỏ + xoá row, KHÔNG chặn toggle phía sau', () async {
    await dao.upsert(item('b'));
    conn.online = false;
    expect(await store.add('Bột ngọt', 1, 'hũ'), isTrue); // CREATE vào hàng đợi
    await store.toggle(item('b')); // TOGGLE xếp SAU
    conn.online = true;
    api.createError = BusinessException('ERR_SHOP_UNIT_INVALID', 'unit');
    api.serverItems = <ShoppingItem>[item('b', status: ShoppingItemStatus.completed, version: 2)];
    await store.sync();
    expect(api.toggled, contains('b'));
    expect(await dao.queue('h1'), isEmpty);
    expect((await dao.getAll('h1')).where((i) => i.name == 'Bột ngọt'), isEmpty);
    expect(store.error!.code, 'ERR_SHOP_UNIT_INVALID');
    expect(store.rejectedCreateName, 'Bột ngọt', reason: 'phải báo món bị gỡ, không im lặng');
  });

  test('toggle online: LIST_NOT_ACTIVE → xoá row như drain', () async {
    await dao.upsert(item('a'));
    api.toggleErrors['a'] = BusinessException('ERR_SHOP_LIST_NOT_ACTIVE', 'old week');
    await store.toggle(item('a'));
    expect(await dao.getById('a'), isNull);
  });

  test('drain: entry đã huỷ cặp sau khi chụp hàng đợi → KHÔNG gửi', () async {
    await dao.upsert(item('a'));
    await dao.upsert(item('b'));
    conn.online = false;
    await store.toggle(item('a'));
    await store.toggle(item('b'));
    conn.online = true;
    api.toggleGate = Completer<void>();
    api.serverItems = <ShoppingItem>[item('a', status: ShoppingItemStatus.completed, version: 2), item('b')];
    final draining = store.sync(); // a đang bay, b nằm trong bản chụp
    await Future<void>.delayed(Duration.zero);
    await store.toggle((await dao.getById('b'))!); // huỷ cặp b
    api.toggleGate!.complete();
    await draining;
    expect(api.toggled, <String>['a']);
    expect(await dao.queue('h1'), isEmpty);
  });

  testWidgets('chip disabled: bấm gọi onDisabledTap (báo "Đang đồng bộ")', (tester) async {
    var disabledTaps = 0;
    await tester.pumpAppWidget(AssigneeChip(
      item: item('x', sync: ShoppingSyncStatus.pendingToggle),
      familyStore: null,
      currentUserId: 'me',
      enabled: false,
      onTap: () {},
      onDisabledTap: () => disabledTaps++,
    ));
    await tester.tap(find.byType(AssigneeChip));
    expect(disabledTaps, 1);
  });

  test('ShoppingItem.isAssignedTo: null userId không bao giờ khớp', () {
    expect(item('x', assignedTo: null).isAssignedTo(null), isFalse);
    expect(item('x', assignedTo: 'me').isAssignedTo('me'), isTrue);
  });
}
