import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart' show reaction;
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_image_service.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/domain/ocr_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_form_store.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/data/receipt_api.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_matched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_unmatched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/stores/receipt_scan_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';

class _FakeReceiptApi implements ReceiptApi {
  final List<String> keys = <String>[];
  final List<Uint8List> bytes = <Uint8List>[];
  final List<CancelToken?> tokens = <CancelToken?>[];

  /// Mỗi lần gọi lấy 1 phần tử: ReceiptScanResult → trả; Completer → chờ;
  /// còn lại → throw.
  final List<Object> outcomes = <Object>[];

  @override
  Future<ReceiptScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    keys.add(idempotencyKey);
    bytes.add(imageBytes);
    tokens.add(cancelToken);
    final outcome = outcomes.removeAt(0);
    if (outcome is ReceiptScanResult) return outcome;
    if (outcome is Completer<ReceiptScanResult>) return outcome.future;
    throw outcome;
  }
}

class _FakePicker implements OcrImagePicker {
  Uint8List? bytes = Uint8List.fromList(<int>[1, 2, 3]);
  Object? error;

  @override
  Future<Uint8List?> pick(OcrImageSource source) async {
    if (error != null) throw error!;
    return bytes;
  }
}

class _FakeCompressor implements OcrImageCompressor {
  Object? error;

  @override
  Future<Uint8List> compress(Uint8List bytes) async {
    if (error != null) throw error!;
    return Uint8List.fromList(<int>[...bytes, 9]);
  }
}

class _SpyShoppingStore implements ShoppingStore {
  final List<Map<String, double?>> calls = <Map<String, double?>>[];
  List<String> failures = <String>[];
  Completer<List<String>>? gate;
  Object? bulkError;

