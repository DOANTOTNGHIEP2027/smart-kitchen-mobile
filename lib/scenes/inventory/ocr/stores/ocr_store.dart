import 'dart:math';
import 'dart:typed_data';

import 'package:mobx/mobx.dart';

import '../../../../data/network/api_exception.dart';
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
  })  : _api = api,
        _imagePicker = imagePicker,
        _imageCompressor = imageCompressor,
        _formStoreFactory = formStoreFactory,
        _idempotencyKeyGenerator = idempotencyKeyGenerator ?? _createUuidV4;

  final OcrApi _api;
  final OcrImagePicker _imagePicker;
  final OcrImageCompressor _imageCompressor;
  final InventoryFormStoreFactory _formStoreFactory;
  final String Function() _idempotencyKeyGenerator;

  final Observable<OcrStatus> _status = Observable(OcrStatus.idle);
  final Observable<OcrScanMode> _mode = Observable(OcrScanMode.item);
  final Observable<Object?> _scanError = Observable(null);
  final Observable<Uint8List?> _previewBytes = Observable(null);
  final ObservableList<OcrItem> items = ObservableList<OcrItem>();

  Uint8List? _compressedBytes;
  String? _idempotencyKey;

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
    final saved = await formStore.save(
      name: item.name,
      category: item.category,
      quantity: item.quantity!,
      unit: item.unit!,
      lowStockThreshold: null,
      expiryDate: item.expiryEstimate,
      note: null,
    );

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
    if (items.isEmpty) return;
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
  }

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

String _createUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String pair(int value) => value.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(pair).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
