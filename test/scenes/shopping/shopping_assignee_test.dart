import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/family_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_roster.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/family_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/widgets/assignee_widgets.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

const String kOtherId = '8d4e6a10-0000-4000-8000-000000000001';

ShoppingItem item({String id = 'i1', String? assignedTo, ShoppingSyncStatus sync = ShoppingSyncStatus.synced, ShoppingItemStatus status = ShoppingItemStatus.pending}) => ShoppingItem(
      id: id,
      householdId: 'h1',
      name: 'Cà chua',
      quantity: 1,
      unit: 'kg',
      displayQuantity: 1,
      displayUnit: 'kg',
      status: status,
      source: ShoppingItemSource.manual,
      version: 3,
      createdAt: DateTime.utc(2026, 10, 19),
      updatedAt: DateTime.utc(2026, 10, 19),
      syncStatus: sync,
      assignedTo: assignedTo,
    );

class _FakeApi implements ShoppingApi {
  final List<(String, int, String?)> assigns = <(String, int, String?)>[];
  Object? assignError;
  Completer<void>? assignGate;
  /// `null` = server trả đúng những gì đang có ở máy (mirror) — list rỗng
  /// sẽ khiến bước reconcile của sync xoá row cục bộ.
  List<ShoppingItem>? listed;
  Future<List<ShoppingItem>> Function()? mirror;
  Completer<void>? listGate;
  int listCalls = 0;

  @override
  Future<ShoppingItem> assign(String id, int version, String householdId, {required String? assigneeId}) async {
    assigns.add((id, version, assigneeId));
    await assignGate?.future;
    if (assignError != null) throw assignError!;
    return ShoppingItem(
      id: id, householdId: householdId, name: 'Cà chua', quantity: 1, unit: 'kg', displayQuantity: 1, displayUnit: 'kg',
      status: ShoppingItemStatus.pending, source: ShoppingItemSource.manual, version: version + 1,
      createdAt: DateTime.utc(2026, 10, 19), updatedAt: DateTime.utc(2026, 10, 19), assignedTo: assigneeId,
    );
  }

  @override
  Future<ShoppingItem> toggle(String id, int version, String householdId, {double? price}) => throw UnimplementedError();
  @override
  Future<ShoppingItem> create(Map<String, dynamic> payload, String householdId, {String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<List<ShoppingItem>> list(String householdId) async {
    listCalls++;
    final snapshot = listed ?? await mirror?.call() ?? <ShoppingItem>[]; // chụp lúc gửi request, như server thật
    await listGate?.future;
    return snapshot;
  }
}

class _FakeConnectivity extends ConnectivityService {
  bool online = true;
  @override
  Future<bool> isOnline() async => online;
  @override
  Stream<void> get onConnectivityRestored => const Stream<void>.empty();
}

SessionStore session() => SessionStore(TokenStorage(), AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))))
  ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
  ..applyHouseholdContext(householdId: 'h1', role: 'MEMBER');

HouseholdMember member(String id, String role, String name) =>
    HouseholdMember(userId: id, fullName: name, role: role, provider: 'EMAIL', joinedAt: DateTime.utc(2026));

