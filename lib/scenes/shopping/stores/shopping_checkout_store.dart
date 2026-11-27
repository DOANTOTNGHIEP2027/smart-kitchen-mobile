import 'dart:convert';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../services/connectivity_service.dart';
import '../../../utils/uuid.dart';
import '../../../widgets/states/view_state.dart';
import '../../inventory/data/inventory_batch_api.dart';
import '../../inventory/domain/unit_option.dart';
import '../data/checkout_api.dart';
import '../domain/checkout_preview_item.dart';

/// Mã 409 khiến danh sách xem trước không còn đúng — tải lại rồi báo (#239 F5).
const Set<String> _staleCodes = <String>{
  'ERR_SHOP_ITEM_VERSION_CONFLICT',
  'ERR_SHOP_ITEM_ALREADY_IN_INVENTORY',
  'ERR_SHOP_ITEM_NOT_BOUGHT',
  'ERR_SHOP_LIST_NOT_ACTIVE',
  'ERR_SHOP_ITEM_NOT_FOUND',
};

/// Màn "Cất vào kho" (#239, thiết kế FE §4). Chỉ chạy khi có mạng (F1) — không
/// có hàng đợi offline: batch all-or-nothing, phát lại muộn dễ ghi sai tuần.
class ShoppingCheckoutStore {
  ShoppingCheckoutStore({
    required CheckoutApi api,
    required InventoryBatchApi batchApi,
    required ConnectivityService connectivity,
    Future<void> Function()? onCommitted,
    String Function()? idempotencyKeyGenerator,
  })  : _api = api,
        _batchApi = batchApi,
        _connectivity = connectivity,
        _onCommitted = onCommitted,
        _newKey = idempotencyKeyGenerator ?? createUuidV4;

  final CheckoutApi _api;
  final InventoryBatchApi _batchApi;
  final ConnectivityService _connectivity;
  final Future<void> Function()? _onCommitted;
  final String Function() _newKey;

  final ObservableList<CheckoutPreviewItem> items = ObservableList<CheckoutPreviewItem>();
  final Observable<bool> _loading = Observable<bool>(true);
  final Observable<ApiException?> _loadError = Observable<ApiException?>(null);
  final Observable<bool> _submitting = Observable<bool>(false);
  final Observable<ApiException?> _submitError = Observable<ApiException?>(null);

  /// `shoppingItemId` của các dòng BE báo lỗi ở lần gửi gần nhất (F6).
  final ObservableSet<String> errorRowIds = ObservableSet<String>();

  /// F2: một key cho một nội dung gửi — bấm lại sau lỗi mạng dùng lại key, sửa
  /// gì đó rồi gửi thì sinh key mới (cùng key khác body BE trả 422).
  String? _key;
  String? _keyBody;

  bool get loading => _loading.value;
  bool get submitting => _submitting.value;
  ApiException? get submitError => _submitError.value;
  bool get isOnline => _connectivity.isOnlineNow;

  ViewState<List<CheckoutPreviewItem>> get state {
    if (_loading.value) return const LoadingState();
    final error = _loadError.value;
    if (error != null) return ErrorState(error);
    if (items.isEmpty) return const EmptyState();
    return SuccessState(items.toList(growable: false));
  }

  List<CheckoutPreviewItem> get selected => items.where((i) => i.selected).toList();
  int get selectedCount => items.where((i) => i.selected).length;

  /// Dòng đã chọn mà số lượng/đơn vị chưa hợp lệ (quả/cái phải là số nguyên).
  bool isRowValid(CheckoutPreviewItem item) {
    if (item.quantity <= 0) return false;
    final option = unitOptions.where((o) => o.value == item.unit);
    if (option.isEmpty) return false;
    return !option.first.isWholeNumber || item.quantity % 1 == 0;
  }

  bool get canSubmit =>
      !_submitting.value && isOnline && selectedCount > 0 && selected.every(isRowValid);

  /// Tải preview. Lần tải lại giữ phần người dùng đã sửa theo `shoppingItemId`.
  Future<void> load() async {
    final edits = <String, CheckoutPreviewItem>{for (final i in items) i.shoppingItemId: i};
    runInAction(() {
      _loading.value = true;
      _loadError.value = null;
    });
    try {
      final fresh = await _api.preview();
      runInAction(() {
        items
          ..clear()
          ..addAll(fresh.map((f) => _mergeEdits(f, edits[f.shoppingItemId])));
        _loading.value = false;
      });
    } on ApiException catch (e) {
      runInAction(() {
        _loadError.value = e;
        _loading.value = false;
      });
    }
  }

  CheckoutPreviewItem _mergeEdits(CheckoutPreviewItem fresh, CheckoutPreviewItem? old) {
    if (old == null) return fresh;
    return fresh.copyWith(
      selected: old.selected,
      quantity: old.quantity,
      unit: old.unit,
      expiryDate: old.expiryEdited ? old.expiryDate : fresh.expiryDate,
      expiryEdited: old.expiryEdited,
    );
  }

  void toggleSelected(String id) => _update(id, (i) => i.copyWith(selected: !i.selected));

  void setExpiry(String id, DateTime? date) =>
      _update(id, (i) => i.copyWith(expiryDate: date, expiryEdited: true));

  void setQuantity(String id, double quantity) => _update(id, (i) => i.copyWith(quantity: quantity));

  void setUnit(String id, String unit) => _update(id, (i) => i.copyWith(unit: unit));

  void clearSubmitError() => runInAction(() => _submitError.value = null);

  void _update(String id, CheckoutPreviewItem Function(CheckoutPreviewItem) change) {
    runInAction(() {
      final index = items.indexWhere((i) => i.shoppingItemId == id);
      if (index < 0) return;
      items[index] = change(items[index]);
      errorRowIds.remove(id);
    });
  }

  /// Gửi batch. Trả số lô đã tạo, hoặc `null` khi thất bại ([submitError]).
  Future<int?> submit() async {
    if (!canSubmit) return null;
    final rows = selected;
    final payload = rows.map((r) => r.toBatchPayload()).toList(growable: false);
    final body = jsonEncode(payload);
    if (_key == null || _keyBody != body) {
      _key = _newKey();
      _keyBody = body;
    }
    runInAction(() {
      _submitting.value = true;
      _submitError.value = null;
      errorRowIds.clear();
    });
    try {
      final created = await _batchApi.batchCreate(payload, idempotencyKey: _key!);
      _key = null;
      _keyBody = null;
      await _onCommitted?.call();
      runInAction(() => _submitting.value = false);
      return created.length;
    } on ApiException catch (e) {
      runInAction(() {
        _submitting.value = false;
        _submitError.value = e;
        for (final index in batchErrorRows(e)) {
          if (index >= 0 && index < rows.length) errorRowIds.add(rows[index].shoppingItemId);
        }
      });
      if (_staleCodes.contains(e.code)) {
        _key = null;
        _keyBody = null;
        await load();
      }
      return null;
    }
  }
}
