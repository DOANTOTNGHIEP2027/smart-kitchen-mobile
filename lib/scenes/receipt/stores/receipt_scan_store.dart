import 'dart:typed_data';

import 'package:dio/dio.dart' show CancelToken;
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../utils/uuid.dart';
import '../../inventory/ocr/data/ocr_image_service.dart';
import '../../inventory/ocr/domain/ocr_scan_result.dart' show OcrImageSource;
import '../../inventory/ocr/stores/ocr_store.dart'
    show InventoryFormStoreFactory;
import '../../shopping/stores/shopping_store.dart';
import '../data/receipt_api.dart';
import '../domain/receipt_matched_item.dart';
import '../domain/receipt_scan_result.dart';
import '../domain/receipt_unmatched_item.dart';

enum ReceiptScanStatus { idle, scanning, reviewing, committing }

class ReceiptCommitResult {
  const ReceiptCommitResult({
    required this.updatedCount,
    required this.failedCount,
  }) : skipped = false;

  /// Lần gọi bị guard chặn (đang commit / đã commit / không có dòng chọn) —
  /// KHÔNG có gì được ghi, scene không được coi là thành công.
  const ReceiptCommitResult.skipped()
      : updatedCount = 0,
        failedCount = 0,
        skipped = true;

  /// Số MÓN (shoppingItemId đã dedupe), không phải số dòng.
  final int updatedCount;
  final int failedCount;
  final bool skipped;

  bool get allSucceeded => !skipped && failedCount == 0;
}

/// Điều phối quét hoá đơn (#68, shopping-receipt-scan.md §9). Viết tay
/// `Observable` + `runInAction` như OcrStore — không codegen. Không điều hướng,
/// không giữ câu chữ hiển thị (D18): chỉ trạng thái, số đếm và mã lỗi.
class ReceiptScanStore {
  ReceiptScanStore({
    required ReceiptApi api,
    required OcrImagePicker imagePicker,
    required OcrImageCompressor imageCompressor,
    required ShoppingStore shoppingStore,
    required InventoryFormStoreFactory formStoreFactory,
    String Function()? idempotencyKeyGenerator,
  })  : _api = api,
        _imagePicker = imagePicker,
        _imageCompressor = imageCompressor,
        _shoppingStore = shoppingStore,
        _formStoreFactory = formStoreFactory,
        _idempotencyKeyGenerator = idempotencyKeyGenerator ?? createUuidV4;

  final ReceiptApi _api;
  final OcrImagePicker _imagePicker;
  final OcrImageCompressor _imageCompressor;
  final ShoppingStore _shoppingStore;
  final InventoryFormStoreFactory _formStoreFactory;
  final String Function() _idempotencyKeyGenerator;

  final Observable<ReceiptScanStatus> _status =
      Observable(ReceiptScanStatus.idle);
  final Observable<Object?> _scanError = Observable(null);
  final Observable<Uint8List?> _previewBytes = Observable(null);
  final Observable<ReceiptScanMeta?> _meta = Observable(null);
  final Observable<bool> _matchedCommitted = Observable(false);

  /// Gương observable của `_compressedBytes != null && _idempotencyKey != null`
  /// — chỉ đổi qua [_setResendPayload] để `canResend` luôn phản ứng (L1).
  final Observable<bool> _canResend = Observable(false);
  final Observable<bool> _bulkAdding = Observable(false);
  final ObservableList<ReceiptMatchedItem> matchedItems =
      ObservableList<ReceiptMatchedItem>();
  final ObservableList<ReceiptUnmatchedItem> unmatchedItems =
      ObservableList<ReceiptUnmatchedItem>();

  /// Khoá theo lineKey (D23) — mặc định chọn tất cả.
  final ObservableSet<String> selectedLineKeys = ObservableSet<String>();

  /// Sau commitMatched(): shoppingItemId đã chắc COMPLETED / không chắc.
  final ObservableSet<String> committedItemIds = ObservableSet<String>();
  final ObservableSet<String> failedItemIds = ObservableSet<String>();

  Uint8List? _compressedBytes;
  String? _idempotencyKey;
  CancelToken? _cancelToken;
  bool _cancelled = false;
  OcrImageSource? _lastPickSource;

  ReceiptScanStatus get status => _status.value;
  Object? get scanError => _scanError.value;
  Uint8List? get previewBytes => _previewBytes.value;
  ReceiptScanMeta? get meta => _meta.value;
  bool get matchedCommitted => _matchedCommitted.value;

  /// Còn ảnh + key để gửi lại đúng key cũ (sau Huỷ hoặc lỗi tạm thời).
  bool get canResend => _canResend.value;

