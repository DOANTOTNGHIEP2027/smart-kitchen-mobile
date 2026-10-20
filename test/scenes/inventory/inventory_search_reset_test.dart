import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/scenes/inventory_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';
import 'fake_connectivity_service.dart';
import 'fake_inventory_api.dart';

/// OD-33: store xoá ô tìm khi đổi household → ô nhập trên màn phải xoá theo,
/// không thì hiện chữ cũ trong khi danh sách không lọc.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  late AppDatabase db;
  late SessionStore session;
  late InventoryStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))))
      ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
      ..applyHouseholdContext(householdId: 'h1', role: 'OWNER');
    store = InventoryStore(
      dao: InventoryDao(db),
      api: FakeInventoryApi(),
      connectivity: FakeConnectivityService(online: false),
      sessionStore: session,
    );
    Get
      ..put<SessionStore>(session)
      ..put<InventoryStore>(store);
  });
  tearDown(() async {
    Get.reset();
    await store.dispose();
    await db.close();
  });

  testWidgets('gõ tìm → đổi household → ô tìm xoá theo store', (tester) async {
    // init ở zone thật (Drift) trước khi dựng — initState gọi lại là no-op.
    await tester.runAsync(() async {
      await store.init();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAppWidget(const InventoryListScene(), wrapInScaffold: false);
    await tester.pump();
    final field = find.byKey(const ValueKey<String>('inventory-search'));
    await tester.enterText(field, 'gạo');
    expect(store.searchQuery, 'gạo');

    await tester.runAsync(() async {
      session.applyHouseholdContext(householdId: 'h2', role: 'OWNER');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(store.searchQuery, '');
    expect(tester.widget<TextField>(field).controller!.text, '');
    await tester.pumpWidget(const SizedBox());
  });
}
