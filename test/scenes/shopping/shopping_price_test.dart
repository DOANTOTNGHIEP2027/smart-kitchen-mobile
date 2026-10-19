import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/widgets/price_capture_sheet.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

ShoppingItem item({ShoppingItemStatus status = ShoppingItemStatus.pending, int version = 1, double? price}) => ShoppingItem(
      id: 'i1',
      householdId: 'h1',
      name: 'Cà chua',
      quantity: 1,
      unit: 'kg',
      displayQuantity: 1,
      displayUnit: 'kg',
      status: status,
      source: ShoppingItemSource.manual,
      version: version,
      createdAt: DateTime.utc(2026, 10, 19),
      updatedAt: DateTime.utc(2026, 10, 19),
      price: price,
    );

class _FakeApi implements ShoppingApi {
  final List<(String, int, double?)> toggles = <(String, int, double?)>[];
  bool offline = false;
  ApiException? reject;

  @override
  Future<ShoppingItem> toggle(String id, int version, String householdId, {double? price}) async {
    if (offline) throw NetworkException();
    if (reject != null) throw reject!;
    toggles.add((id, version, price));
    // BE: giá sticky — chỉ đổi khi có price mới.
    return item(status: ShoppingItemStatus.completed, version: version + 1, price: price);
  }

  @override
  Future<ShoppingItem> create(Map<String, dynamic> payload, String householdId, {String? idempotencyKey}) =>
      throw UnimplementedError();

  @override
  Future<ShoppingItem> assign(String id, int version, String householdId, {required String? assigneeId}) =>
      throw UnimplementedError();

  @override
  Future<List<ShoppingItem>> list(String householdId) async => <ShoppingItem>[];
}

class _SpyStore implements ShoppingStore {
  _SpyStore(this.current);
  List<ShoppingItem> current;
  final List<ShoppingItem> toggled = <ShoppingItem>[];

  @override
  List<ShoppingItem> get items => current;

