import 'dart:convert';
import 'dart:typed_data';

import 'package:mobx/mobx.dart';

import '../../../../data/network/api_exception.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/uuid.dart';
import '../../data/inventory_batch_api.dart';
import '../../stores/inventory_form_store.dart';
import '../data/ocr_api.dart';
import '../data/ocr_image_service.dart';
import '../domain/ocr_item.dart';
import '../domain/ocr_scan_result.dart';

enum OcrStatus { idle, scanning, reviewing, confirming, done }

typedef InventoryFormStoreFactory = InventoryFormStore Function();

class OcrStore {
  OcrStore({
    required OcrApi api,
    required OcrImagePicker imagePicker,
    required OcrImageCompressor imageCompressor,
    required InventoryFormStoreFactory formStoreFactory,
    String Function()? idempotencyKeyGenerator,
    InventoryBatchApi? batchApi,
    Future<void> Function()? onBatchCommitted,
  })  : _api = api,
        _imagePicker = imagePicker,
        _imageCompressor = imageCompressor,
        _formStoreFactory = formStoreFactory,
        _idempotencyKeyGenerator = idempotencyKeyGenerator ?? createUuidV4,
        _batchApi = batchApi,
        _onBatchCommitted = onBatchCommitted;

  final OcrApi _api;
  final OcrImagePicker _imagePicker;
  final OcrImageCompressor _imageCompressor;
  final InventoryFormStoreFactory _formStoreFactory;
  final String Function() _idempotencyKeyGenerator;

  /// #239: có thì "Xác nhận tất cả" ghi MỘT lần batch (all-or-nothing) thay
  /// vì lặp `POST /inventory-items`. Lưu từng thẻ vẫn đi đường cũ.
  final InventoryBatchApi? _batchApi;
  final Future<void> Function()? _onBatchCommitted;

  /// Cùng nội dung gửi lại (vd. sau timeout) dùng lại key để BE không tạo trùng.
  String? _batchKey;
  String? _batchBody;

  final Observable<OcrStatus> _status = Observable(OcrStatus.idle);
  final Observable<OcrScanMode> _mode = Observable(OcrScanMode.item);
  final Observable<Object?> _scanError = Observable(null);
  final Observable<Uint8List?> _previewBytes = Observable(null);
  final ObservableList<OcrItem> items = ObservableList<OcrItem>();

  Uint8List? _compressedBytes;
  String? _idempotencyKey;
  bool _confirmingAll = false;

  OcrStatus get status => _status.value;
  OcrScanMode get mode => _mode.value;
  Object? get scanError => _scanError.value;
  Uint8List? get previewBytes => _previewBytes.value;

  bool get canConfirmAll =>
      items.isNotEmpty &&
      items.any((item) =>
          item.confirmStatus != OcrConfirmStatus.confirmed &&
          item.isValidForConfirm);

  int get failedCount => items
      .where((item) => item.confirmStatus == OcrConfirmStatus.failed)
      .length;

  int get confirmedCount => items
      .where((item) => item.confirmStatus == OcrConfirmStatus.confirmed)
      .length;

  bool get canRetryScan {
    final error = scanError;
    if (error is NetworkException) return true;
    if (error is! ApiException) return false;
    if (error is ServerException && error.code != 'ERR_AI_INVALID_OUTPUT') {
      return true;
    }
    return const <String>{
      'ERR_AI_TIMEOUT',
      'ERR_AI_SERVICE_DOWN',
      'ERR_AI_RATE_LIMIT',
      'ERR_INVENTORY_SCAN_IN_PROGRESS',
      'ERR_NETWORK',
    }.contains(error.code);
  }

  void setMode(OcrScanMode value) => runInAction(() => _mode.value = value);

