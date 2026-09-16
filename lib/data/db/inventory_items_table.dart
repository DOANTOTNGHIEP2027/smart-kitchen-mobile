import 'package:drift/drift.dart';

/// Cache local inventory (FE-5 §5.1).
///
/// `syncStatus` cột enum lưu xâu: SYNCED | PENDING_CREATE | PENDING_UPDATE |
/// PENDING_DELETE | CONFLICT. Quy về xâu vì drift/SQLite không có enum native,
/// vàCodegen tạo typed text column thì vẫn lưu xâu ở DB.
///
/// Phần nullable field (category/expiryDate/lowStockThreshold/note) dùng text/
/// real nullable để khớp với BE. `displayQuantity`/`displayUnit` nullable đúng
/// OAS v1.2.0 — display* có thể null sau khi một buổi nấu trừ lô hàng.
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get displayQuantity => real().nullable()();
  TextColumn get displayUnit => text().nullable()();
  RealColumn get lowStockThreshold => real().nullable()();
  TextColumn get expiryDate => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get version => integer()();
  BoolColumn get isLowStock => boolean().withDefault(const Constant(false))();
  BoolColumn get isExpiringSoon =>
      boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('SYNCED'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
