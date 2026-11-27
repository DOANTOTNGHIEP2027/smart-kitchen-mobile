import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_batch_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_image_service.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/domain/ocr_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/domain/ocr_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/stores/ocr_store.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/scenes/camera_scan_scene.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/scenes/ocr_result_scene.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_form_store.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/inventory_routes.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';

import '../../helpers/pump_app.dart';

class _FakeOcrApi implements OcrApi {
  final List<String> keys = <String>[];
  final List<Object> outcomes = <Object>[];

  @override
  Future<OcrScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    final outcome = outcomes.removeAt(0);
    if (outcome is OcrScanResult) return outcome;
    throw outcome;
  }
}

class _FakePicker implements OcrImagePicker {
  Uint8List? bytes = Uint8List.fromList(<int>[1, 2, 3]);

  @override
  Future<Uint8List?> pick(OcrImageSource source) async => bytes;
}

class _FakeCompressor implements OcrImageCompressor {
  @override
  Future<Uint8List> compress(Uint8List bytes) async => bytes;
}

class _MockInventoryFormStore extends Mock implements InventoryFormStore {}

class _FakeBatchApi implements InventoryBatchApi {
  final List<List<Map<String, dynamic>>> payloads = <List<Map<String, dynamic>>>[];
  Object? failure;

  @override
  Future<List<InventoryItemModel>> batchCreate(
    List<Map<String, dynamic>> items, {
    required String idempotencyKey,
  }) async {
    payloads.add(items);
    if (failure != null) throw failure!;
    return const <InventoryItemModel>[];
  }
}

