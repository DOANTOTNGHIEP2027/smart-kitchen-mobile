import 'package:drift/drift.dart';

import '../../../data/db/app_database.dart';
import '../domain/shopping_category.dart';

/// DAO category local-only (#69 §6) — KHÔNG có API/sync nào đứng sau (Guard #3).
class ShoppingCategoryDao {
  ShoppingCategoryDao(this._db);
  final AppDatabase _db;

  static ShoppingCategory _fromRow(ShoppingCategoryRow r) => ShoppingCategory(
        id: r.id,
        householdId: r.householdId,
        name: r.name,
        colorHex: r.colorHex,
        sortOrder: r.sortOrder,
        createdAt: DateTime.parse(r.createdAt),
      );

  static ShoppingCategoriesCompanion _toCompanion(ShoppingCategory c) =>
      ShoppingCategoriesCompanion.insert(
        id: c.id,
        householdId: c.householdId,
        name: c.name,
        colorHex: c.colorHex,
        sortOrder: c.sortOrder,
        createdAt: c.createdAt.toIso8601String(),
      );

  Stream<List<ShoppingCategory>> watchAll(String householdId) {
    final query = _db.select(_db.shoppingCategories)
      ..where((t) => t.householdId.equals(householdId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// So khớp tên không phân biệt hoa/thường, in-memory — số category/household
  /// luôn nhỏ (watch item Q4).
  Future<bool> existsByName(String householdId, String name, {String? exceptId}) async {
    final normalized = name.trim().toLowerCase();
    final rows = await (_db.select(_db.shoppingCategories)
          ..where((t) => t.householdId.equals(householdId)))
        .get();
    return rows.any((r) => r.id != exceptId && r.name.trim().toLowerCase() == normalized);
  }

  /// `max(sortOrder) + 1` — KHÔNG dùng số dòng: sau khi xoá, sortOrder có lỗ
  /// hổng nên số dòng có thể trùng sortOrder của category đang có.
  Future<int> nextSortOrder(String householdId) async {
    final rows = await (_db.select(_db.shoppingCategories)
          ..where((t) => t.householdId.equals(householdId)))
        .get();
    return rows.fold<int>(-1, (m, r) => r.sortOrder > m ? r.sortOrder : m) + 1;
  }

  Future<void> insert(ShoppingCategory c) =>
      _db.into(_db.shoppingCategories).insert(_toCompanion(c));

  /// Chỉ ghi tên + màu — không ghi đè `sortOrder` bằng bản trong RAM có thể cũ
  /// hơn lần reorder vừa ghi.
  Future<void> update(ShoppingCategory c) =>
      (_db.update(_db.shoppingCategories)..where((t) => t.id.equals(c.id)))
          .write(ShoppingCategoriesCompanion(name: Value(c.name), colorHex: Value(c.colorHex)));

  Future<void> delete(String id) =>
      (_db.delete(_db.shoppingCategories)..where((t) => t.id.equals(id))).go();

  /// [orderedIds] là thứ tự MỚI đầy đủ — ghi lại sortOrder trong 1 transaction.
  Future<void> reorder(List<String> orderedIds) => _db.transaction(() async {
        for (var i = 0; i < orderedIds.length; i++) {
          await (_db.update(_db.shoppingCategories)
                ..where((t) => t.id.equals(orderedIds[i])))
              .write(ShoppingCategoriesCompanion(sortOrder: Value(i)));
        }
      });
}
