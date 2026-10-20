import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_category_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_category.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_share_text_builder.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/scenes/category_manager_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/scenes/shopping_list_binding.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/scenes/shopping_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/category_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/widgets/category_widgets.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/widgets/share_export_sheet.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

SessionStore session({bool withHousehold = true}) {
  final s = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))))
    ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi');
  if (withHousehold) s.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
  return s;
}

ShoppingCategory cat(String id, String name, {int order = 0, String color = '#34A853'}) => ShoppingCategory(
      id: id, householdId: 'h1', name: name, colorHex: color, sortOrder: order, createdAt: DateTime.utc(2026, 10, 20));

ShoppingItem item(String id, String name,
        {String? category, ShoppingItemStatus status = ShoppingItemStatus.pending, double qty = 1, String unit = 'kg', String? assignedTo, double? price}) =>
    ShoppingItem(
      id: id, householdId: 'h1', name: name, quantity: qty, unit: unit, displayQuantity: qty, displayUnit: unit,
      category: category, status: status, source: ShoppingItemSource.manual, version: 1,
      createdAt: DateTime.utc(2026, 10, 20), updatedAt: DateTime.utc(2026, 10, 20), assignedTo: assignedTo, price: price,
    );

/// DAO trong RAM cho widget test — tránh Drift trong fake-async (treo khi ghi
/// sau khi đã dựng scene).
class _MemDao extends ShoppingCategoryDao {
  _MemDao(super.db, [List<ShoppingCategory>? seed]) : rows = <ShoppingCategory>[...?seed];
  final List<ShoppingCategory> rows;
  final StreamController<List<ShoppingCategory>> _ctl = StreamController<List<ShoppingCategory>>.broadcast();
  final List<String> deleted = <String>[];
  bool failWrites = false;
  Completer<void>? reorderGate;
  bool failStream = false;

  void _emit() => _ctl.add(List<ShoppingCategory>.of(rows)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  @override
  Stream<List<ShoppingCategory>> watchAll(String householdId) {
    if (failStream) return Stream<List<ShoppingCategory>>.error(StateError('db corrupt'));
    scheduleMicrotask(_emit);
    return _ctl.stream;
  }

  @override
  Future<bool> existsByName(String householdId, String name, {String? exceptId}) async =>
      rows.any((r) => r.id != exceptId && r.name.trim().toLowerCase() == name.trim().toLowerCase());

  @override
  Future<int> nextSortOrder(String householdId) async =>
      rows.fold<int>(-1, (m, r) => r.sortOrder > m ? r.sortOrder : m) + 1;

  @override
  Future<void> insert(ShoppingCategory c) async {
    if (failWrites) throw StateError('disk full');
    rows.add(c);
    _emit();
  }

  @override
  Future<void> update(ShoppingCategory c) async {
    rows[rows.indexWhere((r) => r.id == c.id)] = c;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) throw StateError('disk full');
    deleted.add(id);
    rows.removeWhere((r) => r.id == id);
    _emit();
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    await reorderGate?.future;
    if (failWrites) throw StateError('disk full');
    for (var i = 0; i < orderedIds.length; i++) {
      final idx = rows.indexWhere((r) => r.id == orderedIds[i]);
      rows[idx] = rows[idx].copyWith(sortOrder: i);
    }
    _emit();
  }
}

class _NoApi implements ShoppingApi {
  _NoApi([this.mirror]);
  /// sync() vẫn gọi list() — trả đúng dữ liệu trên máy để reconcile không xoá.
  final ShoppingDao? mirror;