  /// Nguồn ảnh của lần chọn gần nhất — nút "Thử lại" khi bị từ chối quyền
  /// chọn lại đúng nguồn đó (L4).
  OcrImageSource? get lastPickSource => _lastPickSource;

  bool get isEmptyResult =>
      status == ReceiptScanStatus.reviewing &&
      matchedItems.isEmpty &&
      unmatchedItems.isEmpty;

  /// Số MÓN sẽ được đánh dấu (đã dedupe) — cho nhãn "Cập nhật… (n)".
  int get selectedItemCount => matchedItems
      .where((line) => selectedLineKeys.contains(line.lineKey))
      .map((line) => line.shoppingItemId)
      .toSet()
      .length;

  /// true → nút chung là "Cập nhật…"; false → nút chung là "Xong" (Q9, D22).
  bool get commitPending =>
      matchedItems.isNotEmpty &&
      !matchedCommitted &&
      selectedLineKeys.isNotEmpty;

  /// Còn thẻ unmatched chưa thêm (pending/failed) hoặc đang thêm.
  bool get hasOpenUnmatched => unmatchedItems
      .any((item) => item.confirmStatus != ReceiptConfirmStatus.confirmed);

  /// Thẻ "Thêm tất cả vào kho" thêm được ngay: chưa thêm (pending/failed) và
  /// đủ thông tin.
  int get bulkAddableCount => unmatchedItems
      .where((item) => !item.isLocked && item.isValidForConfirm)
      .length;

  /// Thẻ chưa thêm nhưng thiếu thông tin (vd. chưa chọn đơn vị) — bị bỏ qua.
  int get bulkIncompleteCount => unmatchedItems
      .where((item) => !item.isLocked && !item.isValidForConfirm)
      .length;

  bool get isBulkAdding => _bulkAdding.value;

  /// Gồm cả khoảng giữa 2 thẻ của "Thêm tất cả" — "Xong" không được bấm lọt.
  bool get hasConfirmingUnmatched =>
      _bulkAdding.value ||
      unmatchedItems
          .any((item) => item.confirmStatus == ReceiptConfirmStatus.confirming);

  bool get canRetryScan {
    if (!canResend) return false;
    final error = scanError;
    if (error is NetworkException) return true;
    if (error is ServerException && error.code != 'ERR_AI_INVALID_OUTPUT') {
      return true;
    }
    if (error is! ApiException) return false;
    return const <String>{
      'ERR_AI_TIMEOUT',
      'ERR_AI_SERVICE_DOWN',
      'ERR_AI_RATE_LIMIT',
      'ERR_RECEIPT_SCAN_IN_PROGRESS',
    }.contains(error.code);
  }

  // ── Quét ──────────────────────────────────────────────────────────────

  /// Khung y hệt OcrStore.pickAndScan. Trả true khi có kết quả 200 → scene
  /// push màn kết quả.
  Future<bool> pickAndScan(OcrImageSource source) async {
    Uint8List? picked;
    _lastPickSource = source;
    try {
      picked = await _imagePicker.pick(source);
    } catch (error) {
      // Gồm OcrPermissionDeniedException → scene hiện "Mở cài đặt" (Guard 9).
      runInAction(() => _scanError.value = error);
      return false;
    }
    if (picked == null) return false;

    // Ảnh mới: bỏ ảnh + key cũ NGAY, trước khi nén — nén lỗi/Huỷ không được
    // để "Thử lại" gửi ảnh cũ dưới preview mới (L2).
    _setResendPayload(null, null);
    _beginScan(preview: picked);
    try {
      final compressed = await _imageCompressor.compress(picked);
      _setResendPayload(compressed, _idempotencyKeyGenerator());
      return await _callScan();
    } on OcrImageTooLargeException catch (error) {
      _setScanFailure(error, clearRetry: true);
    } on OcrImageInvalidException catch (error) {
      _setScanFailure(error, clearRetry: true);
    } catch (error) {
      _setScanFailure(error); // ApiException + mọi lỗi khác
    }
    return false;
  }

  /// Guard 5: dùng lại ĐÚNG ảnh + key cũ.
  Future<bool> retryScan() async {
    if (!canResend) return false;
    _beginScan();
    try {
      return await _callScan();
    } catch (error) {
      _setScanFailure(error);
    }
    return false;
  }

  /// Nút Huỷ khi đang chờ (D17). Lỗi huỷ đi qua ErrorMappingInterceptor thành
  /// NetworkException — không phân biệt được bằng kiểu, nên dùng cờ.
  /// GIỮ ảnh + key: BE có thể vẫn đang chạy; gửi lại cùng key nhận 409 hoặc
  /// kết quả cache.
  void cancelScan() {
    if (status != ReceiptScanStatus.scanning) return;
    _cancelled = true;
    _cancelToken?.cancel();
  }

