import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/db/app_database.dart';
import '../domain/shopping_item.dart';
import 'shopping_mapper.dart';

class ShoppingDao {
  ShoppingDao(this._db);
  final AppDatabase _db;

  Stream<List<ShoppingItem>> watchAll(String householdId) {
    final query = _db.select(_db.shoppingListItems)
      ..where((t) => t.householdId.equals(householdId))
      ..orderBy([(t) => OrderingTerm.asc(t.category), (t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map(shoppingItemFromRow).toList());
  }

  Future<ShoppingItem?> getById(String id) async {
    final row = await (_db.select(_db.shoppingListItems)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : shoppingItemFromRow(row);
  }

  Future<void> upsert(ShoppingItem item) => _db.into(_db.shoppingListItems).insertOnConflictUpdate(shoppingItemToRow(item));
  Future<void> delete(String id) => (_db.delete(_db.shoppingListItems)..where((t) => t.id.equals(id))).go();

  Future<void> remap(String temporaryId, ShoppingItem server) => _db.transaction(() async {
    await delete(temporaryId);
    await upsert(server.copyWith(syncStatus: ShoppingSyncStatus.synced));
  });

  Future<void> enqueueCreate(ShoppingItem item) => _insertQueue(item, 'CREATE', null);

  /// Hai toggle offline liên tiếp triệt tiêu nhau; row trở về state server.
  Future<bool> enqueueToggle(ShoppingItem item, ShoppingItem previous) async {
    final existing = await (_db.select(_db.shoppingSyncQueueEntries)
          ..where((t) => t.itemId.equals(item.id)))
        .getSingleOrNull();
    if (existing?.operation == 'TOGGLE_COMPLETE') {
      await (_db.delete(_db.shoppingSyncQueueEntries)..where((t) => t.id.equals(existing!.id))).go();
      await upsert(previous.copyWith(syncStatus: ShoppingSyncStatus.synced));
      return true;
    }
    await _insertQueue(item, 'TOGGLE_COMPLETE', previous.version);
    return false;
  }

  Future<void> _insertQueue(ShoppingItem item, String operation, int? baseVersion) =>
      _db.into(_db.shoppingSyncQueueEntries).insert(ShoppingSyncQueueEntriesCompanion.insert(
        householdId: item.householdId,
        itemId: item.id,
        operation: operation,
        payload: jsonEncode(shoppingCreatePayload(item)),
        baseVersion: Value(baseVersion),
        createdAt: DateTime.now().toUtc().toIso8601String(),
      ));

  Future<List<ShoppingSyncQueueEntry>> queue(String householdId) =>
      (_db.select(_db.shoppingSyncQueueEntries)..where((t) => t.householdId.equals(householdId))..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  Future<void> removeQueue(int id) => (_db.delete(_db.shoppingSyncQueueEntries)..where((t) => t.id.equals(id))).go();
}
