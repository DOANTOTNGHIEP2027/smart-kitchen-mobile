import 'dart:async';
import 'dart:math';

import 'package:mobx/mobx.dart';

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
  List<ShoppingItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading.value;
  ApiException? get error => _error.value;
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

  Future<void> toggle(ShoppingItem item) async {
    if (!item.canToggle) return;
    final next = item.copyWith(status: item.status == ShoppingItemStatus.pending ? ShoppingItemStatus.completed : ShoppingItemStatus.pending, syncStatus: ShoppingSyncStatus.pendingToggle, updatedAt: DateTime.now());
    await _dao.upsert(next);
    if (!await _online()) { await _dao.enqueueToggle(next, item); return; }
    try { await _dao.upsert((await _api.toggle(item.id, item.version, item.householdId)).copyWith(syncStatus: ShoppingSyncStatus.synced)); }
    on NetworkException { await _dao.enqueueToggle(next, item); }
    on ApiException catch (e) { await _dao.upsert(item); runInAction(() => _error.value = e); }
  }

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
        try {
          if (entry.operation == 'CREATE') {
            await _dao.remap(
              item.id,
              await _api.create(shoppingCreatePayload(item), householdId, idempotencyKey: item.id),
            );
          } else {
            await _dao.upsert(
              (await _api.toggle(item.id, entry.baseVersion!, householdId))
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
          break;
        } on ApiException {
          break;
        }
      }
    } finally {
      _draining = false;
    }
  }
  Future<bool> _online() async { try { return await _connectivity.isOnline(); } catch (_) { return true; } }
  Future<void> dispose() async { await _itemsSub?.cancel(); await _connectivitySub?.cancel(); }
}