  void _beginScan({Uint8List? preview}) {
    _cancelled = false;
    _cancelToken = CancelToken();
    runInAction(() {
      _status.value = ReceiptScanStatus.scanning;
      _scanError.value = null;
      if (preview != null) _previewBytes.value = preview;
      _clearResult();
    });
  }

  Future<bool> _callScan() async {
    if (_cancelled) return _finishCancelled(); // Huỷ bấm lúc đang nén
    final result = await _api.scan(
      imageBytes: _compressedBytes!,
      idempotencyKey: _idempotencyKey!,
      cancelToken: _cancelToken,
    );
    if (_cancelled) return _finishCancelled(); // response về sát lúc Huỷ — bỏ
    runInAction(() {
      _meta.value = result.meta;
      matchedItems.addAll(result.matchedItems);
      unmatchedItems.addAll(result.unmatchedItems);
      selectedLineKeys.addAll(result.matchedItems.map((line) => line.lineKey));
      _status.value = ReceiptScanStatus.reviewing;
    });
    return true;
  }

  bool _finishCancelled() {
    _cancelled = false;
    runInAction(() {
      _scanError.value = null;
      _status.value = ReceiptScanStatus.idle;
    });
    return false;
  }

  void _setScanFailure(Object error, {bool clearRetry = false}) {
    if (clearRetry) _setResendPayload(null, null);
    if (_cancelled) {
      _finishCancelled();
      return;
    }
    runInAction(() {
      _scanError.value = error;
      _status.value = ReceiptScanStatus.idle;
    });
  }

  // ── Review ────────────────────────────────────────────────────────────

  void toggleMatchedLine(String lineKey) {
    if (matchedCommitted || status != ReceiptScanStatus.reviewing) return;
    runInAction(() {
      if (!selectedLineKeys.remove(lineKey)) selectedLineKeys.add(lineKey);
    });
  }

  /// Sentinel như OcrStore.editItem: không truyền = giữ; truyền null = xoá.
  void editUnmatchedItem(
    String itemId, {
    String? name,
    Object? category = _notProvided,
    Object? quantity = _notProvided,
    Object? unit = _notProvided,
    Object? expiryDate = _notProvided,
  }) {
    final index = unmatchedItems.indexWhere((item) => item.itemId == itemId);
    if (index < 0) return;
    final item = unmatchedItems[index];
    if (item.isLocked) return;
    runInAction(() {
      unmatchedItems[index] = item.copyWith(
        name: name,
        category: identical(category, _notProvided) ? item.category : category,
        quantity: identical(quantity, _notProvided) ? item.quantity : quantity,
        unit: identical(unit, _notProvided) ? item.unit : unit,
        expiryDate: identical(expiryDate, _notProvided) ? item.expiryDate : expiryDate,
        confirmStatus: ReceiptConfirmStatus.pending,
        confirmError: null,
      );
    });
  }

  // ── Ghi ───────────────────────────────────────────────────────────────

