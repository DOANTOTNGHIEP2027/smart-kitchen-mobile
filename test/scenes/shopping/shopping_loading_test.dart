import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/scenes/shopping_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

class _Dao extends ShoppingDao {
  _Dao(super.db);
  bool failWatch = false;
  bool failRead = false;
  bool failQueue = false;
  int watchCalls = 0;

  @override
  Stream<List<ShoppingItem>> watchAll(String householdId) {
    watchCalls++;
    return failWatch
        ? Stream<List<ShoppingItem>>.error(StateError('cache read failed'))
        : super.watchAll(householdId);
  }

  @override
  Future<List<ShoppingItem>> getAll(String householdId) async {
    if (failRead) throw StateError('cache read failed');
    return super.getAll(householdId);
  }

  @override
  Future<List<ShoppingSyncQueueEntry>> queue(String householdId) async {
    if (failQueue) throw StateError('queue read failed');
    return super.queue(householdId);
  }
}

class _Api implements ShoppingApi {
  @override
  Future<ShoppingItem> update(String id, int version, String householdId, {required String name, required double quantity, required String unit}) => throw UnimplementedError();
  @override
  Future<void> delete(String id, int version) => throw UnimplementedError();
  List<ShoppingItem> serverItems = [];
  @override
  Future<List<ShoppingItem>> list(String householdId) async => serverItems;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Connectivity extends ConnectivityService {
  @override
  Future<bool> isOnline() async => true;
  @override
  Stream<void> get onConnectivityRestored => const Stream<void>.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  late AppDatabase db;
  late _Dao dao;
  late _Api api;
  late SessionStore session;
  late ShoppingStore store;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = _Dao(db);
    api = _Api();
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()))
      ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
      ..applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    store = ShoppingStore(
      dao: dao,
      api: api,
      connectivity: _Connectivity(),
      session: session,
    );
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await store.dispose();
    Get.reset();
    await db.close();
  });

  test('lỗi stream SQLite kết thúc loading, không thành unhandled exception',
      () async {
    dao.failWatch = true;
    await store.init();
    await Future<void>.delayed(Duration.zero);
    expect(store.isLoading, isFalse);
    expect(store.loadError, isNotNull);
  });

  for (final failQueue in [false, true]) {
    test('lỗi đọc ${failQueue ? 'queue' : 'cache'} trong sync được xử lý',
        () async {
      dao.failQueue = failQueue;
      dao.failRead = !failQueue;
      await expectLater(store.sync(), completes);
      expect(store.isLoading, isFalse);
      expect(store.loadError, isNotNull);
    });
  }

  testWidgets('cache lỗi hiện Thử lại; retry đọc lại stream và hiện món từ API',
      (tester) async {
    dao.failWatch = true;
    dao.failRead = true;
    api.serverItems = [
      ShoppingItem(
        id: 'server-item',
        householdId: 'h1',
        name: 'Món kiểm tra',
        quantity: 1,
        unit: 'kg',
        displayQuantity: 1,
        displayUnit: 'kg',
        status: ShoppingItemStatus.pending,
        source: ShoppingItemSource.manual,
        version: 1,
        createdAt: DateTime.utc(2026, 11, 28),
        updatedAt: DateTime.utc(2026, 11, 28),
      ),
    ];
    Get.put<SessionStore>(session);
    Get.put<ShoppingStore>(store);
    Get.put<ConnectivityService>(_Connectivity());
    await tester.pumpAppWidget(const ShoppingListScene(),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.takeException(), isNull);

    dao.failWatch = false;
    dao.failRead = false;
    await tester.runAsync(() async {
      await tester.tap(find.text('Thử lại'));
      await store.sync();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(dao.watchCalls, 2);
    expect(find.byType(AppErrorView), findsNothing);
    expect(store.items.single.id, 'server-item');
    expect(find.text('Món kiểm tra'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
