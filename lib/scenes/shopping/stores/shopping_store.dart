import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mobx/mobx.dart';

import '../../../data/db/app_database.dart';
import '../../../data/network/api_exception.dart';
import '../../../services/connectivity_service.dart';
import '../../../stores/session_store.dart';
import '../data/shopping_api.dart';
import '../data/shopping_dao.dart';
import '../data/shopping_mapper.dart';
import '../domain/shopping_item.dart';

class ShoppingStore {
  ShoppingStore({required ShoppingDao dao, required ShoppingApi api, required ConnectivityService connectivity, required SessionStore session})
      : _dao = dao, _api = api, _connectivity = connectivity, _session = session;
  final ShoppingDao _dao; final ShoppingApi _api; final ConnectivityService _connectivity; final SessionStore _session;
  StreamSubscription<List<ShoppingItem>>? _itemsSub;
  StreamSubscription<void>? _connectivitySub;
  bool _draining = false;
  final ObservableList<ShoppingItem> _items = ObservableList<ShoppingItem>();
  final Observable<bool> _loading = Observable(true);
  final Observable<ApiException?> _error = Observable(null);
  final Observable<bool> _priceNotSaved = Observable(false);
  List<ShoppingItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading.value;
  ApiException? get error => _error.value;
  /// AM-TB-4 (§12): 1 toggle MANG GIÁ bị server từ chối vì món đã đổi ở nơi
  /// khác — giá vừa nhập chưa được lưu, phải báo người dùng.
  bool get priceNotSaved => _priceNotSaved.value;
  List<ShoppingItem> get pending => _items.where((e) => e.status == ShoppingItemStatus.pending).toList();
  List<ShoppingItem> get completed => _items.where((e) => e.status == ShoppingItemStatus.completed).toList();

  Future<void> init() async {
    final householdId = _session.householdId;
    if (householdId == null) { runInAction(() => _loading.value = false); return; }
    _itemsSub = _dao.watchAll(householdId).listen((rows) => runInAction(() { _items..clear()..addAll(rows); _loading.value = false; }));
    _connectivitySub = _connectivity.onConnectivityRestored.listen((_) => unawaited(sync()));
    unawaited(sync());
  }

  Future<bool> add(String name, double quantity, String unit, {String? category}) async {
    final householdId = _session.householdId; if (householdId == null || name.trim().isEmpty || quantity <= 0) return false;
    final now = DateTime.now();
    final local = ShoppingItem(id: 'local-${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}', householdId: householdId, name: name.trim(), quantity: quantity, unit: unit, displayQuantity: quantity, displayUnit: unit, category: category?.trim().isEmpty == true ? null : category?.trim(), status: ShoppingItemStatus.pending, source: ShoppingItemSource.manual, version: 0, createdBy: _session.currentUser?.id, createdAt: now, updatedAt: now, syncStatus: ShoppingSyncStatus.pendingCreate);
    await _dao.upsert(local);
    if (!await _online()) { await _dao.enqueueCreate(local); return true; }
    // #55: id tạm là idempotency key — lần phát lại từ queue dùng đúng id này.
    try { await _dao.remap(local.id, await _api.create(shoppingCreatePayload(local), householdId, idempotencyKey: local.id)); return true; }
    on NetworkException { await _dao.enqueueCreate(local); return true; }
    on ApiException catch (e) { await _dao.delete(local.id); runInAction(() => _error.value = e); return false; }
  }

  /// [price] chỉ có nghĩa ở chiều PENDING → COMPLETED (#133); chiều ngược bỏ
  /// qua để không gửi `price` khi BE sẽ từ chối.
  Future<void> toggle(ShoppingItem item, {double? price}) async {
    if (!item.canToggle) return;
    runInAction(() => _priceNotSaved.value = false);
    final completing = item.status == ShoppingItemStatus.pending;
    final sentPrice = completing ? price : null;
    final next = item.copyWith(status: completing ? ShoppingItemStatus.completed : ShoppingItemStatus.pending, syncStatus: ShoppingSyncStatus.pendingToggle, updatedAt: DateTime.now(), price: sentPrice);
    await _dao.upsert(next);
    // Row đang PENDING_TOGGLE = còn entry chờ gửi: phải đi qua hàng đợi (huỷ
    // cặp), gọi thẳng API sẽ toggle server theo state CŨ — ngược chiều ý muốn.
    if (item.syncStatus == ShoppingSyncStatus.pendingToggle || !await _online()) { await _dao.enqueueToggle(next, item, price: sentPrice); return; }
    try { await _dao.upsert((await _api.toggle(item.id, item.version, item.householdId, price: sentPrice)).copyWith(syncStatus: ShoppingSyncStatus.synced)); }
    on NetworkException { await _dao.enqueueToggle(next, item, price: sentPrice); }
    on ApiException catch (e) {
      await _dao.upsert(item); runInAction(() => _error.value = e);
      if (_isStaleToggle(e)) { if (sentPrice != null) runInAction(() => _priceNotSaved.value = true); await sync(); }
    }
  }