  @override
  Future<void> toggle(ShoppingItem item, {double? price}) async => toggled.add(item);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  group('ShoppingApi.toggle — chỉ gửi price khi có giá (Guard #13)', () {
    Future<Map<String, dynamic>> bodyOf(double? price) async {
      final adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<String, dynamic>{
            'id': 'i1', 'shoppingListId': null, 'name': 'x', 'quantity': 1, 'unit': 'kg',
            'displayQuantity': 1, 'displayUnit': 'kg', 'category': null, 'status': 'COMPLETED',
            'source': 'MANUAL', 'version': 2, 'createdBy': null, 'price': 55000, 'priceCurrency': 'VND',
            'assignedTo': null, 'createdAt': '2026-10-19T00:00:00Z', 'updatedAt': '2026-10-19T00:00:00Z',
          })));
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = adapter;
      final api = ShoppingApiImpl(DioClient.build(tokenStorage: TokenStorage(), dio: dio));
      final res = await api.toggle('i1', 1, 'h1', price: price);
      expect(res.price, 55000.0); // int JSON → double
      return adapter.requests.single.data as Map<String, dynamic>;
    }

    test('có giá → gửi price + currency VND', () async {
      expect(await bodyOf(55000), <String, dynamic>{'version': 1, 'price': 55000.0, 'currency': 'VND'});
    });

    test('không giá → KHÔNG có key price/currency (không gửi "price": null)', () async {
      final body = await bodyOf(null);
      expect(body.keys, <String>['version']);
    });
  });

  group('ShoppingStore.toggle với giá', () {
    late AppDatabase db;
    late ShoppingDao dao;
    late _FakeApi api;
    late _FakeConnectivity conn;
    late ShoppingStore store;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = ShoppingDao(db);
      api = _FakeApi();
      conn = _FakeConnectivity();
      final session = SessionStore(
        TokenStorage(),
        AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
      )..applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
      store = ShoppingStore(dao: dao, api: api, connectivity: conn, session: session);
    });
    tearDown(() => db.close());

    test('PENDING → COMPLETED gửi giá và lưu Drift', () async {
      await dao.upsert(item());
      await store.toggle(item(), price: 55000);
      expect(api.toggles.single, ('i1', 1, 55000.0));
      expect((await dao.getById('i1'))!.price, 55000);
    });

    test('COMPLETED → PENDING KHÔNG gửi giá dù caller truyền', () async {
      final done = item(status: ShoppingItemStatus.completed, price: 30000);
      await dao.upsert(done);
      await store.toggle(done, price: 99999);
      expect(api.toggles.single.$3, isNull);
    });

    test('offline: giá vào hàng đợi rồi phát lại đúng khi drain', () async {
      await dao.upsert(item());
      conn.online = false;
      await store.toggle(item(), price: 42000);
      expect(api.toggles, isEmpty);
      expect((await dao.getById('i1'))!.price, 42000); // optimistic
      conn.online = true;
      await store.sync();
      expect(api.toggles.single, ('i1', 1, 42000.0));
    });

    // §5.4 AM-CAO-2: huỷ cặp phải đưa row về ĐÚNG state server trước lần toggle
    // đầu — status PENDING và giá sticky cũ (không giữ "giá ma" của lần 1).
    for (final double? original in <double?>[null, 30000]) {
      test('offline tick kèm giá rồi bỏ tick → huỷ cặp, về PENDING + giá $original', () async {
        await dao.upsert(item(price: original));
        conn.online = false;
        await store.toggle(item(price: original), price: 42000);
        await store.toggle((await dao.getById('i1'))!);
        final row = (await dao.getById('i1'))!;
        expect(row.status, ShoppingItemStatus.pending);
        expect(row.syncStatus, ShoppingSyncStatus.synced);
        expect(row.price, original);
        expect(await dao.queue('h1'), isEmpty);
        expect(api.toggles, isEmpty);
      });
    }
  });

  group('ShoppingStore — toggle bị từ chối vì món đã đổi (AM-TB-4)', () {
    late AppDatabase db;
    late ShoppingDao dao;
    late _FakeApi api;
    late _FakeConnectivity conn;
    late ShoppingStore store;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = ShoppingDao(db);
      api = _FakeApi();
      conn = _FakeConnectivity();
      final session = SessionStore(
        TokenStorage(),
        AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
      )..applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
      store = ShoppingStore(dao: dao, api: api, connectivity: conn, session: session);
    });
    tearDown(() => db.close());

    // BE kiểm "price chỉ khi COMPLETED" TRƯỚC version ⇒ món đã được tick ở nơi
    // khác trả 400, không phải 409. Không được kẹt hàng đợi mãi.
    test('drain entry MANG GIÁ gặp 400 → bỏ entry, row SYNCED, báo mất giá', () async {
      await dao.upsert(item());
      conn.online = false;
      await store.toggle(item(), price: 42000);
      conn.online = true;
      api.reject = ValidationException('ERR_VALIDATION_FAILED', 'x',
          fieldErrors: <String, String>{'price': 'only allowed when completing'});
      await store.sync();
      expect(await dao.queue('h1'), isEmpty);
      expect((await dao.getById('i1'))!.syncStatus, ShoppingSyncStatus.synced);
      expect(store.priceNotSaved, isTrue);
    });

    test('drain entry KHÔNG giá gặp 409 → bỏ entry, KHÔNG báo', () async {
      await dao.upsert(item());
      conn.online = false;
      await store.toggle(item());
      conn.online = true;
      api.reject = BusinessException('ERR_SHOP_ITEM_VERSION_CONFLICT', 'x');
      await store.sync();
      expect(await dao.queue('h1'), isEmpty);
      expect(store.priceNotSaved, isFalse);
    });

    test('online: tick kèm giá gặp 409 → rollback + báo mất giá', () async {
      await dao.upsert(item());
      api.reject = BusinessException('ERR_SHOP_ITEM_VERSION_CONFLICT', 'x');
      await store.toggle(item(), price: 42000);
      expect((await dao.getById('i1'))!.status, ShoppingItemStatus.pending);
      expect(store.priceNotSaved, isTrue);
    });

    test('online nhưng row còn entry chờ → huỷ cặp, KHÔNG gọi API theo state cũ', () async {
      await dao.upsert(item());
      conn.online = false;
      await store.toggle(item(), price: 42000);
      conn.online = true;
      await store.toggle((await dao.getById('i1'))!);
      expect(api.toggles, isEmpty);
      expect(await dao.queue('h1'), isEmpty);
      final row = (await dao.getById('i1'))!;
      expect(row.status, ShoppingItemStatus.pending);
      expect(row.syncStatus, ShoppingSyncStatus.synced);
    });
  });

  group('PriceCaptureSheet', () {
    Future<Completer<double?>> open(WidgetTester tester) async {
      final result = Completer<double?>();
      await tester.pumpAppWidget(Builder(
        builder: (context) => TextButton(
          onPressed: () async => result.complete(await showModalBottomSheet<double>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const PriceCaptureSheet(itemName: 'Cà chua'),
          )),
          child: const Text('open'),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('Bỏ qua → null; Lưu khoá khi rỗng', (tester) async {
      final r = await open(tester);
      final save = tester.widget<ElevatedButton>(find.descendant(
          of: find.byKey(const ValueKey<String>('price-save')), matching: find.byType(ElevatedButton)));
      expect(save.onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey<String>('price-skip')));
      await tester.pumpAndSettle();
      expect(await r.future, isNull);
    });

    testWidgets('gõ 55000 → hiện 55.000, Lưu trả 55000; 0 → gợi ý bỏ qua', (tester) async {
      final r = await open(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('price-input')), '0');
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('price-zero-hint')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey<String>('price-input')), '55000');
      await tester.pump();
      expect(find.text('55.000'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('price-save')));
      await tester.pumpAndSettle();
      expect(await r.future, 55000);
    });

    testWidgets('sửa chữ số ở giữa → con trỏ giữ vị trí, không nhảy về cuối', (tester) async {
      await open(tester);
      final input = find.byKey(const ValueKey<String>('price-input'));
      await tester.enterText(input, '55000');
      await tester.pump();
      // Chèn '1' sau chữ số đầu: "5|5.000" → "51|5.000" → nhóm lại "515.000".
      tester.testTextInput.updateEditingValue(const TextEditingValue(
          text: '515.000', selection: TextSelection.collapsed(offset: 2)));
      await tester.pump();
      final controller = tester.widget<TextField>(input).controller!;
      expect(controller.text, '515.000');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('đủ 10 chữ số mà chèn thêm ở giữa → giữ nguyên, không cắt chữ số cuối', (tester) async {
      await open(tester);
      final input = find.byKey(const ValueKey<String>('price-input'));
      await tester.enterText(input, '1234567890');
      await tester.pump();
      tester.testTextInput.updateEditingValue(const TextEditingValue(
          text: '15.234.567.890', selection: TextSelection.collapsed(offset: 2)));
      await tester.pump();
      expect(tester.widget<TextField>(input).controller!.text, '1.234.567.890');
    });

    testWidgets('số 0 đứng đầu bị bỏ: 0055 → 55', (tester) async {
      await open(tester);
      final input = find.byKey(const ValueKey<String>('price-input'));
      await tester.enterText(input, '0055');
      await tester.pump();
      expect(tester.widget<TextField>(input).controller!.text, '55');
    });

    testWidgets('sheet đang mở mà món đã được tick ở nơi khác → không toggle ngược', (tester) async {
      final spy = _SpyStore(<ShoppingItem>[item()]);
      await tester.pumpAppWidget(Builder(
        builder: (context) => TextButton(
          onPressed: () => toggleShoppingItemWithPrice(context, spy, item()),
          child: const Text('tick'),
        ),
      ));
      await tester.tap(find.text('tick'));
      await tester.pumpAndSettle();
      spy.current = <ShoppingItem>[item(status: ShoppingItemStatus.completed, version: 2)];
      await tester.tap(find.byKey(const ValueKey<String>('price-skip')));
      await tester.pumpAndSettle();
      expect(spy.toggled, isEmpty);
    });

    test('parse: rỗng → null, có dấu chấm → số', () {
      expect(PriceCaptureSheet.parse(''), isNull);
      expect(PriceCaptureSheet.parse('1.250.000'), 1250000);
    });
  });
}
