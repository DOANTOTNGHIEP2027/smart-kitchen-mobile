import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/app/app.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/data/notification/bg_files.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/inventory_catch_up.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import 'fake_connectivity_service.dart';
import 'fake_inventory_api.dart';

/// InventoryCatchUp — cờ file + ping port (inventory-management.md §20.3
/// Amendment #134 A8, Guard 18). Thay test `prefs.reload()` cũ.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late BgFiles files;
  late int syncCalls;
  Object? syncError;
  Completer<void>? holdSync;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sk_catchup_');
    files = BgFiles(baseDirectory: () async => dir);
    syncCalls = 0;
    syncError = null;
    holdSync = null;
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  InventoryCatchUpTarget target() => InventoryCatchUpTarget(
        sync: () async {
          syncCalls++;
          final hold = holdSync;
          if (hold != null) await hold.future;
          return syncError == null;
        },
      );

  test('cờ do ISOLATE KHÁC ghi ⇒ run() gọi syncFromServer rồi xoá cờ',
      () async {
    final path = dir.path;
    await Isolate.run(() async {
      await BgFiles(baseDirectory: () async => Directory(path))
          .markInventoryPendingSync();
    });
    final catchUp = InventoryCatchUp(files: files, target: target);

    await catchUp.run();

    expect(syncCalls, 1);
    expect(await files.hasInventoryPendingSync(), isFalse);
  });

  test('không có cờ ⇒ không sync', () async {
    await InventoryCatchUp(files: files, target: target).run();
    expect(syncCalls, 0);
  });

  test('syncError != null ⇒ GIỮ cờ cho lần sau', () async {
    await files.markInventoryPendingSync();
    syncError = NetworkException();

    await InventoryCatchUp(files: files, target: target).run();

    expect(syncCalls, 1);
    expect(await files.hasInventoryPendingSync(), isTrue);
  });

  test('store chưa đăng ký ⇒ giữ cờ, không ném', () async {
    await files.markInventoryPendingSync();

    await InventoryCatchUp(files: files, target: () => null).run();
    // Mặc định đọc GetX: không có InventoryStore ⇒ cũng giữ cờ.
    await InventoryCatchUp(files: files).run();

    expect(await files.hasInventoryPendingSync(), isTrue);
  });

  test('2 lần gọi chồng ⇒ đúng 1 sync', () async {
    await files.markInventoryPendingSync();
    holdSync = Completer<void>();
    final catchUp = InventoryCatchUp(files: files, target: target);

    final first = catchUp.run();
    final second = catchUp.run();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    holdSync!.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(syncCalls, 1);
  });

  test(
      'nền ghi cờ MỚI + ping trong lúc sync đang chạy ⇒ không xoá cờ mới, '
      'chạy thêm 1 lượt (review M1)', () async {
    await files.markInventoryPendingSync();
    final gate = Completer<void>();
    holdSync = gate;
    final catchUp = InventoryCatchUp(files: files, target: target);

    final first = catchUp.run();
    for (var i = 0; i < 100 && syncCalls == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(syncCalls, 1);
    // Bấm món B: isolate nền ghi lại cờ rồi ping — ping gộp vào lượt đang chạy.
    await files.markInventoryPendingSync();
    final pinged = catchUp.run();
    holdSync = null; // lượt sau không bị giữ
    gate.complete();
    await Future.wait(<Future<void>>[first, pinged]);

    expect(syncCalls, 2, reason: 'thay đổi của B phải được sync');
    expect(await files.hasInventoryPendingSync(), isFalse);
  });

  test('ping port sk.inventory.catchup ⇒ chạy catch-up', () async {
    await files.markInventoryPendingSync();
    final catchUp = InventoryCatchUp(files: files, target: target)..listen();
    addTearDown(catchUp.dispose);

    pingInventoryCatchUp();
    for (var i = 0; i < 50 && syncCalls == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(syncCalls, 1);
  });

  group('InventoryCatchUpTarget.fromStore — chỉ xoá cờ khi sync THẬT (L1)', () {
    final storageChannel = FakeSecureStorageChannel();
    late AppDatabase db;
    late FakeInventoryApi api;
    late SessionStore session;
    late InventoryStore store;
    late int listCalls;

    setUp(() {
      storageChannel.install();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      api = FakeInventoryApi();
      listCalls = 0;
      api.onList = ({int page = 0, int size = 100}) async {
        listCalls++;
        return const InventoryListPage(
            items: <InventoryItemModel>[],
            page: 0,
            size: 100,
            totalElements: 0,
            totalPages: 1);
      };
      session = SessionStore(
        TokenStorage(),
        AuthRefreshUseCase(Dio()
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          )),
      );
      store = InventoryStore(
        dao: InventoryDao(db),
        api: api,
        connectivity: FakeConnectivityService(online: true),
        sessionStore: session,
      );
    });

    tearDown(() async {
      await store.dispose();
      await db.close();
      storageChannel.uninstall();
    });

    Future<void> runWithStore() => InventoryCatchUp(
          files: files,
          target: () => InventoryCatchUpTarget.fromStore(store),
        ).run();

    test('chưa có household ⇒ syncFromServer trả sớm ⇒ GIỮ cờ', () async {
      await files.markInventoryPendingSync();

      await runWithStore();

      expect(listCalls, 0);
      expect(await files.hasInventoryPendingSync(), isTrue);
    });

    test('household đổi giữa chừng (epoch cũ, break) ⇒ GIỮ cờ', () async {
      session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
      await files.markInventoryPendingSync();
      api.onList = ({int page = 0, int size = 100}) async {
        listCalls++;
        store.unbindHousehold(); // epoch++ như khi household đổi
        return const InventoryListPage(
            items: <InventoryItemModel>[],
            page: 0,
            size: 100,
            totalElements: 0,
            totalPages: 1);
      };

      await runWithStore();

      expect(listCalls, 1);
      expect(store.syncError, isNull, reason: 'nhánh break không đặt lỗi');
      expect(await files.hasInventoryPendingSync(), isTrue);
    });

    test('có household, sync xong ⇒ xoá cờ', () async {
      session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
      await files.markInventoryPendingSync();

      await runWithStore();

      expect(listCalls, 1);
      expect(await files.hasInventoryPendingSync(), isFalse);
    });
  });

  group('AppLifecycleState.resumed (app.dart)', () {
    final storageChannel = FakeSecureStorageChannel();

    setUp(() {
      storageChannel.install();
      final session = SessionStore(
        TokenStorage(),
        AuthRefreshUseCase(Dio()
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          )),
      );
      Get.put<SessionStore>(session, permanent: true);
      Get.put<AuthStore>(
        AuthStore(
          AuthApiImpl(DioClient.build(tokenStorage: TokenStorage())),
          session,
          const UnavailableGoogleAuthGateway(),
        ),
        permanent: true,
      );
    });

    tearDown(() {
      storageChannel.uninstall();
      Get.reset();
    });

    testWidgets('resumed + có cờ ⇒ gọi syncFromServer', (tester) async {
      await tester.runAsync(files.markInventoryPendingSync);
      Get.put<InventoryCatchUp>(
        InventoryCatchUp(files: files, target: target),
        permanent: true,
      );
      await Get.find<SessionStore>().clear();
      await tester.pumpWidget(const SmartKitchenApp());
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        for (var i = 0; i < 50 && syncCalls == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });

      expect(syncCalls, 1);
    });
  });
}