const _validItem = OcrItem(
  itemId: 'item-1',
  name: 'Cà chua',
  category: 'Rau củ',
  quantity: 3,
  unit: 'quả',
  needsManualReview: false,
  rawQuantity: 3,
  rawUnit: 'quả',
  duplicate: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeOcrApi api;
  late _FakePicker picker;
  late _MockInventoryFormStore formStore;
  late OcrStore store;

  setUp(() {
    api = _FakeOcrApi();
    picker = _FakePicker();
    formStore = _MockInventoryFormStore();
    store = OcrStore(
      api: api,
      imagePicker: picker,
      imageCompressor: _FakeCompressor(),
      formStoreFactory: () => formStore,
      idempotencyKeyGenerator: () => 'fixed-key',
    );
  });

  tearDown(() async => Get.reset());

  test('scan success moves to review and keeps proposed items', () async {
    api.outcomes.add(
      const OcrScanResult(scanId: 'scan-1', items: <OcrItem>[_validItem]),
    );

    expect(await store.pickAndScan(OcrImageSource.gallery), isTrue);

    expect(store.status, OcrStatus.reviewing);
    expect(store.items.single.name, 'Cà chua');
    expect(api.keys, <String>['fixed-key']);
  });

  test('retry reuses the same idempotency key', () async {
    api.outcomes
      ..add(NetworkException())
      ..add(const OcrScanResult(scanId: 'scan-1', items: <OcrItem>[]));

    expect(await store.pickAndScan(OcrImageSource.camera), isFalse);
    expect(store.canRetryScan, isTrue);
    expect(await store.retryScan(), isTrue);

    expect(api.keys, <String>['fixed-key', 'fixed-key']);
    expect(store.status, OcrStatus.reviewing);
  });

  test('manual review becomes confirmable after quantity and unit are edited',
      () async {
    api.outcomes.add(
      const OcrScanResult(
        scanId: 'scan-1',
        items: <OcrItem>[
          OcrItem(
            itemId: 'manual',
            name: 'Sữa tươi',
            quantity: null,
            unit: null,
            needsManualReview: true,
            rawQuantity: 1,
            rawUnit: 'hộp',
            duplicate: false,
          ),
        ],
      ),
    );
    await store.pickAndScan(OcrImageSource.gallery);

    store.editItem('manual', quantity: 1.0, unit: 'cái');

    expect(store.items.single.isValidForConfirm, isTrue);
    expect(store.canConfirmAll, isTrue);
  });

  test('confirm delegates creation to InventoryFormStore and reaches done',
      () async {
    api.outcomes.add(
      const OcrScanResult(scanId: 'scan-1', items: <OcrItem>[_validItem]),
    );
    when(
      () => formStore.save(
        name: any(named: 'name'),
        category: any(named: 'category'),
        quantity: any(named: 'quantity'),
        unit: any(named: 'unit'),
        lowStockThreshold: any(named: 'lowStockThreshold'),
        expiryDate: any(named: 'expiryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => true);
    await store.pickAndScan(OcrImageSource.gallery);

    await store.confirmAll();

    expect(store.status, OcrStatus.done);
    expect(store.items.single.confirmStatus, OcrConfirmStatus.confirmed);
    verify(
      () => formStore.save(
        name: 'Cà chua',
        category: 'Rau củ',
        quantity: 3,
        unit: 'quả',
        lowStockThreshold: null,
        expiryDate: null,
        note: null,
      ),
    ).called(1);
  });

  testWidgets('camera state follows the OCR mockup entry actions',
      (tester) async {
    Get.put<OcrStore>(store);

    await tester.pumpAppWidget(
      const CameraScanScene(),
      wrapInScaffold: false,
    );

    expect(find.text('Quét ảnh thêm vào kho'), findsOneWidget);
    expect(find.text('Từng món'), findsOneWidget);
    expect(find.text('Hoá đơn / tủ lạnh'), findsOneWidget);
    expect(find.text('Chụp ảnh'), findsOneWidget);
    expect(find.text('Chọn từ thư viện'), findsOneWidget);
  });

  for (final standalone in [false, true]) {
    testWidgets('confirm all giữ màn gốc (standalone=$standalone)',
        (tester) async {
      api.outcomes
          .add(const OcrScanResult(scanId: 'scan-1', items: [_validItem]));
      when(() => formStore.save(
          name: any(named: 'name'),
          category: any(named: 'category'),
          quantity: any(named: 'quantity'),
          unit: any(named: 'unit'),
          lowStockThreshold: any(named: 'lowStockThreshold'),
          expiryDate: any(named: 'expiryDate'),
          note: any(named: 'note'))).thenAnswer((_) async => true);
      await store.pickAndScan(OcrImageSource.gallery);
      Get.put<OcrStore>(store, permanent: true);
      final shell = Get.put<AppShellStore>(AppShellStore());
      await tester.pumpWidget(GetMaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: '/',
        getPages: [
          GetPage<void>(
              name: '/', page: () => const Scaffold(body: Text('ROOT-SHELL'))),
          GetPage<void>(
              name: InventoryRoutes.list,
              page: () => const Scaffold(body: Text('INVENTORY'))),
          GetPage<void>(
              name: InventoryRoutes.scan,
              page: () => const Scaffold(body: Text('SCAN'))),
          GetPage<void>(
              name: InventoryRoutes.scanReview,
              page: () => const OcrResultScene()),
        ],
      ));
      await tester.pumpAndSettle();
      if (standalone) {
        unawaited(Get.toNamed<void>(InventoryRoutes.list));
        await tester.pumpAndSettle();
      }
      unawaited(Get.toNamed<void>(InventoryRoutes.scan));
      await tester.pumpAndSettle();
      unawaited(Get.toNamed<void>(InventoryRoutes.scanReview));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận tất cả'));
      await tester.pumpAndSettle();
      expect(
          find.text(standalone ? 'INVENTORY' : 'ROOT-SHELL'), findsOneWidget);
      expect(shell.selectedIndex, 1);
      expect(store.status, OcrStatus.idle);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('review state shows manual-review and duplicate badges',
      (tester) async {
    api.outcomes.add(
      const OcrScanResult(
        scanId: 'scan-1',
        items: <OcrItem>[
          _validItem,
          OcrItem(
            itemId: 'manual',
            name: 'Sữa tươi',
            quantity: null,
            unit: null,
            needsManualReview: true,
            rawQuantity: 1,
            rawUnit: 'hộp',
            duplicate: true,
            existingItemId: 'existing-1',
          ),
        ],
      ),
    );
    await store.pickAndScan(OcrImageSource.gallery);
    Get.put<OcrStore>(store);

    await tester.pumpAppWidget(
      const OcrResultScene(),
      wrapInScaffold: false,
    );

    expect(find.text('Kết quả quét (2)'), findsOneWidget);
    expect(find.text('Cần kiểm tra'), findsOneWidget);
    expect(find.text('Đã có trong tồn kho'), findsOneWidget);
    expect(find.text('Xác nhận tất cả'), findsOneWidget);
  });

  group('#239 confirmAll qua batch', () {
    late _FakeBatchApi batch;
    late int committed;

    setUp(() {
      batch = _FakeBatchApi();
      committed = 0;
      store = OcrStore(
        api: api,
        imagePicker: picker,
        imageCompressor: _FakeCompressor(),
        formStoreFactory: () => formStore,
        idempotencyKeyGenerator: () => 'fixed-key',
        batchApi: batch,
        onBatchCommitted: () async => committed++,
      );
    });

    test('ghi một lần batch, không gọi InventoryFormStore, gửi hạn theo ngày local',
        () async {
      api.outcomes.add(
        const OcrScanResult(scanId: 'scan-1', items: <OcrItem>[_validItem]),
      );
      await store.pickAndScan(OcrImageSource.gallery);
      store.editItem('item-1', expiryEstimate: DateTime(2026, 12, 1));

      await store.confirmAll();

      expect(batch.payloads.single.single['expiryDate'], '2026-12-01');
      expect(batch.payloads.single.single['unit'], 'quả');
      expect(store.items.single.confirmStatus, OcrConfirmStatus.confirmed);
      expect(store.status, OcrStatus.done);
      expect(committed, 1);
      verifyNever(
        () => formStore.save(
          name: any(named: 'name'),
          category: any(named: 'category'),
          quantity: any(named: 'quantity'),
          unit: any(named: 'unit'),
          lowStockThreshold: any(named: 'lowStockThreshold'),
          expiryDate: any(named: 'expiryDate'),
          note: any(named: 'note'),
        ),
      );
    });

    test('batch lỗi → mọi món failed, quay lại reviewing', () async {
      api.outcomes.add(
        const OcrScanResult(scanId: 'scan-1', items: <OcrItem>[_validItem]),
      );
      await store.pickAndScan(OcrImageSource.gallery);
      batch.failure = NetworkException();

      await store.confirmAll();

      expect(store.items.single.confirmStatus, OcrConfirmStatus.failed);
      expect(store.status, OcrStatus.reviewing);
      expect(committed, 0);
    });
  });
}