  @override
  Future<List<ShoppingItem>> list(String householdId) async => mirror?.getAll(householdId) ?? <ShoppingItem>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _OfflineConn extends ConnectivityService {
  @override
  Future<bool> isOnline() async => false;
  @override
  Stream<void> get onConnectivityRestored => const Stream<void>.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  group('ShoppingCategoryDao (Drift thật)', () {
    late AppDatabase db;
    late ShoppingCategoryDao dao;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = ShoppingCategoryDao(db);
    });
    tearDown(() => db.close());

    test('round-trip insert/watch/update/delete, chỉ household của mình, theo sortOrder', () async {
      await dao.insert(cat('b', 'Thịt', order: 1));
      await dao.insert(cat('a', 'Rau', order: 0));
      await dao.insert(ShoppingCategory(id: 'x', householdId: 'h2', name: 'Khác', colorHex: '#8E8E93', sortOrder: 0, createdAt: DateTime.utc(2026)));
      expect((await dao.watchAll('h1').first).map((c) => c.name), <String>['Rau', 'Thịt']);
      await dao.update(cat('a', 'Rau củ', color: '#4285F4'));
      final first = (await dao.watchAll('h1').first).first;
      expect((first.name, first.colorHex), ('Rau củ', '#4285F4'));
      await dao.delete('b');
      await dao.delete('khong-co'); // idempotent
      expect((await dao.watchAll('h1').first).map((c) => c.id), <String>['a']);
    });

    test('reorder: ghi lại sortOrder đủ danh sách, ≥3 phần tử, kéo xuống rồi kéo lên', () async {
      for (final (i, n) in <String>['A', 'B', 'C', 'D'].indexed) {
        await dao.insert(cat(n, n, order: i));
      }
      Future<List<String>> names() async => (await dao.watchAll('h1').first).map((c) => c.name).toList();
      await dao.reorder(reorderedIds(await names(), 0, 2)); // A xuống vị trí 2
      expect(await names(), <String>['B', 'C', 'A', 'D']);
      await dao.reorder(reorderedIds(await names(), 3, 0)); // D lên đầu
      expect(await names(), <String>['D', 'B', 'C', 'A']);
    });

    test('existsByName không phân biệt hoa/thường + bỏ qua chính nó khi sửa', () async {
      await dao.insert(cat('a', 'Rau Củ'));
      expect(await dao.existsByName('h1', '  rau củ '), isTrue);
      expect(await dao.existsByName('h1', 'rau củ', exceptId: 'a'), isFalse);
      expect(await dao.existsByName('h2', 'rau củ'), isFalse);
    });

    test('migration v6 → v7: tạo bảng shopping_categories, dữ liệu cũ còn', () async {
      final old = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
        raw.execute('''
          CREATE TABLE shopping_list_items (
            id TEXT NOT NULL PRIMARY KEY, household_id TEXT NOT NULL, shopping_list_id TEXT,
            name TEXT NOT NULL, quantity REAL NOT NULL, unit TEXT NOT NULL,
            display_quantity REAL NOT NULL, display_unit TEXT NOT NULL, category TEXT,
            status TEXT NOT NULL, source TEXT NOT NULL, version INTEGER NOT NULL,
            created_by TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'SYNCED', price REAL, assigned_to TEXT
          )''');
        raw.execute(
            "INSERT INTO shopping_list_items VALUES ('old','h1',NULL,'Cũ',1,'kg',1,'kg','Rau','PENDING','MANUAL',1,NULL,'2026-10-01T00:00:00Z','2026-10-01T00:00:00Z','SYNCED',NULL,NULL)");
        raw.userVersion = 6;
      }));
      addTearDown(old.close);
      expect((await ShoppingDao(old).getById('old'))!.category, 'Rau');
      final catDao = ShoppingCategoryDao(old);
      await catDao.insert(cat('a', 'Rau'));
      expect((await catDao.watchAll('h1').first).single.name, 'Rau');
    });
  });

  group('CategoryStore', () {
    late AppDatabase db;
    late _MemDao dao;
    late CategoryStore store;
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = _MemDao(db, <ShoppingCategory>[cat('a', 'Rau Củ')]);
      store = CategoryStore(dao, session());
      await store.loadCategories();
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      store.dispose();
      await db.close();
    });

    test('add: rỗng / >100 ký tự / trùng tên (hoa-thường) → báo lỗi, KHÔNG ghi', () async {
      expect(await store.addCategory(name: '   ', colorHex: '#34A853'), isFalse);
      expect(store.error, CategoryError.empty);
      expect(await store.addCategory(name: 'x' * 101, colorHex: '#34A853'), isFalse);
      expect(store.error, CategoryError.tooLong);
      expect(await store.addCategory(name: ' rau củ ', colorHex: '#34A853'), isFalse);
      expect(store.error, CategoryError.duplicate);
      expect(dao.rows, hasLength(1));
    });

    test('add hợp lệ → trim tên, sortOrder cuối, xoá lỗi cũ', () async {
      await store.addCategory(name: '', colorHex: '#34A853');
      expect(await store.addCategory(name: '  Thịt cá ', colorHex: '#E5484D'), isTrue);
      expect(store.error, isNull);
      final added = dao.rows.last;
      expect((added.name, added.colorHex, added.sortOrder), ('Thịt cá', '#E5484D', 1));
    });

    test('update: đổi màu cùng tên (của chính nó) OK; trùng tên category khác → lỗi', () async {
      await store.addCategory(name: 'Thịt', colorHex: '#E5484D');
      await Future<void>.delayed(Duration.zero);
      expect(await store.updateCategory('a', name: 'RAU CỦ', colorHex: '#4285F4'), isTrue);
      final thit = dao.rows.firstWhere((c) => c.name == 'Thịt');
      expect(await store.updateCategory(thit.id, name: 'rau củ', colorHex: '#4285F4'), isFalse);
      expect(store.error, CategoryError.duplicate);
    });

    test('ghi Drift lỗi (disk full) → saveFailed, không crash', () async {
      dao.failWrites = true;
      expect(await store.addCategory(name: 'Mới', colorHex: '#34A853'), isFalse);
      expect(store.error, CategoryError.saveFailed);
    });

    test('xoá lỗi ghi → trả ĐÚNG snapshot cũ (cả thứ tự) + saveFailed', () async {
      await store.addCategory(name: 'Thịt', colorHex: '#E5484D');
      await Future<void>.delayed(Duration.zero);
      final before = store.categories.map((c) => c.id).toList();
      dao.failWrites = true;
      expect(await store.deleteCategory('a'), isFalse);
      expect(store.categories.map((c) => c.id), before);
      expect(store.error, CategoryError.saveFailed);
    });

    test('sắp xếp: list đổi NGAY (không chờ Drift); lỗi ghi → về snapshot cũ', () async {
      await store.addCategory(name: 'Thịt', colorHex: '#E5484D');
      await Future<void>.delayed(Duration.zero);
      final before = store.categories.map((c) => c.id).toList();
      final reversed = before.reversed.toList();
      dao
        ..reorderGate = Completer<void>()
        ..failWrites = true;
      final pending = store.reorderCategories(reversed);
      expect(store.categories.map((c) => c.id), reversed);
      dao.reorderGate!.complete();
      expect(await pending, isFalse);
      expect(store.categories.map((c) => c.id), before);
    });

    test('stream Drift lỗi → loadFailed (không loading mãi); thử lại (force) hết lỗi', () async {
      final s = CategoryStore(dao..failStream = true, session());
      await s.loadCategories();
      await Future<void>.delayed(Duration.zero);
      expect((s.isLoading, s.loadFailed), (false, true));
      dao.failStream = false;
      await s.loadCategories(force: true);
      await Future<void>.delayed(Duration.zero);
      expect((s.isLoading, s.loadFailed), (false, false));
      expect(s.categories, isNotEmpty);
      s.dispose();
    });

    test('nạp lại cùng household (mở màn quản lý) → KHÔNG nháy loading', () async {
      expect(store.isLoading, isFalse);
      await store.loadCategories();
      expect(store.isLoading, isFalse);
    });

    test('householdId null → không loading mãi, danh sách rỗng', () async {
      final s = CategoryStore(dao, session(withHousehold: false));
      await s.loadCategories();
      expect(s.isLoading, isFalse);
      expect(s.categories, isEmpty);
    });
  });

  test('reorderedIds: kéo xuống và kéo lên (chỉ số sau khi nhấc, như onReorderItem)', () {
    expect(reorderedIds(<String>['a', 'b', 'c'], 0, 2), <String>['b', 'c', 'a']);
    expect(reorderedIds(<String>['a', 'b', 'c'], 2, 0), <String>['c', 'a', 'b']);
    expect(reorderedIds(<String>['a'], 0, 0), <String>['a']);
  });

  test('categorySuggestions: local (màu) trước, rồi đã dùng (xám), rồi mặc định; không trùng hoa/thường', () {
    final s = categorySuggestions(
      local: <ShoppingCategory>[cat('a', 'Thịt cá', color: '#E5484D')],
      used: <String?>['Rau củ', null, 'thịt cá', '  '],
      defaults: <String>['Rau củ', 'Gia vị'],
    );
    expect(s.map((e) => e.name), <String>['Thịt cá', 'Rau củ', 'Gia vị']);
    expect(s.first.colorHex, '#E5484D');
    expect(s[1].colorHex, categoryDefaultColorHex);
  });

  group('ShoppingShareTextBuilder (pure)', () {
    const labels = ShoppingShareLabels(
      header: 'HEAD',
      progress: _progress,
      uncategorized: 'Chưa phân loại',
      footer: 'FOOT',
    );
    String build(List<ShoppingItem> all, {Map<String, String> names = const <String, String>{}}) =>
        ShoppingShareTextBuilder.build(
          groups: ShoppingShareTextBuilder.groupAllForShare(all),
          checkedCount: all.where((i) => i.status == ShoppingItemStatus.completed).length,
          totalCount: all.length,
          labels: labels,
          memberNamesById: names,
        );

    test('nhiều category, null cuối, chưa mua trước, ☑/☐, số lượng nguyên/thập phân', () {
      final text = build(<ShoppingItem>[
        item('1', 'Muối', unit: 'g', qty: 500),
        item('2', 'Cà chua', category: 'Rau', status: ShoppingItemStatus.completed, qty: 1.5),
        item('3', 'Bắp cải', category: 'Rau'),
        item('4', 'Bò', category: 'Thịt'),
      ]);
      expect(
        text,
        'HEAD\n1/4\n\n'
        '📌 Rau\n☐ Bắp cải — 1kg\n☑ Cà chua — 1.5kg\n\n'
        '📌 Thịt\n☐ Bò — 1kg\n\n'
        '📌 Chưa phân loại\n☐ Muối — 500g\n\n'
        'FOOT',
      );
    });

    test('danh sách rỗng vẫn ra chuỗi hợp lệ', () {
      expect(build(<ShoppingItem>[]), 'HEAD\n0/0\n\nFOOT');
    });

    test('Guard #14: hậu tố — @Tên CHỈ khi giải được tên; UUID lạ KHÔNG lọt ra', () {
      const uuid = '8d4e6a10-0000-4000-8000-00000000dead';
      final text = build(
        <ShoppingItem>[item('1', 'Bò', assignedTo: 'u1'), item('2', 'Gà', assignedTo: uuid)],
        names: <String, String>{'u1': 'Mẹ'},
      );
      expect(text, contains('☐ Bò — 1kg — @Mẹ\n'));
      expect(text, contains('☐ Gà — 1kg\n'));
      expect(text.contains(uuid), isFalse);
    });

    test('Guard #13: KHÔNG có giá trong share text', () {
      final text = build(<ShoppingItem>[item('1', 'Bò', status: ShoppingItemStatus.completed, price: 55000)]);
      expect(text.contains('55'), isFalse);
      expect(text.contains('đ'), isFalse);
    });
  });

  group('Widget', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() async {
      Get.reset();
      await db.close();
    });

    Future<CategoryStore> putStore(WidgetTester tester, List<ShoppingCategory> seed) async {
      final store = CategoryStore(_MemDao(db, seed), session());
      Get.put<CategoryStore>(store);
      await store.loadCategories();
      await tester.pump();
      return store;
    }

    testWidgets('CategoryManagerScene: rỗng → empty + ghi chú chỉ trên thiết bị này', (tester) async {
      await putStore(tester, <ShoppingCategory>[]);
      await tester.pumpAppWidget(const CategoryManagerScene(), wrapInScaffold: false);
      await tester.pump();
      expect(find.textContaining('chỉ lưu trên thiết bị này'), findsOneWidget);
    });

    testWidgets('CategoryManagerScene: list theo thứ tự; vuốt xoá → huỷ giữ nguyên, xác nhận thì xoá', (tester) async {
      final store = await putStore(tester, <ShoppingCategory>[cat('a', 'Rau', order: 0), cat('b', 'Thịt', order: 1)]);
      await tester.pumpAppWidget(const CategoryManagerScene(), wrapInScaffold: false);
      await tester.pump();
      expect(tester.getTopLeft(find.text('Rau')).dy, lessThan(tester.getTopLeft(find.text('Thịt')).dy));

      await tester.drag(find.text('Rau'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(find.text('Rau'), findsOneWidget);

      await tester.drag(find.text('Rau'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('category-delete-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Rau'), findsNothing);
      expect(store.categories.map((c) => c.id), <String>['b']);
    });

    testWidgets('Fix LOW-1: mở dialog mới → lỗi validate lần trước KHÔNG còn hiện', (tester) async {
      final store = await putStore(tester, <ShoppingCategory>[cat('a', 'Rau')]);
      await tester.pumpAppWidget(const CategoryManagerScene(), wrapInScaffold: false);
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'rau');
      await tester.tap(find.byKey(const ValueKey<String>('category-save')));
      await tester.pumpAndSettle();
      expect(find.text('Đã có danh mục trùng tên'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(store.error, isNull);
      expect(find.text('Đã có danh mục trùng tên'), findsNothing);
    });

    testWidgets('dialog thêm: nhập tên + chọn màu → lưu đúng màu, đóng dialog', (tester) async {
      final store = await putStore(tester, <ShoppingCategory>[]);
      await tester.pumpAppWidget(const CategoryManagerScene(), wrapInScaffold: false);
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Gia vị');
      await tester.tap(find.byKey(const ValueKey<String>('category-color-#7C3AED')));
      await tester.tap(find.byKey(const ValueKey<String>('category-save')));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryEditDialog), findsNothing);
      expect((store.categories.single.name, store.categories.single.colorHex), ('Gia vị', '#7C3AED'));
    });

    group('ShareExportSheet', () {
      late ShoppingDao shoppingDao;
      late ShoppingStore shopping;
      String? copied;

      setUp(() {
        copied = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
            return null;
          },
        );
        shoppingDao = ShoppingDao(db);
        shopping = ShoppingStore(dao: shoppingDao, api: _NoApi(shoppingDao), connectivity: _OfflineConn(), session: session());
      });
      tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      Future<void> pumpSheet(WidgetTester tester, List<ShoppingItem> rows) async {
        await tester.runAsync(() async {
          for (final r in rows) {
            await shoppingDao.upsert(r);
          }
          await shopping.init();
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAppWidget(ShareExportSheet(store: shopping));
        await tester.pump();
      }

      testWidgets('không có món → "Sao chép" disabled + gợi ý; "Chia sẻ link" luôn disabled', (tester) async {
        await pumpSheet(tester, <ShoppingItem>[]);
        expect(tester.widget<ListTile>(find.byKey(const ValueKey<String>('share-copy-text'))).enabled, isFalse);
        expect(find.text('Chưa có mặt hàng nào để chia sẻ'), findsOneWidget);
        expect(tester.widget<ListTile>(find.byKey(const ValueKey<String>('share-link'))).enabled, isFalse);
      });

      testWidgets('FamilyStore CHƯA đăng ký → không crash; copy ra text TOÀN BỘ món, không hậu tố', (tester) async {
        await pumpSheet(tester, <ShoppingItem>[
          item('1', 'Bò', category: 'Thịt', assignedTo: 'me'),
          item('2', 'Rau muống', category: 'Rau', status: ShoppingItemStatus.completed),
        ]);
        await tester.tap(find.byKey(const ValueKey<String>('share-copy-text')));
        await tester.pump();
        expect(copied, isNotNull);
        expect(copied, contains('Đã mua: 1/2'));
        expect(copied, contains('☐ Bò — 1kg\n'));
        expect(copied, contains('☑ Rau muống — 1kg\n'));
        expect(copied!.contains('@'), isFalse);
        expect(shoppingCategoryStore(), isNull);
      });
    });

    testWidgets('sheet thêm món: chip = category local (đúng thứ tự) + đã dùng; chọn chip → món mang category đó', (tester) async {
      final shoppingDao = ShoppingDao(db);
      final s = session();
      Get
        ..put<SessionStore>(s)
        ..put<ConnectivityService>(_OfflineConn());
      final shopping = ShoppingStore(dao: shoppingDao, api: _NoApi(shoppingDao), connectivity: _OfflineConn(), session: s);
      Get.put<ShoppingStore>(shopping);
      await putStore(tester, <ShoppingCategory>[cat('b', 'Đồ nhà', order: 1), cat('a', 'Bánh', order: 0)]);
      await tester.runAsync(() => shoppingDao.upsert(item('old', 'Cũ', category: 'Hải sản')));
      await tester.pumpAppWidget(const ShoppingListScene(), wrapInScaffold: false);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      double x(String name) => tester.getTopLeft(find.byKey(ValueKey<String>('add-category-$name'))).dx;
      expect(x('Bánh'), lessThan(x('Đồ nhà')));
      expect(x('Đồ nhà'), lessThan(x('Hải sản')));

      await tester.enterText(find.byType(TextField).first, 'Bánh mì');
      await tester.tap(find.byKey(const ValueKey<String>('add-category-Bánh')));
      await tester.pump();
      await tester.tap(find.text('Thêm vào danh sách'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      final added = (await tester.runAsync(() => shoppingDao.getAll('h1')))!.firstWhere((i) => i.name == 'Bánh mì');
      expect(added.category, 'Bánh');
    });

    test('DI (Fix CRITICAL-1): ShoppingListBinding đăng ký CategoryStore — sheet thêm món không crash', () async {
      Get
        ..put<AppDatabase>(db)
        ..put<SessionStore>(session())
        ..put<ConnectivityService>(_OfflineConn())
        ..put<ShoppingApi>(_NoApi());
      ShoppingListBinding().dependencies();
      expect(Get.isRegistered<CategoryStore>(), isTrue);
      expect(shoppingCategoryStore(), isA<CategoryStore>());
    });
  });
}

String _progress(int checked, int total) => '$checked/$total';