  Future<bool> pickAndScan(OcrImageSource source) async {
    Uint8List? picked;
    try {
      picked = await _imagePicker.pick(source);
    } on OcrPermissionDeniedException catch (error) {
      runInAction(() => _scanError.value = error);
      return false;
    } catch (error) {
      runInAction(() => _scanError.value = error);
      return false;
    }
    if (picked == null) return false;

    runInAction(() {
      _status.value = OcrStatus.scanning;
      _scanError.value = null;
      _previewBytes.value = picked;
      items.clear();
    });
    try {
      final compressed = await _imageCompressor.compress(picked);
      _compressedBytes = compressed;
      _idempotencyKey = _idempotencyKeyGenerator();
      return await _callScan();
    } on OcrImageTooLargeException catch (error) {
      _setScanFailure(error, clearRetry: true);
    } on OcrImageInvalidException catch (error) {
      _setScanFailure(error, clearRetry: true);
    } on ApiException catch (error) {
      _setScanFailure(error);
    } catch (error) {
      _setScanFailure(error);
    }
    return false;
  }

  Future<bool> retryScan() async {
    if (_compressedBytes == null || _idempotencyKey == null) return false;
    runInAction(() {
      _status.value = OcrStatus.scanning;
      _scanError.value = null;
    });
    try {
      return await _callScan();
    } on ApiException catch (error) {
      _setScanFailure(error);
    } catch (error) {
      _setScanFailure(error);
    }
    return false;
  }

  Future<bool> _callScan() async {
    final result = await _api.scan(
      imageBytes: _compressedBytes!,
      idempotencyKey: _idempotencyKey!,
    );
    runInAction(() {
      items
        ..clear()
        ..addAll(result.items);
      _status.value = OcrStatus.reviewing;
    });
    return true;
  }

  void _setScanFailure(Object error, {bool clearRetry = false}) {
    if (clearRetry) {
      _compressedBytes = null;
      _idempotencyKey = null;
    }
    runInAction(() {
      _scanError.value = error;
      _status.value = OcrStatus.idle;
    });
  }

  void editItem(
    String itemId, {
    String? name,
    Object? quantity = _notProvided,
    Object? unit = _notProvided,
    Object? expiryEstimate = _notProvided,
  }) {
    final index = items.indexWhere((item) => item.itemId == itemId);
    if (index < 0) return;
    final item = items[index];
    runInAction(() {
      items[index] = item.copyWith(
        name: name,
        quantity: identical(quantity, _notProvided) ? item.quantity : quantity,
        unit: identical(unit, _notProvided) ? item.unit : unit,
        expiryEstimate: identical(expiryEstimate, _notProvided)
            ? item.expiryEstimate
            : expiryEstimate,
        confirmStatus: item.confirmStatus == OcrConfirmStatus.confirmed
            ? OcrConfirmStatus.confirmed
            : OcrConfirmStatus.pending,
        confirmError: null,
      );
    });
  }

  void removeItem(String itemId) {
    runInAction(() {
      items.removeWhere((item) => item.itemId == itemId);
      if (items.isNotEmpty && items.every(_isConfirmed)) {
        _status.value = OcrStatus.done;
      }
    });
  }

  Future<void> confirmItem(String itemId) async {
    var index = items.indexWhere((item) => item.itemId == itemId);
    if (index < 0) return;
    final item = items[index];
    if (item.confirmStatus == OcrConfirmStatus.confirmed ||
        item.confirmStatus == OcrConfirmStatus.confirming) {
      return;
    }
    if (!item.isValidForConfirm) {
      runInAction(() {
        items[index] = item.copyWith(confirmError: 'INVALID_OCR_ITEM');
      });
      return;
    }

    runInAction(() {
      items[index] = item.copyWith(
        confirmStatus: OcrConfirmStatus.confirming,
        confirmError: null,
      );
    });
    final formStore = _formStoreFactory();
    var saved = false;
    try {
      saved = await formStore.save(
        name: item.name,
        category: item.category,
        quantity: item.quantity!,
        unit: item.unit!,
        lowStockThreshold: null,
        expiryDate: item.expiryEstimate,
        note: null,
      );
    } catch (_) {
      // Lỗi lưu bất ngờ vẫn giữ người dùng ở màn xác nhận để thử lại.
      saved = false;
    }

    index = items.indexWhere((current) => current.itemId == itemId);
    if (index < 0) return;
    final current = items[index];
    runInAction(() {
      items[index] = saved
          ? current.copyWith(
              confirmStatus: OcrConfirmStatus.confirmed,
              confirmError: null,
            )
          : current.copyWith(
              confirmStatus: OcrConfirmStatus.failed,
              confirmError: formStore.saveError?.message ?? 'SAVE_FAILED',
            );
      if (items.isNotEmpty && items.every(_isConfirmed)) {
        _status.value = OcrStatus.done;
      }
    });
  }

