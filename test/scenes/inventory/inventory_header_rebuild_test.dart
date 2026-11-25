import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/sync_status.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/scenes/inventory_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';
import 'fake_connectivity_service.dart';
import 'fake_inventory_api.dart';

/// #93 F7 (app-performance-audit §7.5): header Inventory tách 3 phần —
/// đổi bộ lọc chỉ dựng lại chip, không dựng lại banner thống kê hay ô tìm.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  late AppDatabase db;
  late InventoryDao dao;
  late SessionStore session;
  late InventoryStore store;

  InventoryItemModel item(String id, String name, String category,
          {bool expiring = false, bool low = false}) =>
      InventoryItemModel(
        id: id,
        householdId: 'h1',
        name: name,
        category: category,
        quantity: 1,
        unit: 'UNIT',
        displayQuantity: 1,
        displayUnit: 'cái',
        lowStockThreshold: null,
        expiryDate: null,
        note: null,
        version: 1,
        isLowStock: low,
        isExpiringSoon: expiring,
        createdBy: 'me',
        createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
        updatedAt: DateTime.parse('2026-09-15T10:00:00Z'),
        syncStatus: SyncStatus.synced,
      );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryDao(db);
    session = SessionStore(TokenStorage(),
        AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))))
      ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
      ..applyHouseholdContext(householdId: 'h1', role: 'OWNER');
    store = InventoryStore(
      dao: dao,
      api: FakeInventoryApi(),
      connectivity: FakeConnectivityService(online: false),
      sessionStore: session,
    );
    Get
      ..put<SessionStore>(session)
      ..put<InventoryStore>(store);
  });
  tearDown(() async {
    widgets.debugOnRebuildDirtyWidget = null;
    Get.reset();
    await store.dispose();
    await db.close();
  });

  testWidgets('đổi category → chip dựng lại; banner + ô tìm KHÔNG dựng lại',
      (tester) async {
    await tester.runAsync(() async {
      await dao.upsertItem(item('a', 'Gạo', 'Khô', expiring: true));
      await dao.upsertItem(item('b', 'Sữa', 'Lạnh', low: true));
      await store.init();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAppWidget(const InventoryListScene(),
        wrapInScaffold: false);
    await tester.pump();
    expect(store.items, hasLength(2));

    var statBuilds = 0;
    var pillBuilds = 0;
    var searchBuilds = 0;
    widgets.debugOnRebuildDirtyWidget = (element, _) {
      final type = element.widget.runtimeType.toString();
      if (type == '_StatItem') statBuilds++;
      if (type == '_CategoryPill') pillBuilds++;
      final key = element.widget.key;
      if (element.widget is TextField &&
          key == const ValueKey<String>('inventory-search')) {
        searchBuilds++;
      }
    };

    store.setCategory('Khô');
    await tester.pump();

    expect(pillBuilds, greaterThan(0), reason: 'chip phải phản ánh lựa chọn');
    expect(statBuilds, 0, reason: 'banner không phụ thuộc bộ lọc');
    expect(searchBuilds, 0, reason: 'ô tìm nằm ngoài mọi Observer');
    expect(store.filteredItems.map((i) => i.id), <String>['a']);

    await tester.pumpWidget(const SizedBox());
  });
}
