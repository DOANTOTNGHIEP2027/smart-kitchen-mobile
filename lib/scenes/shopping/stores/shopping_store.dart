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

/// stale = món vừa đổi ở nơi khác (tick lại được); itemDeleted = món đã bị xoá
/// ở máy khác; listClosed = danh sách đã sang tuần mới (OD-24).
enum PriceLostReason { stale, itemDeleted, listClosed }

class ShoppingStore {
  ShoppingStore({required ShoppingDao dao, required ShoppingApi api, required ConnectivityService connectivity, required SessionStore session, void Function()? onRosterStale})
      : _dao = dao, _api = api, _connectivity = connectivity, _session = session, _onRosterStale = onRosterStale;
  final ShoppingDao _dao; final ShoppingApi _api; final ConnectivityService _connectivity; final SessionStore _session;
  /// Gọi khi BE báo `ERR_SHOP_ASSIGNEE_INVALID` — roster cục bộ đã cũ (#134).
  final void Function()? _onRosterStale;
  StreamSubscription<List<ShoppingItem>>? _itemsSub;
  StreamSubscription<void>? _connectivitySub;
  bool _draining = false;
  final ObservableList<ShoppingItem> _items = ObservableList<ShoppingItem>();
  final Observable<bool> _loading = Observable(true);
  final Observable<ApiException?> _error = Observable(null);
  /// Lý do giá vừa nhập bị mất — 1 lần drain có thể có NHIỀU lý do cùng lúc.
  final ObservableSet<PriceLostReason> _priceLost = ObservableSet<PriceLostReason>();
  final Observable<String?> _rejectedCreateName = Observable(null);
  final ObservableSet<String> _assigningIds = ObservableSet<String>();
  final Observable<ApiException?> _assignError = Observable(null);
  /// Món nhận response PATCH gán trong lúc có `sync()` đang chạy — bản `list()`
  /// của sync đó có thể chụp TRƯỚC PATCH, không được lùi row về. Không chặn
  /// theo version cho MỌI món: server có thể trả version thấp hơn hợp lệ (Demo
  /// Mode reset fixture khi mở lại app, DB reseed) — chặn chung kẹt row cũ mãi.
  final Set<String> _assignedDuringSync = <String>{};
  int _syncsRunning = 0;
  List<ShoppingItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading.value;
  ApiException? get error => _error.value;
  /// AM-TB-4 (§12): 1 toggle MANG GIÁ bị server từ chối vì món đã đổi ở nơi
  /// khác — giá vừa nhập chưa được lưu, phải báo người dùng.
  bool get priceNotSaved => _priceLost.contains(PriceLostReason.stale);
  /// Giá mất vì món đã bị XOÁ ở máy khác (không còn món để tick lại) — câu
  /// báo khác [priceNotSaved] (OD-24).
  bool get priceLostItemDeleted => _priceLost.contains(PriceLostReason.itemDeleted);
  /// Danh sách đã sang tuần mới — món KHÔNG bị xoá, câu báo riêng (OD-24).
  bool get priceLostListClosed => _priceLost.contains(PriceLostReason.listClosed);
  /// Tên món thêm lúc offline bị server từ chối vĩnh viễn khi drain — row đã
  /// bị gỡ, phải báo người dùng (không im lặng mất món).
  String? get rejectedCreateName => _rejectedCreateName.value;
  /// Đang gửi PATCH gán cho món này — chặn bấm chồng.
  bool isAssigning(String itemId) => _assigningIds.contains(itemId);
  ApiException? get assignError => _assignError.value;

  /// Badge "Của tôi": món CHƯA MUA giao cho chính mình — tính CỤC BỘ từ Drift,
  /// không đọc `assignedToMeCount` của server (§9.5, Guard #16).
  int get assignedToMeCount {
    final me = _session.currentUser?.id;
    if (me == null) return 0;
    return _items.where((e) => e.isAssignedTo(me) && e.status == ShoppingItemStatus.pending).length;
  }

  List<ShoppingItem> get pending => _items.where((e) => e.status == ShoppingItemStatus.pending).toList();
  List<ShoppingItem> get completed => _items.where((e) => e.status == ShoppingItemStatus.completed).toList();

