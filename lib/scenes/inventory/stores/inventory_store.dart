import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/realtime/ws_event_envelope.dart';
import '../../../stores/household_scoped.dart';
import '../../../stores/session_store.dart';
import '../../../services/connectivity_service.dart';
import '../data/inventory_api.dart';
import '../data/inventory_dao.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_mapper.dart';
import '../domain/sync_status.dart';

/// Trạng thái danh sách inventory — chỉ loading|ready (FE-5 §9.1, Decision D13).
///
/// Offline-first có nghĩa là всегда có dữ liệu local; KO dùng [ViewState] cũ
/// vì model đó ý "lỗi = không có gì hiển thị" — sai với cache-first.
enum InventoryLoadStatus { loading, ready }

/// State + actions cho `InventoryListScene` (FE-5 §9).
///
/// Bám pattern thủ công MobX của profile_store (Observable + runInAction) —
/// không codegen để giữ code phẳng và dễ đọc cho scope 3 ngày công này.
class InventoryStore with HouseholdScoped {
  InventoryStore({
    required InventoryDao dao,
    required InventoryApi api,
    required ConnectivityService connectivity,
    required SessionStore sessionStore,
  })  : _dao = dao,
        _api = api,
        _connectivity = connectivity,
        _session = sessionStore;

  final InventoryDao _dao;
  final InventoryApi _api;
  final ConnectivityService _connectivity;
  final SessionStore _session;

  StreamSubscription<List<InventoryItemModel>>? _dbSub;
  StreamSubscription<void>? _connectivitySub;
  bool _isDrainingQueue = false;

  final Observable<InventoryLoadStatus> _status =
      Observable<InventoryLoadStatus>(InventoryLoadStatus.loading);
  final ObservableList<InventoryItemModel> _items =
      ObservableList<InventoryItemModel>();
  final Observable<String> _searchQuery = Observable<String>('');
  final Observable<String?> _selectedCategory = Observable<String?>(null);
  final Observable<bool> _isSyncing = Observable<bool>(false);
  final Observable<ApiException?> _syncError = Observable<ApiException?>(null);

  /// Bounded LRU cho event id (at-least-once delivery từ BE — §9.3).
  final Set<String> _seenEventIds = <String>{};
  static const int _maxSeenEvents = 200;

  // ── Getters ──────────────────────────────────────────────────────────────

  InventoryLoadStatus get status => _status.value;
  List<InventoryItemModel> get items => List.unmodifiable(_items);
  String get searchQuery => _searchQuery.value;
  String? get selectedCategory => _selectedCategory.value;
  bool get isSyncing => _isSyncing.value;
  ApiException? get syncError => _syncError.value;

  /// Filter + search được tính lại tại mỗi lần [_items] đổi (FE-5 §9).
  List<InventoryItemModel> get filteredItems {
    final q = _searchQuery.value.toLowerCase();
    final cat = _selectedCategory.value;
    return _items.where((i) {
      final matchesSearch = q.isEmpty || i.name.toLowerCase().contains(q);
      final matchesCategory = cat == null || i.category == cat;
      return matchesSearch && matchesCategory;
    }).toList(growable: false);
  }

  List<String> get knownCategories =>
      _items.map((i) => i.category).whereType<String>().toSet().toList()
        ..sort();

