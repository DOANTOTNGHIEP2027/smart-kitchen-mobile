import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/realtime/ws_event_envelope.dart';
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
class InventoryStore {
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
  final Observable<String?> _selectedCategory =
      Observable<String?>(null);
  final Observable<bool> _isSyncing = Observable<bool>(false);
  final Observable<ApiException?> _syncError =
      Observable<ApiException?>(null);

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
      final matchesSearch =
          q.isEmpty || i.name.toLowerCase().contains(q);
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
  Future<void> init() async {
    final hid = _session.householdId;
    if (hid == null) {
      runInAction(() => _status.value = InventoryLoadStatus.ready);
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
    await _dbSub?.cancel();
    _dbSub = null;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void setSearchQuery(String q) =>
      runInAction(() => _searchQuery.value = q);

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
        for (final serverItem in result.items) {
          final local = await _dao.getById(serverItem.id);
          if (local == null ||
              local.syncStatus == SyncStatus.synced) {
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
      // Chỉ reconcile-xóa khi đã tải đủ toàn bộ set; tránh false-positive
      if (gotFullSet == true) {
        await _reconcileDeletes(seenIds);
      }
    } on ApiException catch (e) {
      runInAction(() => _syncError.value = e);
    } catch (e) {
      // Bất ngờ — log và làm như mọi ApiException.
      developer.log('syncFromServer lỗi ngoài dự kiến: $e',
          name: 'InventoryStore');
      runInAction(() => _syncError.value =
          ServerException('ERR_UNKNOWN', e.toString()));
    } finally {
      runInAction(() => _isSyncing.value = false);
    }
  }

  /// Gửi lại mutation offline theo đúng thứ tự sau khi có mạng. Queue lưu trên
  /// SQLite nên không mất khi app bị đóng trước lúc reconnect.
  Future<void> drainSyncQueue() async {
    if (_isDrainingQueue) return;
    final hid = _session.householdId;
    if (hid == null) return;

    _isDrainingQueue = true;
    try {
      final operations = await _dao.queuedOperations(hid);
      for (final operation in operations) {
        final local = await _dao.getById(operation.itemId);
        if (local == null) {
          await _dao.removeQueuedOperation(operation.id);
          continue;
        }
        try {
          switch (operation.operation) {
            case 'CREATE':
              final serverItem = await _api.create(_payloadFor(local));
              await _dao.remapAndMarkSynced(local.id, serverItem);
              break;
            case 'UPDATE':
              final serverItem = await _api.update(
                local.id,
                version: operation.baseVersion,
                payload: _payloadFor(local),
              );
              await _dao.markSynced(local.id, serverItem);
              break;
            case 'DELETE':
              await _api.delete(
                local.id,
                version: operation.baseVersion,
                reason: operation.deleteReason ?? 'CORRECTED',
              );
              await _dao.deleteItem(local.id);
              break;
            default:
              break;
          }
          await _dao.removeQueuedOperation(operation.id);
        } on BusinessException catch (e) {
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

  Future<void> _reconcileDeletes(Set<String> serverIds) async {
    for (final local in List<InventoryItemModel>.from(_items)) {
      if (local.syncStatus == SyncStatus.synced &&
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
    if (local != null &&
        local.syncStatus != SyncStatus.synced &&
        !isOwnEcho) {
      return; // guard D12 — không ghi đè optimistic row đang pending
    }
    await _dao.upsertItem(
        remote.copyWith(syncStatus: SyncStatus.synced));
  }

  Future<void> _applyRemoteDelete(String id, {String? actorId}) async {
    final local = await _dao.getById(id);
    final isOwnEcho = actorId == _session.currentUser?.id;
    if (local != null &&
        local.syncStatus != SyncStatus.synced &&
        !isOwnEcho) {
      return; // cùng guard
    }
    await _dao.deleteItem(id);
  }
}
