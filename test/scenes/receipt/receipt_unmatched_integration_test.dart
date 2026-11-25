import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/sync_status.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_image_service.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/domain/ocr_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_form_store.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/data/receipt_api.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_matched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_unmatched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/stores/receipt_scan_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import '../inventory/fake_connectivity_service.dart';
import '../inventory/fake_inventory_api.dart';

/// §16 "Store — unmatched": `confirmUnmatchedItem` với `InventoryFormStore`
/// THẬT + `InventoryDao` Drift in-memory → bảng tồn kho có đúng 1 row, kể cả
/// double-tap và Thử lại (Guard 12).

class _OneResultApi implements ReceiptApi {
  @override
  Future<ReceiptScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
    CancelToken? cancelToken,
  }) async =>
      const ReceiptScanResult(
        meta: ReceiptScanMeta(scanId: 'scan-1', currency: 'VND'),
        matchedItems: <ReceiptMatchedItem>[],
        unmatchedItems: <ReceiptUnmatchedItem>[
          ReceiptUnmatchedItem(
            itemId: 'u-1',
            name: 'Sữa tươi',
            category: 'Sữa',
            quantity: 2,
            unit: 'cái',
            rawName: 'SUA TUOI',
            rawQuantity: 2,
            rawUnit: 'hop',
          ),
        ],
      );
}

class _Picker implements OcrImagePicker {
  @override
  Future<Uint8List?> pick(OcrImageSource source) async =>
      Uint8List.fromList(<int>[1]);
}

class _Compressor implements OcrImageCompressor {
  @override
  Future<Uint8List> compress(Uint8List bytes) async => bytes;
}

class _UnusedShoppingStore implements ShoppingStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Như server thật: mỗi lần create là 1 id mới — 2 lần ghi sẽ ra 2 row.
var _serverSeq = 0;

InventoryItemModel _serverItem(Map<String, dynamic> payload) =>
    InventoryItemModel(
      id: 'srv-${++_serverSeq}',
      householdId: 'h1',
      name: payload['name'] as String,
      category: payload['category'] as String?,
      quantity: (payload['quantity'] as num).toDouble(),
      unit: payload['unit'] as String,
      displayQuantity: (payload['quantity'] as num).toDouble(),
      displayUnit: payload['unit'] as String,
      version: 1,
      isLowStock: false,
      isExpiringSoon: false,
      createdBy: 'u1',
      createdAt: DateTime.utc(2026, 11, 25),
      updatedAt: DateTime.utc(2026, 11, 25),
      syncStatus: SyncStatus.synced,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  setUp(storageChannel.install);
  tearDown(storageChannel.uninstall);

  late AppDatabase db;
  late InventoryDao dao;
  late FakeInventoryApi inventoryApi;
  late FakeConnectivityService connectivity;
  late ReceiptScanStore store;

  setUp(() async {
    _serverSeq = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryDao(db);
    inventoryApi = FakeInventoryApi();
    connectivity = FakeConnectivityService(online: true);
    final session = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(
        Dio(BaseOptions(baseUrl: 'https://test.local'))
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          ),
      ),
    );
    session.currentUser = const UserSummary(id: 'u1', fullName: 'Tester');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    store = ReceiptScanStore(
      api: _OneResultApi(),
      imagePicker: _Picker(),
      imageCompressor: _Compressor(),
      shoppingStore: _UnusedShoppingStore(),
      // Như ReceiptScanBinding: mỗi lần thêm 1 InventoryFormStore mới.
      formStoreFactory: () => InventoryFormStore(
        mode: InventoryFormMode.create,
        dao: dao,
        api: inventoryApi,
        connectivity: connectivity,
        sessionStore: session,
      ),
    );
    await store.pickAndScan(OcrImageSource.gallery);
  });

  tearDown(() => db.close());

  Future<int> inventoryRowCount() async =>
      (await db.select(db.inventoryItems).get()).length;

  ReceiptConfirmStatus cardStatus() =>
      store.unmatchedItems.single.confirmStatus;

  test('double-tap khi create đang bay → đúng 1 row, create 1 lần', () async {
    final gate = Completer<void>();
    inventoryApi.onCreate = (payload) async {
      await gate.future;
      return _serverItem(payload);
    };

    final first = store.confirmUnmatchedItem('u-1');
    final second = store.confirmUnmatchedItem('u-1');
    gate.complete();

    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(await store.confirmUnmatchedItem('u-1'), isFalse); // sau confirmed
    expect(cardStatus(), ReceiptConfirmStatus.confirmed);
    expect(inventoryApi.createIdempotencyKeys, hasLength(1));
    expect(await inventoryRowCount(), 1);
    final row = await dao.getById('srv-1');
    expect(row?.name, 'Sữa tươi');
    expect(row?.syncStatus, SyncStatus.synced);
  });

  test('lỗi rồi Thử lại → vẫn đúng 1 row', () async {
    inventoryApi.onCreateError =
        BusinessException('ERR_VALIDATION_FAILED', 'bad');

    expect(await store.confirmUnmatchedItem('u-1'), isFalse);
    expect(cardStatus(), ReceiptConfirmStatus.failed);
    expect(await inventoryRowCount(), 0); // rollback xoá row tạm

    inventoryApi
      ..onCreateError = null
      ..onCreate = (payload) async => _serverItem(payload);
    expect(await store.confirmUnmatchedItem('u-1'), isTrue);
    expect(await store.confirmUnmatchedItem('u-1'), isFalse);

    expect(cardStatus(), ReceiptConfirmStatus.confirmed);
    expect(inventoryApi.createIdempotencyKeys, hasLength(2));
    expect(await inventoryRowCount(), 1);
  });

  test('offline → enqueue; bấm lại → vẫn 1 row, 1 thao tác trong queue',
      () async {
    connectivity.set(false);

    expect(await store.confirmUnmatchedItem('u-1'), isTrue);
    expect(await store.confirmUnmatchedItem('u-1'), isFalse);

    expect(inventoryApi.createIdempotencyKeys, isEmpty);
    expect(await inventoryRowCount(), 1);
    expect(await dao.queuedOperations('h1'), hasLength(1));
  });
}