  /// Household đang nghe Drift — store `permanent` sống qua logout/đổi household.
  String? _boundHousehold;
  bool _bound = false;
  ReactionDisposer? _householdReaction;

  /// Idempotent theo household: cùng household → no-op; household đổi (kể cả
  /// logout → login tài khoản khác) → huỷ luồng cũ, xoá dữ liệu cũ, nghe lại.
  /// Không huỷ thì luồng household cũ vẫn ghi đè `_items` (lộ dữ liệu).
  Future<void> init() async {
    _householdReaction ??= reaction<String?>((_) => _session.householdId, (_) => unawaited(init()));
    final householdId = _session.householdId;
    if (_bound && householdId == _boundHousehold) return;
    final oldItems = _itemsSub, oldConn = _connectivitySub;
    _itemsSub = null; _connectivitySub = null;
    _bound = true; _boundHousehold = householdId;
    runInAction(() {
      _items.clear(); _assigningIds.clear();
      _error.value = null; _assignError.value = null; _priceLost.clear(); _rejectedCreateName.value = null;
      _loading.value = householdId != null;
    });
    unawaited(oldItems?.cancel()); unawaited(oldConn?.cancel());
    if (householdId == null) return;
    _itemsSub = _dao.watchAll(householdId).listen((rows) => runInAction(() { _items..clear()..addAll(rows); _loading.value = false; }));
    _connectivitySub = _connectivity.onConnectivityRestored.listen((_) => unawaited(sync()));
    unawaited(sync());
  }