  Future<void> confirmAll() async {
    if (items.isEmpty || _confirmingAll) return;
    _confirmingAll = true;
    try {
      final batchApi = _batchApi;
      if (batchApi != null) {
        await _confirmAllBatch(batchApi);
        return;
      }
      runInAction(() => _status.value = OcrStatus.confirming);
      final ids = items
          .where((item) => item.confirmStatus != OcrConfirmStatus.confirmed)
          .map((item) => item.itemId)
          .toList(growable: false);
      for (final id in ids) {
        await confirmItem(id);
      }
      if (items.isEmpty) return;
      runInAction(() {
        _status.value =
            items.every(_isConfirmed) ? OcrStatus.done : OcrStatus.reviewing;
      });
    } finally {
      _confirmingAll = false;
    }
  }

  Future<void> _confirmAllBatch(InventoryBatchApi batchApi) async {
    final ids = <String>[];
    runInAction(() {
      _status.value = OcrStatus.confirming;
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.confirmStatus == OcrConfirmStatus.confirmed) continue;
        if (!item.isValidForConfirm) {
          items[i] = item.copyWith(confirmError: 'INVALID_OCR_ITEM');
          continue;
        }
        ids.add(item.itemId);
        items[i] = item.copyWith(
          confirmStatus: OcrConfirmStatus.confirming,
          confirmError: null,
        );
      }
    });
    if (ids.isEmpty) {
      runInAction(() => _status.value =
          items.every(_isConfirmed) ? OcrStatus.done : OcrStatus.reviewing);
      return;
    }
    final payload = <Map<String, dynamic>>[
      for (final id in ids)
        _batchPayload(items.firstWhere((i) => i.itemId == id)),
    ];
    String? failure;
    Set<int> failedRows = const <int>{};
    final body = jsonEncode(payload);
    if (_batchKey == null || _batchBody != body) {
      _batchKey = createUuidV4();
      _batchBody = body;
    }
    try {
      await batchApi.batchCreate(payload, idempotencyKey: _batchKey!);
      _batchKey = null;
      _batchBody = null;
      await _onBatchCommitted?.call();
    } on ApiException catch (e) {
      failure = e.message;
      failedRows = batchErrorRows(e);
    }
    runInAction(() {
      for (var k = 0; k < ids.length; k++) {
        final index = items.indexWhere((i) => i.itemId == ids[k]);
        if (index < 0) continue;
        final current = items[index];
        items[index] = failure == null
            ? current.copyWith(
                confirmStatus: OcrConfirmStatus.confirmed, confirmError: null)
            // All-or-nothing: cả lô thất bại; dòng BE chỉ đích danh mang lỗi.
            : current.copyWith(
                confirmStatus: OcrConfirmStatus.failed,
                confirmError: failedRows.isEmpty || failedRows.contains(k)
                    ? failure
                    : null,
              );
      }
      _status.value = items.isNotEmpty && items.every(_isConfirmed)
          ? OcrStatus.done
          : OcrStatus.reviewing;
    });
  }

  static Map<String, dynamic> _batchPayload(OcrItem item) => <String, dynamic>{
        'name': item.name,
        if (item.category != null) 'category': item.category,
        'quantity': item.quantity,
        'unit': item.unit,
        if (item.expiryEstimate != null)
          'expiryDate': toApiDate(item.expiryEstimate!),
      };

  void reset() {
    _compressedBytes = null;
    _idempotencyKey = null;
    runInAction(() {
      _status.value = OcrStatus.idle;
      _mode.value = OcrScanMode.item;
      _scanError.value = null;
      _previewBytes.value = null;
      items.clear();
    });
  }

  static bool _isConfirmed(OcrItem item) =>
      item.confirmStatus == OcrConfirmStatus.confirmed;
}

const Object _notProvided = Object();