  String? get householdId => _session.householdId;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Subscribe local Drift stream + trigger initial syncFromServer.
  /// KHÔNG chờ network — `status` chuyển `ready` ngay tại emission đầu tiên
  /// của Drift, kể cả khi list rỗng (§9.2).
  ///
  /// Idempotent theo household (store `permanent` sống qua logout/đổi
  /// household): cùng household → no-op; household đổi → huỷ luồng cũ, xoá dữ
  /// liệu + bộ lọc cũ rồi nghe lại. Không huỷ thì luồng household cũ vẫn ghi
  /// đè `_items` (lộ dữ liệu household trước).
  Future<void> init() async {
    if (!rebindHousehold(_session, () => unawaited(init()))) return;
    final hid = _session.householdId;
    final oldDb = _dbSub, oldConn = _connectivitySub;
    _dbSub = null;
    _connectivitySub = null;
    _seenEventIds.clear();
    runInAction(() {
      _items.clear();
      _searchQuery.value = '';
      _selectedCategory.value = null;
      _syncError.value = null;
      _isSyncing.value = false;
      _status.value =
          hid == null ? InventoryLoadStatus.ready : InventoryLoadStatus.loading;
    });
    unawaited(oldDb?.cancel());
    unawaited(oldConn?.cancel());
    if (hid == null) {
      return; // §12 Failure modes — không có household thì empty state
    }

    _dbSub = _dao.watchAllItems(hid).listen((rows) {
      runInAction(() {
        _items
          ..clear()
          ..addAll(rows);
        _status.value = InventoryLoadStatus.ready;
      });
    });
    _connectivitySub = _connectivity.onConnectivityRestored.listen((_) {
      unawaited(_syncAfterConnectivityRestored());
    });

    // Background sync — không chặn UI. Không đổi status (Drift sẽ emit).
    unawaited(_syncAfterConnectivityRestored());
  }