  @override
  Future<List<String>> bulkCheck(Map<String, double?> priceById) async {
    calls.add(Map<String, double?>.of(priceById));
    if (bulkError != null) throw bulkError!;
    final pending = gate;
    if (pending != null) return pending.future;
    return failures;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockInventoryFormStore extends Mock implements InventoryFormStore {}

ReceiptMatchedItem _line(
  int index,
  String shoppingItemId, {
  double? totalPrice,
  double confidence = 0.95,
}) =>
    ReceiptMatchedItem(
      lineKey: 'm$index',
      shoppingItemId: shoppingItemId,
      shoppingItemName: 'Món $shoppingItemId',
      rawName: 'RAW $index',
      quantity: 1,
      unit: 'kg',
      totalPrice: totalPrice,
      matchConfidence: confidence,
    );

const _unmatched = ReceiptUnmatchedItem(
  itemId: 'u-1',
  name: 'Sữa tươi',
  category: 'Sữa',
  quantity: 2,
  rawName: 'SUA TUOI',
  rawQuantity: 2,
  rawUnit: 'hop',
);

ReceiptScanResult _result({
  List<ReceiptMatchedItem>? matched,
  List<ReceiptUnmatchedItem>? unmatched,
  String currency = 'VND',
}) =>
    ReceiptScanResult(
      meta: ReceiptScanMeta(scanId: 'scan-1', currency: currency),
      matchedItems: matched ??
          <ReceiptMatchedItem>[
            _line(0, 'si-1', totalPrice: 45000),
            _line(1, 'si-1', totalPrice: 5000, confidence: 0.87),
            _line(2, 'si-2', totalPrice: 20000),
          ],
      unmatchedItems: unmatched ?? const <ReceiptUnmatchedItem>[_unmatched],
    );

void main() {
  late _FakeReceiptApi api;
  late _FakePicker picker;
  late _FakeCompressor compressor;
  late _SpyShoppingStore shopping;
  late _MockInventoryFormStore formStore;
  late int formStoreCreated;
  late int keyCounter;
  late ReceiptScanStore store;

  void stubSave(Future<bool> Function() answer) {
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
    ).thenAnswer((_) => answer());
  }

  void verifySaveCalled(int times) {
    verify(
      () => formStore.save(
        name: any(named: 'name'),
        category: any(named: 'category'),
        quantity: any(named: 'quantity'),
        unit: any(named: 'unit'),
        lowStockThreshold: any(named: 'lowStockThreshold'),
        expiryDate: any(named: 'expiryDate'),
        note: any(named: 'note'),
      ),
    ).called(times);
  }

  setUp(() {
    api = _FakeReceiptApi();
    picker = _FakePicker();
    compressor = _FakeCompressor();
    shopping = _SpyShoppingStore();
    formStore = _MockInventoryFormStore();
    formStoreCreated = 0;
    keyCounter = 0;
    store = ReceiptScanStore(
      api: api,
      imagePicker: picker,
      imageCompressor: compressor,
      shoppingStore: shopping,
      formStoreFactory: () {
        formStoreCreated++;
        return formStore;
      },
      idempotencyKeyGenerator: () => 'key-${++keyCounter}',
    );
  });

  group('quét', () {
    test('startScan 200 → reviewing, đếm đúng, matched chọn sẵn hết', () async {
      api.outcomes.add(_result());

      expect(await store.pickAndScan(OcrImageSource.gallery), isTrue);

      expect(store.status, ReceiptScanStatus.reviewing);
      expect(store.matchedItems, hasLength(3));
      expect(store.unmatchedItems, hasLength(1));
      expect(store.selectedLineKeys, <String>{'m0', 'm1', 'm2'});
      expect(store.selectedItemCount, 2); // 3 dòng · 2 món
      expect(store.commitPending, isTrue);
      expect(store.hasOpenUnmatched, isTrue);
      expect(store.isEmptyResult, isFalse);
      expect(store.meta?.scanId, 'scan-1');
      expect(store.previewBytes, Uint8List.fromList(<int>[1, 2, 3]));
      expect(api.keys, <String>['key-1']);
      expect(api.bytes.single, Uint8List.fromList(<int>[1, 2, 3, 9]));
    });

    test('200 rỗng → isEmptyResult, commitPending false', () async {
      api.outcomes.add(
        _result(
          matched: const <ReceiptMatchedItem>[],
          unmatched: const <ReceiptUnmatchedItem>[],
        ),
      );

      await store.pickAndScan(OcrImageSource.camera);

      expect(store.isEmptyResult, isTrue);
      expect(store.commitPending, isFalse);
    });

    test('pick null → không đổi trạng thái, không gọi API', () async {
      picker.bytes = null;

      expect(await store.pickAndScan(OcrImageSource.gallery), isFalse);

      expect(store.status, ReceiptScanStatus.idle);
      expect(store.scanError, isNull);
      expect(api.keys, isEmpty);
    });

    test('từ chối quyền → scanError permission, idle, không retry', () async {
      picker.error = const OcrPermissionDeniedException();

      expect(await store.pickAndScan(OcrImageSource.camera), isFalse);

      expect(store.scanError, isA<OcrPermissionDeniedException>());
      expect(store.status, ReceiptScanStatus.idle);
      expect(store.canRetryScan, isFalse);
      expect(api.keys, isEmpty);
    });

    test('ảnh quá lớn / hỏng (cục bộ) → không gọi API, canResend false',
        () async {
      compressor.error = const OcrImageTooLargeException();
      await store.pickAndScan(OcrImageSource.gallery);
      expect(store.scanError, isA<OcrImageTooLargeException>());
      expect(store.canResend, isFalse);
      expect(store.canRetryScan, isFalse);

      compressor.error = const OcrImageInvalidException();
      await store.pickAndScan(OcrImageSource.gallery);
      expect(store.scanError, isA<OcrImageInvalidException>());
      expect(store.canResend, isFalse);
      expect(store.status, ReceiptScanStatus.idle);
      expect(api.keys, isEmpty);
    });

    test('lỗi mạng → retry dùng lại ĐÚNG key + bytes', () async {
      api.outcomes
        ..add(NetworkException())
        ..add(_result());

      expect(await store.pickAndScan(OcrImageSource.gallery), isFalse);
      expect(store.canRetryScan, isTrue);
      expect(await store.retryScan(), isTrue);

      expect(api.keys, <String>['key-1', 'key-1']);
      expect(identical(api.bytes[0], api.bytes[1]), isTrue);
      expect(store.status, ReceiptScanStatus.reviewing);
    });

    test('409 ERR_RECEIPT_SCAN_IN_PROGRESS → retryable', () async {
      api.outcomes.add(
        BusinessException('ERR_RECEIPT_SCAN_IN_PROGRESS', 'in progress'),
      );

      await store.pickAndScan(OcrImageSource.gallery);

      expect(store.scanError, isA<BusinessException>());
      expect(store.canRetryScan, isTrue);
    });

    test('503 / 429 / 504 → retryable; 502 / 403 / 422 → không', () async {
      Future<bool> retryableFor(ApiException error) async {
        api.outcomes.add(error);
        await store.pickAndScan(OcrImageSource.gallery);
        return store.canRetryScan;
      }

      expect(await retryableFor(ServerException('ERR_AI_SERVICE_DOWN', 'x')),
          isTrue);
      expect(await retryableFor(BusinessException('ERR_AI_RATE_LIMIT', 'x')),
          isTrue);
      expect(
          await retryableFor(ServerException('ERR_AI_TIMEOUT', 'x')), isTrue);
      expect(await retryableFor(ServerException('ERR_AI_INVALID_OUTPUT', 'x')),
          isFalse);
      expect(
        await retryableFor(BusinessException('ERR_RECEIPT_NO_HOUSEHOLD', 'x')),
        isFalse,
      );
      expect(
        await retryableFor(BusinessException('ERR_AI_CONTENT_FILTERED', 'x')),
        isFalse,
      );
    });

    test('ảnh mới → key mới; retry không sinh key mới', () async {
      api.outcomes
        ..add(NetworkException())
        ..add(NetworkException())
        ..add(_result());

      await store.pickAndScan(OcrImageSource.gallery);
      await store.retryScan();
      await store.pickAndScan(OcrImageSource.gallery);

      expect(api.keys, <String>['key-1', 'key-1', 'key-2']);
    });

    test('Huỷ khi đang chờ → idle, không lỗi, giữ key; response muộn bị bỏ',
        () async {
      final pending = Completer<ReceiptScanResult>();
      api.outcomes.add(pending);

      final future = store.pickAndScan(OcrImageSource.gallery);
      await Future<void>.delayed(Duration.zero);
      expect(store.status, ReceiptScanStatus.scanning);

      store.cancelScan();
      expect(api.tokens.single?.isCancelled, isTrue);
      pending.complete(_result()); // response về sát lúc Huỷ

      expect(await future, isFalse);
      expect(store.status, ReceiptScanStatus.idle);
      expect(store.scanError, isNull);
      expect(store.matchedItems, isEmpty);
      expect(store.canResend, isTrue);

      api.outcomes.add(_result());
      expect(await store.retryScan(), isTrue);
      expect(api.keys, <String>['key-1', 'key-1']);
    });

    test('Huỷ → lỗi huỷ (NetworkException) không hiện thành scanError',
        () async {
      final pending = Completer<ReceiptScanResult>();
      api.outcomes.add(pending);

      final future = store.pickAndScan(OcrImageSource.gallery);
      await Future<void>.delayed(Duration.zero);
      store.cancelScan();
      pending.completeError(NetworkException());

      expect(await future, isFalse);
      expect(store.scanError, isNull);
      expect(store.status, ReceiptScanStatus.idle);
      expect(store.canResend, isTrue);
    });

    test('ảnh mới lỗi lúc nén (không phải lỗi ảnh) → KHÔNG giữ ảnh/key cũ',
        () async {
      api.outcomes.add(NetworkException());
      await store.pickAndScan(OcrImageSource.gallery); // ảnh A, key-1
      expect(store.canResend, isTrue);

      picker.bytes = Uint8List.fromList(<int>[7, 7]); // ảnh B
      compressor.error = StateError('compress crashed');
      await store.pickAndScan(OcrImageSource.camera);

      expect(store.previewBytes, Uint8List.fromList(<int>[7, 7]));
      expect(store.canResend, isFalse);
      expect(store.canRetryScan, isFalse);
      expect(await store.retryScan(), isFalse);
      expect(api.keys, <String>['key-1']); // ảnh A không bị gửi lại
    });

    test('canResend là observable — reaction thấy đổi (L1)', () async {
      final seen = <bool>[];
      final dispose = reaction((_) => store.canResend, seen.add);
      addTearDown(dispose.call);

      api.outcomes.add(NetworkException());
      await store.pickAndScan(OcrImageSource.gallery);
      store.reset();

      expect(seen, <bool>[true, false]);
    });

    test('lastPickSource nhớ nguồn của lần chọn gần nhất, reset xoá', () async {
      picker.error = const OcrPermissionDeniedException();
      await store.pickAndScan(OcrImageSource.camera);
      expect(store.lastPickSource, OcrImageSource.camera);

      store.reset();
      expect(store.lastPickSource, isNull);
    });

    test('cancelScan khi không scanning → no-op', () {
      store.cancelScan();
      expect(store.status, ReceiptScanStatus.idle);
    });
  });

  group('review + commit', () {
    Future<void> scanned({String currency = 'VND'}) async {
      api.outcomes.add(_result(currency: currency));
      await store.pickAndScan(OcrImageSource.gallery);
    }

    test('commitMatched gọi bulkCheck 1 entry/món, giá = tổng nhóm', () async {
      await scanned();

      final result = await store.commitMatched();

      expect(shopping.calls.single, <String, double?>{
        'si-1': 50000,
        'si-2': 20000,
      });
      expect(result.allSucceeded, isTrue);
      expect(result.updatedCount, 2);
      expect(store.matchedCommitted, isTrue);
      expect(store.committedItemIds, <String>{'si-1', 'si-2'});
      expect(store.status, ReceiptScanStatus.reviewing);
      expect(store.commitPending, isFalse);
    });

    test('1 dòng trong nhóm thiếu totalPrice → giá nhóm null', () async {
      api.outcomes.add(
        _result(
          matched: <ReceiptMatchedItem>[
            _line(0, 'si-1', totalPrice: 45000),
            _line(1, 'si-1'),
          ],
        ),
      );
      await store.pickAndScan(OcrImageSource.gallery);

      await store.commitMatched();

      expect(shopping.calls.single, <String, double?>{'si-1': null});
    });

    test('currency USD → không gửi giá', () async {
      await scanned(currency: 'USD');

      await store.commitMatched();

      expect(shopping.calls.single, <String, double?>{
        'si-1': null,
        'si-2': null,
      });
    });

    test(
        'bỏ chọn 1 dòng → giá nhóm chỉ còn dòng đã chọn; bỏ hết nhóm → không gửi',
        () async {
      await scanned();

      store.toggleMatchedLine('m1');
      expect(store.selectedItemCount, 2);
      store.toggleMatchedLine('m2');
      expect(store.selectedItemCount, 1);
      await store.commitMatched();

      expect(shopping.calls.single, <String, double?>{'si-1': 45000});
    });

    test('bỏ chọn tất cả → commitPending false, commit bị chặn (skipped)',
        () async {
      await scanned();
      for (final key in <String>['m0', 'm1', 'm2']) {
        store.toggleMatchedLine(key);
      }

      final result = await store.commitMatched();

      expect(result.skipped, isTrue);
      expect(result.allSucceeded, isFalse);
      expect(shopping.calls, isEmpty);
    });

    test('bulkCheck trả failure → failedItemIds, allSucceeded false', () async {
      shopping.failures = <String>['si-2'];
      await scanned();

      final result = await store.commitMatched();

      expect(result.allSucceeded, isFalse);
      expect(result.failedCount, 1);
      expect(store.failedItemIds, <String>{'si-2'});
      expect(store.committedItemIds, <String>{'si-1'});
    });

    test(
        'double-tap commit: lần 2 skipped NGAY khi lần 1 còn treo; '
        'bulkCheck 1 lần', () async {
      await scanned();
      final gate = Completer<List<String>>();
      shopping.gate = gate;

      var firstDone = false;
      final first = store.commitMatched() // không await — bulkCheck treo
        ..then((_) => firstDone = true);
      await Future<void>.delayed(Duration.zero);
      expect(store.status, ReceiptScanStatus.committing);
      expect(firstDone, isFalse); // chắc chắn lần 1 còn treo

      final second = await store.commitMatched();
      expect(second.skipped, isTrue);
      expect(second.allSucceeded, isFalse);
      expect(firstDone, isFalse);
      expect(store.status, ReceiptScanStatus.committing);
      expect(shopping.calls, hasLength(1));

      gate.complete(<String>[]);
      final done = await first;
      expect(done.allSucceeded, isTrue);
      expect(store.status, ReceiptScanStatus.reviewing);

      final after = await store.commitMatched(); // đã commit
      expect(after.skipped, isTrue);
      expect(shopping.calls, hasLength(1));
    });

    test('bulkCheck throw → không throw, mọi món failed, không kẹt committing',
        () async {
      await scanned();
      shopping.bulkError = StateError('boom');

      final result = await store.commitMatched();

      expect(store.status, ReceiptScanStatus.reviewing);
      expect(result.allSucceeded, isFalse);
      expect(result.failedCount, 2);
      expect(store.failedItemIds, <String>{'si-1', 'si-2'});
      expect(store.committedItemIds, isEmpty);
      expect(store.matchedCommitted, isTrue);
    });

    test('sau commit không đổi được lựa chọn', () async {
      await scanned();
      await store.commitMatched();

      store.toggleMatchedLine('m0');

      expect(store.selectedLineKeys, contains('m0'));
    });
  });

  group('unmatched (Guard 12)', () {
    Future<void> scanned() async {
      api.outcomes.add(_result());
      await store.pickAndScan(OcrImageSource.gallery);
    }

    test('chưa chọn unit → INVALID_RECEIPT_ITEM, không gọi save()', () async {
      await scanned();

      expect(await store.confirmUnmatchedItem('u-1'), isFalse);

      expect(store.unmatchedItems.single.confirmError, 'INVALID_RECEIPT_ITEM');
      expect(store.unmatchedItems.single.confirmStatus,
          ReceiptConfirmStatus.pending);
      expect(formStoreCreated, 0);
    });

    test('double-tap không await → save() đúng 1 lần, đúng tham số', () async {
      await scanned();
      store.editUnmatchedItem('u-1', unit: 'cái');
      final gate = Completer<bool>();
      stubSave(() => gate.future);

      final first = store.confirmUnmatchedItem('u-1');
      final second = store.confirmUnmatchedItem('u-1');
      expect(store.unmatchedItems.single.confirmStatus,
          ReceiptConfirmStatus.confirming);
      expect(store.hasConfirmingUnmatched, isTrue);
      gate.complete(true);

      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(store.unmatchedItems.single.confirmStatus,
          ReceiptConfirmStatus.confirmed);
      expect(store.hasOpenUnmatched, isFalse);
      verify(
        () => formStore.save(
          name: 'Sữa tươi',
          category: 'Sữa',
          quantity: 2,
          unit: 'cái',
          lowStockThreshold: null,
          expiryDate: null,
          note: null,
        ),
      ).called(1);

      // Bấm lại sau confirmed → không gọi nữa; sửa field bị khoá.
      expect(await store.confirmUnmatchedItem('u-1'), isFalse);
      store.editUnmatchedItem('u-1', name: 'Khác');
      expect(store.unmatchedItems.single.name, 'Sữa tươi');
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

    test('lỗi → failed + mã lỗi; sửa field → pending; retry ghi 1 lần',
        () async {
      await scanned();
      store.editUnmatchedItem('u-1', unit: 'cái');
      stubSave(() async => false);
      when(() => formStore.saveError).thenReturn(NetworkException());

      expect(await store.confirmUnmatchedItem('u-1'), isFalse);
      expect(store.unmatchedItems.single.confirmStatus,
          ReceiptConfirmStatus.failed);
      expect(store.unmatchedItems.single.confirmError, 'ERR_NETWORK');
      expect(store.hasOpenUnmatched, isTrue);

      store.editUnmatchedItem('u-1', quantity: 3.0);
      expect(store.unmatchedItems.single.confirmStatus,
          ReceiptConfirmStatus.pending);
      expect(store.unmatchedItems.single.confirmError, isNull);

      stubSave(() async => true);
      expect(await store.confirmUnmatchedItem('u-1'), isTrue);
      expect(await store.confirmUnmatchedItem('u-1'), isFalse);

      expect(store.unmatchedItems.single.confirmStatus,
          ReceiptConfirmStatus.confirmed);
      verifySaveCalled(2); // 1 lần lỗi + 1 lần thành công, không trùng
    });

    test('thêm tất cả: thêm lần lượt thẻ đủ thông tin, bỏ qua thẻ thiếu đơn vị, lỗi 1 thẻ không chặn thẻ sau',
        () async {
      api.outcomes.add(_result(unmatched: const <ReceiptUnmatchedItem>[
        _unmatched,
        ReceiptUnmatchedItem(itemId: 'u-2', name: 'Trứng', quantity: 10, unit: 'quả', rawName: 'TRUNG', rawQuantity: 1, rawUnit: 'cai'),
        ReceiptUnmatchedItem(itemId: 'u-3', name: 'Bơ', quantity: 1, rawName: 'BO', rawQuantity: 1, rawUnit: 'cai'),
        ReceiptUnmatchedItem(itemId: 'u-4', name: 'Táo', quantity: 3, unit: 'quả', rawName: 'TAO', rawQuantity: 1, rawUnit: 'cai'),
      ]));
      await store.pickAndScan(OcrImageSource.gallery);
      store.editUnmatchedItem('u-1', unit: 'cái');
      expect(store.bulkAddableCount, 3); // u-3 chưa chọn đơn vị
      expect(store.bulkIncompleteCount, 1);

      var calls = 0;
      stubSave(() async => ++calls != 2); // thẻ thứ 2 (u-2) lỗi
      when(() => formStore.saveError).thenReturn(NetworkException());

      final running = store.confirmAllUnmatched();
      expect(store.isBulkAdding, isTrue);
      expect(store.hasConfirmingUnmatched, isTrue);
      expect(await running, 2);

      ReceiptConfirmStatus status(String id) =>
          store.unmatchedItems.firstWhere((i) => i.itemId == id).confirmStatus;
      expect(status('u-1'), ReceiptConfirmStatus.confirmed);
      expect(status('u-2'), ReceiptConfirmStatus.failed);
      expect(status('u-3'), ReceiptConfirmStatus.pending);
      expect(status('u-4'), ReceiptConfirmStatus.confirmed);
      verifySaveCalled(3);
      expect(store.isBulkAdding, isFalse);

      // Bấm lại chỉ thử lại thẻ lỗi, không ghi trùng thẻ đã thêm.
      expect(store.bulkAddableCount, 1);
      expect(await store.confirmAllUnmatched(), 1);
      expect(status('u-2'), ReceiptConfirmStatus.confirmed);
    });

    test('save() throw → failed SAVE_FAILED, không kẹt confirming', () async {
      await scanned();
      store.editUnmatchedItem('u-1', unit: 'cái');
      stubSave(() async => throw StateError('boom'));
      when(() => formStore.saveError).thenReturn(null);

      expect(await store.confirmUnmatchedItem('u-1'), isFalse);

      expect(store.unmatchedItems.single.confirmStatus,
          ReceiptConfirmStatus.failed);
      expect(store.unmatchedItems.single.confirmError, 'SAVE_FAILED');
    });

    test('editUnmatchedItem: null xoá field, không truyền thì giữ', () async {
      await scanned();

      store.editUnmatchedItem('u-1', unit: 'kg', category: null);

      final item = store.unmatchedItems.single;
      expect(item.unit, 'kg');
      expect(item.category, isNull);
      expect(item.quantity, 2);
      expect(item.name, 'Sữa tươi');
    });
  });

  test('reset → idle, xoá kết quả, ảnh, key', () async {
    api.outcomes.add(_result());
    await store.pickAndScan(OcrImageSource.gallery);
    await store.commitMatched();

    store.reset();

    expect(store.status, ReceiptScanStatus.idle);
    expect(store.scanError, isNull);
    expect(store.previewBytes, isNull);
    expect(store.meta, isNull);
    expect(store.matchedItems, isEmpty);
    expect(store.unmatchedItems, isEmpty);
    expect(store.selectedLineKeys, isEmpty);
    expect(store.committedItemIds, isEmpty);
    expect(store.failedItemIds, isEmpty);
    expect(store.matchedCommitted, isFalse);
    expect(store.canResend, isFalse);
    expect(await store.retryScan(), isFalse);
  });
}