  /// 409 version lệch, hoặc 400 vì BE kiểm "giá chỉ hợp lệ khi COMPLETED"
  /// TRƯỚC version (món đã được tick ở nơi khác) ⇒ thao tác cũ hết đúng: bỏ +
  /// refetch (D6), KHÔNG retry mãi.
  static bool _isStaleToggle(ApiException e) =>
      e.code == 'ERR_SHOP_ITEM_VERSION_CONFLICT' || e.code == 'ERR_VALIDATION_FAILED';

  Future<void> sync() async {
    final householdId = _session.householdId; if (householdId == null) return;
    await _drain(householdId);
    try { for (final item in await _api.list(householdId)) { final local = await _dao.getById(item.id); if (local == null || !local.isPendingSync) await _dao.upsert(item); } }
    on ApiException catch (e) { runInAction(() => _error.value = e); }
  }
  Future<void> _drain(String householdId) async {
    if (_draining) {
      return;
    }
    _draining = true;
    try {
      for (final entry in await _dao.queue(householdId)) {
        final item = await _dao.getById(entry.itemId);
        if (item == null) {
          await _dao.removeQueue(entry.id);
          continue;
        }
        final queuedPrice = entry.operation == 'CREATE'
            ? null
            : ((jsonDecode(entry.payload) as Map<String, dynamic>)['price'] as num?)?.toDouble();
        try {
          if (entry.operation == 'CREATE') {
            await _dao.remap(
              item.id,
              await _api.create(shoppingCreatePayload(item), householdId, idempotencyKey: item.id),
            );
          } else {
            await _dao.upsert(
              (await _api.toggle(item.id, entry.baseVersion!, householdId,
                      price: queuedPrice))
                  .copyWith(syncStatus: ShoppingSyncStatus.synced),
            );
          }
          await _dao.removeQueue(entry.id);
        } on BusinessException catch (e) {
          // #55: cùng key nhưng nội dung khác — không tự retry, báo người dùng.
          // Bản đã tạo ở lần gửi đầu sẽ về qua list ở bước sync kế tiếp.
          if (e.code == 'ERR_IDEMPOTENCY_KEY_REUSED') {
            runInAction(() => _error.value = e);
            await _dao.removeQueue(entry.id);
            await _dao.delete(item.id);
            continue;
          }
          if (await _dropStaleToggle(entry, item, e, queuedPrice)) continue;
          break;
        } on ApiException catch (e) {
          if (await _dropStaleToggle(entry, item, e, queuedPrice)) continue;
          break;
        }
      }
    } finally {
      _draining = false;
    }
  }
  /// AM-TB-4: entry toggle bị từ chối vì món đã đổi → bỏ entry, đưa row về
  /// SYNCED để `list()` ngay sau đó ghi đè bằng bản server; mất giá thì báo.
  Future<bool> _dropStaleToggle(ShoppingSyncQueueEntry entry, ShoppingItem item, ApiException e, double? queuedPrice) async {
    if (entry.operation == 'CREATE' || !_isStaleToggle(e)) return false;
    await _dao.removeQueue(entry.id);
    await _dao.upsert(item.copyWith(syncStatus: ShoppingSyncStatus.synced));
    if (queuedPrice != null) runInAction(() => _priceNotSaved.value = true);
    return true;
  }
  Future<bool> _online() async { try { return await _connectivity.isOnline(); } catch (_) { return true; } }
  Future<void> dispose() async { await _itemsSub?.cancel(); await _connectivitySub?.cancel(); }
}