class _FakeFamilyApi implements FamilyApi {
  Completer<void>? gate;
  bool fail = false;
  @override
  Future<HouseholdRoster> getMyHousehold() async {
    await gate?.future;
    if (fail) throw NetworkException();
    final members = <HouseholdMember>[
      member('me', 'OWNER', 'Tôi'),
      member(kOtherId, 'MEMBER', 'Lan'),
      member('viewer', 'REMOTE_VIEWER', 'Bà ngoại'),
      member('future', 'SUPER_ADMIN', 'Ai đó'),
    ];
    return HouseholdRoster(id: 'h1', name: 'Nhà', ownerId: 'me', callerRole: 'OWNER', memberCount: members.length, members: members);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoHealth implements HealthApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  test('API assign: bỏ giao vẫn gửi key "assignedTo": null (Guard #14)', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<String, dynamic>{
          'id': 'i1', 'shoppingListId': null, 'name': 'x', 'quantity': 1, 'unit': 'kg', 'displayQuantity': 1,
          'displayUnit': 'kg', 'category': null, 'status': 'PENDING', 'source': 'MANUAL', 'version': 4,
          'createdBy': null, 'price': null, 'priceCurrency': null, 'assignedTo': null,
          'createdAt': '2026-10-19T00:00:00Z', 'updatedAt': '2026-10-19T00:00:00Z',
        })));
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = adapter;
    final api = ShoppingApiImpl(DioClient.build(tokenStorage: TokenStorage(), dio: dio));
    await api.assign('i1', 3, 'h1', assigneeId: null);
    final req = adapter.requests.single;
    expect(req.method, 'PATCH');
    expect(req.path, '/api/v1/shopping/items/i1');
    final body = req.data as Map<String, dynamic>;
    expect(body.containsKey('assignedTo'), isTrue);
    expect(body, <String, dynamic>{'version': 3, 'assignedTo': null});
  });

  group('ShoppingStore.assign', () {
    late AppDatabase db;
    late ShoppingDao dao;
    late _FakeApi api;
    late _FakeConnectivity conn;
    late ShoppingStore store;
    var rosterStale = 0;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = ShoppingDao(db);
      api = _FakeApi()..mirror = () => dao.getAll('h1');
      conn = _FakeConnectivity();
      rosterStale = 0;
      store = ShoppingStore(dao: dao, api: api, connectivity: conn, session: session(), onRosterStale: () => rosterStale++);
      await store.init();
    });
    tearDown(() => db.close());

    test('thành công → lưu assignedTo từ server; badge chỉ đếm món CHƯA MUA của mình', () async {
      await dao.upsert(item());
      await dao.upsert(item(id: 'done', assignedTo: 'me', status: ShoppingItemStatus.completed));
      expect(await store.assign(item(), assigneeId: 'me'), isTrue);
      expect(api.assigns.single, ('i1', 3, 'me'));
      expect((await dao.getById('i1'))!.assignedTo, 'me');
      await Future<void>.delayed(Duration.zero);
      expect(store.assignedToMeCount, 1);
    });

    test('row chưa SYNCED → KHÔNG gọi API (Guard #18); offline → KHÔNG gọi API', () async {
      await dao.upsert(item(sync: ShoppingSyncStatus.pendingToggle));
      expect(await store.assign(item(), assigneeId: 'me'), isFalse);
      await dao.upsert(item());
      conn.online = false;
      expect(await store.assign(item(), assigneeId: 'me'), isFalse);
      expect(api.assigns, isEmpty);
    });

    test('ERR_SHOP_ASSIGNEE_INVALID → báo lỗi + nạp lại roster', () async {
      await dao.upsert(item());
      api.assignError = BusinessException('ERR_SHOP_ASSIGNEE_INVALID', 'invalid');
      expect(await store.assign(item(), assigneeId: kOtherId), isFalse);
      expect(store.assignError!.code, 'ERR_SHOP_ASSIGNEE_INVALID');
      expect(rosterStale, 1);
      expect((await dao.getById('i1'))!.assignedTo, isNull);
    });

    test('2 lần gán sát nhau → CHỈ 1 PATCH (không 409 giả)', () async {
      await dao.upsert(item());
      final r = await Future.wait(<Future<bool>>[
        store.assign(item(), assigneeId: 'me'),
        store.assign(item(), assigneeId: 'me'),
      ]);
      expect(api.assigns, hasLength(1));
      expect(r.where((ok) => ok), hasLength(1));
    });

    test('row thành PENDING_TOGGLE lúc PATCH đang bay → KHÔNG ghi đè (Guard #18)', () async {
      await dao.upsert(item());
      api.assignGate = Completer<void>();
      final pending = store.assign(item(), assigneeId: 'me');
      await Future<void>.delayed(Duration.zero);
      await dao.upsert(item(sync: ShoppingSyncStatus.pendingToggle, status: ShoppingItemStatus.completed));
      api.assignGate!.complete();
      await pending;
      final row = (await dao.getById('i1'))!;
      expect(row.syncStatus, ShoppingSyncStatus.pendingToggle);
      expect(row.status, ShoppingItemStatus.completed);
    });

    test('list() của sync chụp TRƯỚC khi PATCH gán về → không lùi assignedTo', () async {
      await dao.upsert(item());
      api.listed = <ShoppingItem>[item()]; // version 3, chưa giao
      api.listGate = Completer<void>();
      final before = api.listCalls;
      final syncing = store.sync();
      while (api.listCalls == before) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(await store.assign(item(), assigneeId: 'me'), isTrue);
      api.listGate!.complete();
      await syncing;
      final row = (await dao.getById('i1'))!;
      expect(row.version, 4);
      expect(row.assignedTo, 'me');
    });

    test('server trả version THẤP hơn (Demo reset/reseed), không có gán đang chạy → vẫn nhận bản server', () async {
      await dao.upsert(item(assignedTo: 'me', status: ShoppingItemStatus.completed).copyWith(version: 7));
      api.listed = <ShoppingItem>[item()]; // version 3, PENDING, chưa giao
      await store.sync();
      final row = (await dao.getById('i1'))!;
      expect(row.version, 3);
      expect(row.status, ShoppingItemStatus.pending);
      expect(row.assignedTo, isNull);
    });
  });

  group('Widget (Guard #15, whitelist, degrade)', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    FamilyStore family(_FakeFamilyApi api) => FamilyStore(api, _NoHealth(), ReadCacheDao(db), session());

    Widget chip(ShoppingItem i, FamilyStore? f) =>
        AssigneeChip(item: i, familyStore: f, currentUserId: 'me', enabled: true, onTap: () {});

    testWidgets('roster đang tải → không chữ, KHÔNG UUID, KHÔNG "Thành viên cũ"', (tester) async {
      final api = _FakeFamilyApi()..gate = Completer<void>();
      final f = family(api);
      unawaited(f.loadRoster());
      await tester.pumpAppWidget(chip(item(assignedTo: kOtherId), f));
      expect(find.textContaining(kOtherId), findsNothing);
      expect(find.text('Thành viên cũ'), findsNothing);
      api.gate!.complete();
    });

    testWidgets('roster xong: tên đúng; UUID lạ → "Thành viên cũ"; của mình → "Tôi"', (tester) async {
      final f = family(_FakeFamilyApi());
      await tester.runAsync(f.loadRoster);
      await tester.pumpAppWidget(chip(item(assignedTo: kOtherId), f));
      expect(find.text('Lan'), findsOneWidget);
      await tester.pumpAppWidget(chip(item(assignedTo: 'ghost-uuid'), f));
      expect(find.text('Thành viên cũ'), findsOneWidget);
      expect(find.textContaining('ghost-uuid'), findsNothing);
      await tester.pumpAppWidget(chip(item(assignedTo: 'me'), f));
      expect(find.text('Tôi'), findsOneWidget);
    });

    testWidgets('chip disabled NUỐT tap — không lọt xuống tile để tick món', (tester) async {
      var rowTaps = 0;
      var chipTaps = 0;
      await tester.pumpAppWidget(InkWell(
        onTap: () => rowTaps++,
        child: AssigneeChip(item: item(), familyStore: null, currentUserId: 'me', enabled: false, onTap: () => chipTaps++),
      ));
      await tester.tap(find.byKey(const ValueKey<String>('assignee-chip-i1')));
      await tester.pump();
      expect(rowTaps, 0);
      expect(chipTaps, 0);
    });

    testWidgets('roster từ CACHE không thấy người → KHÔNG khẳng định "Thành viên cũ"', (tester) async {
      final api = _FakeFamilyApi();
      final f = family(api);
      await tester.runAsync(() async {
        await f.loadRoster();
        await Future<void>.delayed(const Duration(milliseconds: 50)); // cache.put chạy nền
        api.fail = true;
        await f.loadRoster();
      });
      expect(f.rosterIsFromCache, isTrue);
      await tester.pumpAppWidget(chip(item(assignedTo: 'newcomer'), f));
      expect(find.text('Thành viên cũ'), findsNothing);
      expect(find.textContaining('newcomer'), findsNothing);
      await tester.pumpAppWidget(chip(item(assignedTo: kOtherId), f));
      expect(find.text('Lan'), findsOneWidget);
    });

    testWidgets('picker mở lúc roster đang tải → tự hiện thành viên khi roster về', (tester) async {
      final api = _FakeFamilyApi()..gate = Completer<void>();
      final f = family(api);
      final load = f.loadRoster();
      await tester.pumpAppWidget(AssigneePickerSheet(item: item(), familyStore: f, currentUserId: 'me'));
      expect(find.text('Lan'), findsNothing);
      await tester.runAsync(() async {
        api.gate!.complete();
        await load;
      });
      await tester.pump();
      expect(find.text('Lan'), findsOneWidget);
    });

    testWidgets('picker: chỉ OWNER/MEMBER (loại REMOTE_VIEWER + role lạ), có "Bỏ giao" khi đang giao', (tester) async {
      final f = family(_FakeFamilyApi());
      await tester.runAsync(f.loadRoster);
      await tester.pumpAppWidget(AssigneePickerSheet(item: item(assignedTo: kOtherId), familyStore: f, currentUserId: 'me'));
      expect(find.byKey(const ValueKey<String>('assignee-me')), findsOneWidget);
      expect(find.text('Lan'), findsOneWidget);
      expect(find.text('Bà ngoại'), findsNothing);
      expect(find.text('Ai đó'), findsNothing);
      expect(find.byKey(const ValueKey<String>('assignee-clear')), findsOneWidget);
    });

    testWidgets('không có FamilyStore → picker rút gọn, không crash', (tester) async {
      await tester.pumpAppWidget(AssigneePickerSheet(item: item(assignedTo: kOtherId), familyStore: null, currentUserId: 'me'));
      expect(find.byKey(const ValueKey<String>('assignee-me')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('assignee-clear')), findsOneWidget);
      expect(find.text('Lan'), findsNothing);
    });
  });
}