  /// M-5 + Guard 12 — gọi từ nút "Thêm vào tồn kho"/"Thử lại" trên TỪNG thẻ.
  /// Trả true chỉ khi lần gọi NÀY vừa ghi thành công.
  Future<bool> confirmUnmatchedItem(String itemId) async {
    var index = unmatchedItems.indexWhere((item) => item.itemId == itemId);
    if (index < 0) return false;
    final item = unmatchedItems[index];
    // Guard 12: đã thêm hoặc đang thêm → KHÔNG gọi save() lần nữa. Kiểm và
    // đổi sang `confirming` ĐỒNG BỘ, trước await đầu tiên → double-tap chỉ
    // ghi 1 lần.
    if (item.isLocked) return false;
    if (!item.isValidForConfirm) {
      runInAction(
        () => unmatchedItems[index] =
            item.copyWith(confirmError: 'INVALID_RECEIPT_ITEM'),
      );
      return false;
    }
    runInAction(() {
      unmatchedItems[index] = item.copyWith(
        confirmStatus: ReceiptConfirmStatus.confirming,
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
        // #239: hạn gợi ý của BE (hoặc người dùng đã sửa).
        expiryDate: item.expiryDate,
        note: null,
      );
    } catch (_) {
      saved = false; // không để thẻ kẹt `confirming`
    }

    // Tính lại index sau await (reset() có thể đã xen vào).
    index = unmatchedItems.indexWhere((current) => current.itemId == itemId);
    if (index < 0) return saved;
    final current = unmatchedItems[index];
    runInAction(() {
      unmatchedItems[index] = saved
          ? current.copyWith(
              confirmStatus: ReceiptConfirmStatus.confirmed,
              confirmError: null,
            )
          : current.copyWith(
              confirmStatus: ReceiptConfirmStatus.failed,
              confirmError: formStore.saveError?.code ?? 'SAVE_FAILED',
            );
    });
    return saved;
  }

  /// "Thêm tất cả vào kho": thêm LẦN LƯỢT từng thẻ đủ thông tin qua đúng
  /// đường của [confirmUnmatchedItem] (ghi lạc quan, hàng đợi offline, khoá
  /// double-tap) — 1 thẻ lỗi không chặn thẻ sau. Trả số thẻ vừa thêm được.
  Future<int> confirmAllUnmatched() async {
    if (_bulkAdding.value) return 0;
    final ids = <String>[
      for (final item in unmatchedItems)
        if (!item.isLocked && item.isValidForConfirm) item.itemId,
    ];
    if (ids.isEmpty) return 0;
    runInAction(() => _bulkAdding.value = true);
    var added = 0;
    try {
      for (final id in ids) {
        if (await confirmUnmatchedItem(id)) added++;
      }
    } finally {
      runInAction(() => _bulkAdding.value = false);
    }
    return added;
  }

  /// Nút chung "Cập nhật danh sách mua sắm" — CHỈ matched (M-5). Chạy tối đa
  /// 1 lần mỗi kết quả quét (sau đó matchedCommitted = true, D7). Bị chặn →
  /// `ReceiptCommitResult.skipped()` (allSucceeded == false).
  Future<ReceiptCommitResult> commitMatched() async {
    if (!commitPending || status != ReceiptScanStatus.reviewing) {
      return const ReceiptCommitResult.skipped();
    }
    final priceById = _buildPriceById();
    runInAction(() => _status.value = ReceiptScanStatus.committing);
    // bulkCheck hứa không throw; vẫn chặn để status không kẹt `committing`
    // (PopScope + nút bị khoá) nếu sau này nó throw (L3).
    Set<String> failed;
    try {
      failed = (await _shoppingStore.bulkCheck(priceById)).toSet();
    } catch (_) {
      failed = priceById.keys.toSet();
    }
    runInAction(() {
      committedItemIds
        ..clear()
        ..addAll(priceById.keys.where((id) => !failed.contains(id)));
      failedItemIds
        ..clear()
        ..addAll(failed);
      _matchedCommitted.value = true;
      _status.value = ReceiptScanStatus.reviewing;
    });
    return ReceiptCommitResult(
      updatedCount: committedItemIds.length,
      failedCount: failedItemIds.length,
    );
  }

  /// M-7/M-8: nhóm dòng ĐÃ CHỌN theo shoppingItemId (mỗi id 1 lần).
  /// Giá nhóm = tổng totalPrice nếu MỌI dòng trong nhóm có totalPrice, hoá đơn
  /// là VND và tổng ≥ 0; ngược lại null (không gửi giá). Không bao giờ tự nhân
  /// unitPrice * quantity.
  Map<String, double?> _buildPriceById() {
    final linesById = <String, List<ReceiptMatchedItem>>{};
    for (final line in matchedItems) {
      if (!selectedLineKeys.contains(line.lineKey)) continue;
      linesById
          .putIfAbsent(line.shoppingItemId, () => <ReceiptMatchedItem>[])
          .add(line);
    }
    final isVnd = meta?.isVnd ?? false;
    return linesById.map((id, lines) {
      double? price;
      if (isVnd && lines.every((line) => line.totalPrice != null)) {
        final sum = lines.fold<double>(
          0,
          (total, line) => total + line.totalPrice!,
        );
        price = sum >= 0 ? sum : null;
      }
      return MapEntry(id, price);
    });
  }

  void reset() {
    _cancelled = false;
    _cancelToken = null;
    _lastPickSource = null;
    _setResendPayload(null, null);
    runInAction(() {
      _status.value = ReceiptScanStatus.idle;
      _scanError.value = null;
      _previewBytes.value = null;
      _clearResult();
    });
  }

  void _setResendPayload(Uint8List? bytes, String? key) {
    _compressedBytes = bytes;
    _idempotencyKey = key;
    runInAction(() => _canResend.value = bytes != null && key != null);
  }

  /// Gọi bên trong runInAction.
  void _clearResult() {
    _meta.value = null;
    _matchedCommitted.value = false;
    matchedItems.clear();
    unmatchedItems.clear();
    selectedLineKeys.clear();
    committedItemIds.clear();
    failedItemIds.clear();
  }
}

const Object _notProvided = Object();
