import 'package:drift/drift.dart';

import '../../../data/db/app_database.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_mapper.dart';
import '../domain/sync_status.dart';

/// DAO for inventory_items table (FE-5 §5.4).
///
/// Một số quyết định load-bearing:
/// - [watchAllItems] reaktivitet Drift dùng cho [InventoryStore.init] —
///   phát snapshot đầu tiên ngay khi có subscriber, kể cả khi list rỗng →
///   status chuyển ready không cần chờ network.
/// - [markPendingDelete] chỉ đổi syncStatus, không xoá row — để optimistic UI
///   giấu item qua watchAllItems (filter `!= PENDING_DELETE`).
/// - `remapAndMarkSynced` xoá temp id + insert server id trong 1 transaction,
///   vì id là PK nên không update được tại chỗ.
class InventoryDao {
  InventoryDao(this._db);

  final AppDatabase _db;

  /// Reactive stream. Loại bỏ row PENDING_DELETE khỏi UI ngay khi user xoá
  /// optimistic (§5.4).
  Stream<List<InventoryItemModel>> watchAllItems(String householdId) {
    final query = _db.select(_db.inventoryItems)
      ..where((t) =>
          t.householdId.equals(householdId) &
          t.syncStatus.equals('PENDING_DELETE').not())
      ..orderBy([
        // PENDING_*/CONFLICT trước (đang chờ người dùng xử lý) — rồi đến SYNCED.
        // Giữ createdAt DESC ổn định để UI không nhảy thứ tự giữa các emission.
        (t) => OrderingTerm(expression: t.syncStatus.equals('SYNCED')),
        (u) => OrderingTerm.desc(u.createdAt),
      ]);
    return query.watch().map((rows) =>
        rows.map(inventoryItemFromRow).toList(growable: false));
  }

  Future<InventoryItemModel?> getById(String id) async {
    final row = await (_db.select(_db.inventoryItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : inventoryItemFromRow(row);
  }

  Future<void> upsertItem(InventoryItemModel item) {
    return _db
        .into(_db.inventoryItems)
        .insertOnConflictUpdate(inventoryItemToRow(item));
  }

  /// CREATE reconciliation: temp id không đổi được tại chỗ (PK) — xoá row temp
  /// + insert row server id trong 1 transaction (§5.4).
  Future<void> remapAndMarkSynced(
      String tempId, InventoryItemModel serverItem) {
    return _db.transaction(() async {
      await (_db.delete(_db.inventoryItems)
            ..where((t) => t.id.equals(tempId)))
          .go();
      await upsertItem(serverItem.copyWith(syncStatus: SyncStatus.synced));
    });
  }

  Future<void> markSynced(String id, InventoryItemModel serverItem) {
    return upsertItem(
        serverItem.copyWith(id: id, syncStatus: SyncStatus.synced));
  }

  Future<void> markPendingDelete(String id) {
    return (_db.update(_db.inventoryItems)
          ..where((t) => t.id.equals(id)))
        .write(const InventoryItemsCompanion(syncStatus: Value('PENDING_DELETE')));
  }

  /// Cập nhật syncStatus cho một row (KHÔNG ghi đè các field khác) —
  /// dùng khi server gửi 409 conflict và ta cần set CONFLICT giữ nguyên state
  /// optimistic của mình để dựng dialog.
  Future<void> updateSyncStatus(String id, SyncStatus status) {
    return (_db.update(_db.inventoryItems)
          ..where((t) => t.id.equals(id)))
        .write(InventoryItemsCompanion(syncStatus: Value(_toString(status))));
  }

  Future<void> deleteItem(String id) {
    return (_db.delete(_db.inventoryItems)..where((t) => t.id.equals(id)))
        .go();
  }

  String _toString(SyncStatus s) {
    switch (s) {
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.pendingCreate:
        return 'PENDING_CREATE';
      case SyncStatus.pendingUpdate:
        return 'PENDING_UPDATE';
      case SyncStatus.pendingDelete:
        return 'PENDING_DELETE';
      case SyncStatus.conflict:
        return 'CONFLICT';
    }
  }
}