  Future<bool> add(String name, double quantity, String unit, {String? category}) async {
    final householdId = _session.householdId; if (householdId == null || name.trim().isEmpty || quantity <= 0) return false;
    runInAction(() => _rejectedCreateName.value = null);
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
    runInAction(_priceLost.clear);
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
      // §10: món không còn ở server / danh sách đã sang tuần mới — rollback
      // không áp dụng, xoá row (như drain).
      if (_isGone(e)) { await _dao.delete(item.id); if (sentPrice != null) _markPriceLost(_goneReason(e), item.householdId); return; }
      await _dao.upsert(item); runInAction(() => _error.value = e);
      if (_isStaleToggle(e)) { if (sentPrice != null) _markPriceLost(PriceLostReason.stale, item.householdId); await sync(); }
    }
  }

  /// 409 version lệch, hoặc 400 vì BE kiểm "giá chỉ hợp lệ khi COMPLETED"
  /// TRƯỚC version (món đã được tick ở nơi khác) ⇒ thao tác cũ hết đúng: bỏ +
  /// refetch (D6), KHÔNG retry mãi.
  static bool _isStaleToggle(ApiException e) =>
      e.code == 'ERR_SHOP_ITEM_VERSION_CONFLICT' || e.code == 'ERR_VALIDATION_FAILED';

  /// Gán / bỏ gán (`assigneeId == null`) — ONLINE-ONLY, KHÔNG optimistic
  /// (§9.5). Chỉ chạy trên row đã SYNCED (Guard #18): ghi đè row đang
  /// PENDING_TOGGLE sẽ xoá mất lần tick của người dùng.
  Future<bool> assign(ShoppingItem item, {required String? assigneeId}) async {
    // Chiếm chỗ ĐỒNG BỘ trước mọi await — kiểm sau await thì 2 lần gọi sát
    // nhau đều lọt qua, gửi 2 PATCH cùng version (lần sau ăn 409 giả).
    if (_assigningIds.contains(item.id)) return false;
    runInAction(() {
      _assignError.value = null;
      _assigningIds.add(item.id);
    });
    try {
      final current = await _dao.getById(item.id);
      if (current == null || current.syncStatus != ShoppingSyncStatus.synced) return false;
      if (!await _online()) return false;
      final server = await _api.assign(current.id, current.version, current.householdId, assigneeId: assigneeId);
      // Guard #18 lần 3: row đã thành PENDING_* trong lúc PATCH bay — ghi đè
      // sẽ xoá lần tick; để sync() kế tiếp hoà giải.
      if ((await _dao.getById(item.id))?.syncStatus != ShoppingSyncStatus.synced) return true;
      // Đánh dấu TRƯỚC khi ghi — vòng lặp của sync() có thể đọc row ngay sau upsert.
      if (_syncsRunning > 0) _assignedDuringSync.add(item.id);
      await _dao.upsert(server.copyWith(syncStatus: ShoppingSyncStatus.synced));
      return true;
    } on BusinessException catch (e) {
      runInAction(() => _assignError.value = e);
      if (e.code == 'ERR_SHOP_ASSIGNEE_INVALID') _onRosterStale?.call();
      if (e.code == 'ERR_SHOP_ITEM_VERSION_CONFLICT') await sync();
      return false;
    } on ApiException catch (e) {
      runInAction(() => _assignError.value = e);
      return false;
    } finally {
      runInAction(() => _assigningIds.remove(item.id));
    }
  }

  void clearAssignError() => runInAction(() => _assignError.value = null);

  Future<void> sync() async {
    final householdId = _session.householdId; if (householdId == null) return;
    await _drain(householdId);
    _syncsRunning++;
    try {
      // Chụp row SYNCED TRƯỚC khi gửi list(): chỉ những row này mới được xoá
      // khi server không trả. Row thành SYNCED trong lúc list() bay (remap của
      // add() online / drain của sync khác) không có trong bản chụp server.
      final syncedBefore = <String>{for (final l in await _dao.getAll(householdId)) if (!l.isPendingSync) l.id};
      final serverItems = await _api.list(householdId);
      final seen = <String>{for (final i in serverItems) i.id};
      for (final item in serverItems) { final local = await _dao.getById(item.id); if (local == null || (!local.isPendingSync && !(_assignedDuringSync.contains(item.id) && item.version < local.version))) await _dao.upsert(item); }
      // Reconcile (§16 #16): row đã SYNCED mà server không còn trả (bị xoá ở
      // máy khác / danh sách sang tuần mới) → xoá cục bộ. Row PENDING_* giữ
      // nguyên để drain xử lý.
      for (final local in await _dao.getAll(householdId)) {
        if (!local.isPendingSync && syncedBefore.contains(local.id) && !seen.contains(local.id)) await _dao.delete(local.id);
      }
    }
    // Household đổi trong lúc sync bay → lỗi của household cũ không được hiện ở household mới.
    on ApiException catch (e) { if (_session.householdId == householdId) runInAction(() => _error.value = e); }
    finally { if (--_syncsRunning == 0) _assignedDuringSync.clear(); }
  }
  Future<void> _drain(String householdId) async {
    if (_draining) {
      return;
    }
    _draining = true;
    var requeued = false;
    try {
      for (final entry in await _dao.queue(householdId)) {
        // Household đổi giữa chừng (vd. logout → tài khoản khác) — token mới bị
        // từ chối sẽ khiến entry household cũ bị xoá nhầm; dừng, giữ queue.
        if (_session.householdId != householdId) break;
        // Bản chụp hàng đợi có thể cũ: entry đã bị huỷ cặp trong lúc drain gửi
        // entry trước — gửi nó sẽ toggle server ngược ý người dùng.
        if (!await _dao.hasQueueEntry(entry.id)) continue;
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
            final server = (await _api.toggle(item.id, entry.baseVersion!, householdId,
                    price: queuedPrice))
                .copyWith(syncStatus: ShoppingSyncStatus.synced);
            // Race: người dùng bỏ tick (huỷ cặp, xoá entry) ĐÚNG lúc entry này
            // đang bay → server đã nhận T1, ngược ý muốn. Xếp 1 toggle đảo lại
            // từ state server để server khớp ý người dùng ở lần drain kế.
            if (!await _dao.hasQueueEntry(entry.id)) {
              final revert = server.copyWith(
                status: server.status == ShoppingItemStatus.completed
                    ? ShoppingItemStatus.pending
                    : ShoppingItemStatus.completed,
                syncStatus: ShoppingSyncStatus.pendingToggle,
              );
              await _dao.upsert(revert);
              await _dao.enqueueToggle(revert, server);
              requeued = true;
              continue;
            }
            await _dao.upsert(server);
          }
          await _dao.removeQueue(entry.id);
        } on BusinessException catch (e) {
          if (_session.householdId != householdId) break;
          // #55: cùng key nhưng nội dung khác — không tự retry, báo người dùng.
          // Bản đã tạo ở lần gửi đầu sẽ về qua list ở bước sync kế tiếp.
          if (e.code == 'ERR_IDEMPOTENCY_KEY_REUSED') {
            runInAction(() => _error.value = e);
            await _dao.removeQueue(entry.id);
            await _dao.delete(item.id);
            continue;
          }
          // CREATE bị từ chối vĩnh viễn (vd. đơn vị không hợp lệ, mất quyền) —
          // retry không bao giờ thành, giữ lại sẽ chặn MỌI entry phía sau.
          // Chỉ `ERR_IDEMPOTENCY_IN_PROGRESS` là tạm thời (request trước còn chạy).
          if (entry.operation == 'CREATE' && e.code != 'ERR_IDEMPOTENCY_IN_PROGRESS') {
            await _dropCreate(entry, item, e);
            continue;
          }
          if (await _dropStaleToggle(entry, item, e, queuedPrice)) continue;
          break;
        } on ValidationException catch (e) {
          if (_session.householdId != householdId) break;
          if (entry.operation == 'CREATE') {
            await _dropCreate(entry, item, e);
            continue;
          }
          if (await _dropStaleToggle(entry, item, e, queuedPrice)) continue;
          break;
        } on ApiException catch (e) {
          if (_session.householdId != householdId) break;
          if (await _dropStaleToggle(entry, item, e, queuedPrice)) continue;
          break;
        }
      }
    } finally {
      _draining = false;
    }
    // Lần drain của household mới đã bị cờ `_draining` chặn — chạy bù.
    final now = _session.householdId;
    if (now != null && now != householdId) { await _drain(now); return; }
    // Toggle đảo lại vừa xếp không nằm trong bản chụp hàng đợi ở trên — gửi
    // ngay, không chờ lần sync kế (có thể rất lâu nếu không có sự kiện nào).
    if (requeued) await _drain(householdId);
  }
  Future<void> _dropCreate(ShoppingSyncQueueEntry entry, ShoppingItem item, ApiException e) async {
    runInAction(() {
      _error.value = e;
      _rejectedCreateName.value = item.name;
    });
    await _dao.removeQueue(entry.id);
    await _dao.delete(item.id);
  }

  /// AM-TB-4: entry toggle bị từ chối vì món đã đổi → bỏ entry, đưa row về
  /// SYNCED để `list()` ngay sau đó ghi đè bằng bản server; mất giá thì báo.
  Future<bool> _dropStaleToggle(ShoppingSyncQueueEntry entry, ShoppingItem item, ApiException e, double? queuedPrice) async {
    if (entry.operation == 'CREATE') return false;
    // Món không còn (xoá ở máy khác) / danh sách đã sang tuần mới: entry vô
    // nghĩa — bỏ, xoá row cục bộ, KHÔNG kẹt hàng đợi (OD-20).
    if (_isGone(e)) {
      await _dao.removeQueue(entry.id);
      await _dao.delete(item.id);
      if (queuedPrice != null) _markPriceLost(_goneReason(e), item.householdId);
      return true;
    }
    if (!_isStaleToggle(e)) return false;
    await _dao.removeQueue(entry.id);
    await _dao.upsert(item.copyWith(syncStatus: ShoppingSyncStatus.synced));
    if (queuedPrice != null) _markPriceLost(PriceLostReason.stale, item.householdId);
    return true;
  }
  /// Household đổi trong lúc request bay → không báo mất giá của household cũ ở household mới.
  void _markPriceLost(PriceLostReason r, String householdId) {
    if (_session.householdId == householdId) runInAction(() => _priceLost.add(r));
  }
  static bool _isGone(ApiException e) => e.code == 'ERR_SHOP_ITEM_NOT_FOUND' || e.code == 'ERR_SHOP_LIST_NOT_ACTIVE';
  static PriceLostReason _goneReason(ApiException e) =>
      e.code == 'ERR_SHOP_LIST_NOT_ACTIVE' ? PriceLostReason.listClosed : PriceLostReason.itemDeleted;
  Future<bool> _online() async { try { return await _connectivity.isOnline(); } catch (_) { return true; } }
  Future<void> dispose() async { _householdReaction?.call(); _householdReaction = null; _bound = false; await _itemsSub?.cancel(); await _connectivitySub?.cancel(); }
}