  Future<void> dispose() async {
    unbindHousehold();
    await _dbSub?.cancel();
    _dbSub = null;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void setSearchQuery(String q) => runInAction(() => _searchQuery.value = q);

  void setCategory(String? cat) =>
      runInAction(() => _selectedCategory.value = cat);

  Future<void> clearSyncError() async {
    runInAction(() => _syncError.value = null);
  }

  /// Pull-to-refresh & reconnect catchup. KHÔNG ghi đè item đang PENDING_*
  /// cục bộ (FE-5 §9.4 — Implementation Guard 4).
  Future<void> syncFromServer() async {
    final hid = _session.householdId;
    if (hid == null) return;
    final epoch = householdEpoch;

    runInAction(() {
      _isSyncing.value = true;
      _syncError.value = null;
    });
    try {
      final seenIds = <String>{};
      var page = 0;
      const maxPages = 5; // safety cap 500 item (open-questions Q5)
      bool? gotFullSet;
      while (page < maxPages) {
        final result = await _api.list(page: page, size: 100);
        // Household đổi giữa chừng → trang sau lấy bằng token mới; dừng.
        if (isStaleEpoch(epoch)) break;
        for (final serverItem in result.items) {
          final local = await _dao.getById(serverItem.id);
          if (local == null || local.syncStatus == SyncStatus.synced) {
            await _dao.upsertItem(serverItem);
          }
          seenIds.add(serverItem.id);
        }
        if (page >= result.totalPages - 1) {
          gotFullSet = true;
          break;
        }
        page++;
      }
      // Chỉ reconcile-xóa khi đã tải đủ toàn bộ set; tránh false-positive.
      // Household đổi trong lúc sync bay → `_items` đã là household mới, xoá
      // theo `seenIds` cũ sẽ xoá nhầm row household mới.
      // So epoch (không so householdId): A→B→A trong lúc sync thì id khớp lại
      // nhưng các trang sau đã lấy bằng token của B (OD-33).
      if (gotFullSet == true && !isStaleEpoch(epoch)) {
        await _reconcileDeletes(seenIds, hid);
      }
    } on ApiException catch (e) {
      if (!isStaleEpoch(epoch)) runInAction(() => _syncError.value = e);
    } catch (e) {
      // Bất ngờ — log và làm như mọi ApiException.
      developer.log('syncFromServer lỗi ngoài dự kiến: $e',
          name: 'InventoryStore');
      if (!isStaleEpoch(epoch)) {
        runInAction(() =>
            _syncError.value = ServerException('ERR_UNKNOWN', e.toString()));
      }
    } finally {
      // Sync household cũ về muộn không được tắt cờ của sync household mới.
      if (!isStaleEpoch(epoch)) {
        runInAction(() => _isSyncing.value = false);
      }
    }
  }

  /// Gửi lại mutation offline theo đúng thứ tự sau khi có mạng. Queue lưu trên
  /// SQLite nên không mất khi app bị đóng trước lúc reconnect.
  Future<void> drainSyncQueue() async {
    if (_isDrainingQueue) return;
    final hid = _session.householdId;
    if (hid == null) return;

    _isDrainingQueue = true;
    final epoch = householdEpoch;
    try {
      final operations = await _dao.queuedOperations(hid);
      for (final operation in operations) {
        // Household đổi giữa chừng → token đã thuộc household mới; gửi tiếp
        // queue household cũ sẽ tạo/sửa nhầm sang household mới.
        if (isStaleEpoch(epoch)) break;
        final local = await _dao.getById(operation.itemId);
        if (local == null) {
          await _dao.removeQueuedOperation(operation.id);
          continue;
        }
        final metadata = inventoryMutationMetadataFromQueue(
          operation.deleteReason,
          operation: operation.operation,
        );
        try {
          switch (operation.operation) {
            case 'CREATE':
              // #55: id tạm của row PENDING_CREATE là idempotency key — cùng
              // key mà form đã gửi lần đầu, nên timeout rồi phát lại không tạo trùng.
              final serverItem = await _api.create(
                _payloadFor(local),
                idempotencyKey: local.id,
              );
              await _dao.remapAndMarkSynced(local.id, serverItem);
              break;
            case 'UPDATE':
              final payload = _payloadFor(local);
              if (metadata.reason != null) {
                payload['reason'] = metadata.reason;
              }
              if (metadata.wasteCause != null) {
                payload['wasteCause'] = metadata.wasteCause;
              }
              final serverItem = await updateInventoryWithWasteFallback(
                _api,
                local.id,
                version: operation.baseVersion,
                payload: payload,
              );
              await _dao.markSynced(local.id, serverItem);
              break;
            case 'DELETE':
              await deleteInventoryWithWasteFallback(
                _api,
                local.id,
                version: operation.baseVersion,
                reason: metadata.reason ?? 'CORRECTED',
                wasteCause: metadata.wasteCause,
              );
              await _dao.deleteItem(local.id);
              break;
            default:
              break;
          }
          await _dao.removeQueuedOperation(operation.id);
        } on BusinessException catch (e) {
          // Lỗi có thể do token household mới — không xoá/đánh dấu conflict.
          if (isStaleEpoch(epoch)) break;
          if (e.code == 'ERR_INVENTORY_NOT_FOUND' &&
              operation.operation == 'DELETE') {
            await _dao.deleteItem(local.id);
            await _dao.removeQueuedOperation(operation.id);
            continue;
          }
          if (e.code == 'ERR_INVENTORY_VERSION_CONFLICT') {
            await _dao.updateSyncStatus(local.id, SyncStatus.conflict);
            await _dao.removeQueuedOperation(operation.id);
            continue;
          }
          // #55: request trước cùng key còn đang xử lý ở server — lỗi tạm,
          // giữ queue và dừng như lỗi mạng, lần drain sau gửi lại.
          if (e.code == 'ERR_IDEMPOTENCY_IN_PROGRESS') {
            break;
          }
          // #55: cùng key nhưng nội dung khác — không tự retry, báo người dùng
          // (offline-sync-contract.md §5). Rơi xuống nhánh chung bên dưới.
          if (e.code == 'ERR_IDEMPOTENCY_KEY_REUSED') {
            runInAction(() => _syncError.value = e);
          }
          // Lỗi nghiệp vụ khác không thể tự retry; giữ item được đánh dấu để
          // người dùng chỉnh lại, đồng thời bỏ queue tránh vòng lặp vô hạn.
          await _dao.updateSyncStatus(local.id, SyncStatus.conflict);
          await _dao.removeQueuedOperation(operation.id);
        } on ApiException {
          // Mạng/server chưa sẵn sàng: giữ nguyên queue và dừng, bảo toàn thứ tự.
          break;
        }
      }
    } finally {
      _isDrainingQueue = false;
    }
    // Household đổi giữa chừng (kể cả A→B→A): lần drain của household hiện
    // tại đã bị cờ trên chặn — chạy bù.
    // Store đã dispose (unbind cũng tăng epoch) → không chạy bù.
    if (isStaleEpoch(epoch) && isHouseholdBound && _session.householdId != null) {
      await drainSyncQueue();
    }
  }

  Future<void> _syncAfterConnectivityRestored() async {
    await drainSyncQueue();
    await syncFromServer();
  }

  Map<String, dynamic> _payloadFor(InventoryItemModel item) {
    return <String, dynamic>{
      'name': item.name,
      'category': item.category,
      'quantity': item.quantity,
      'unit': item.unit,
      'lowStockThreshold': item.lowStockThreshold,
      'expiryDate': item.expiryDate?.toUtc().toIso8601String().split('T').first,
      'note': item.note,
    };
  }

  Future<void> _reconcileDeletes(Set<String> serverIds, String hid) async {
    for (final local in List<InventoryItemModel>.from(_items)) {
      if (local.householdId == hid &&
          local.syncStatus == SyncStatus.synced &&
          !serverIds.contains(local.id)) {
        await _dao.deleteItem(local.id);
      }
    }
  }

  /// Xử lý event WS realtime. Dùng bởi [RealtimeStore].
  ///
  /// 2 lớp dedupe/guard — bỏ một là mất optimistic UI hoặc double-apply
  /// (FE-5 Implementation Guard 6):
  /// - eventId dedupe: BE at-least-once, có thể gửi trùng khi reconnect sweep.
  /// - actorId guard: nếu item đang PENDING_* cục bộ (của chính device),
  ///   không ghi đè — tránh mất optimistic write của người dùng.
  void handleWsEvent(WsEventEnvelope event) {
    if (event.householdId != _session.householdId) return;
    if (!_seenEventIds.add(event.eventId)) return; // dedupe §9.3
    if (_seenEventIds.length > _maxSeenEvents) {
      _seenEventIds.remove(_seenEventIds.first);
    }

    final eventType = event.eventType;
    final actorId = event.actorId;
    final data = (event.data as Map<String, dynamic>?) ?? const {};

    switch (eventType) {
      case 'INVENTORY_ITEM_CREATED':
      case 'INVENTORY_ITEM_UPDATED':
        final server = inventoryItemFromJson(data);
        unawaited(_applyRemoteItem(server, actorId: actorId));
      case 'INVENTORY_ITEM_DELETED':
        final id = data['id'] as String?;
        if (id != null) unawaited(_applyRemoteDelete(id, actorId: actorId));
      case 'INVENTORY_EXPIRY_ALERT':
      case 'INVENTORY_LOW_STOCK_ALERT':
        break; // bỏ qua có chủ đích (§2, notification-center tương lai)
      default:
        developer.log('InventoryStore: event type chưa xử lý: $eventType',
            name: 'InventoryStore');
    }
  }

  Future<void> _applyRemoteItem(
    InventoryItemModel remote, {
    String? actorId,
  }) async {
    final local = await _dao.getById(remote.id);
    final isOwnEcho = actorId == _session.currentUser?.id;
    if (local != null && local.syncStatus != SyncStatus.synced && !isOwnEcho) {
      return; // guard D12 — không ghi đè optimistic row đang pending
    }
    await _dao.upsertItem(remote.copyWith(syncStatus: SyncStatus.synced));
  }

  Future<void> _applyRemoteDelete(String id, {String? actorId}) async {
    final local = await _dao.getById(id);
    final isOwnEcho = actorId == _session.currentUser?.id;
    if (local != null && local.syncStatus != SyncStatus.synced && !isOwnEcho) {
      return; // cùng guard
    }
    await _dao.deleteItem(id);
  }
}
