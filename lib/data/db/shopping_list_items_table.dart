import 'package:drift/drift.dart';

class ShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get shoppingListId => text().nullable()();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get displayQuantity => real()();
  TextColumn get displayUnit => text()();
  TextColumn get category => text().nullable()();
  TextColumn get status => text()();
  TextColumn get source => text()();
  IntColumn get version => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('SYNCED'))();
  /// Giá VND người dùng nhập khi tick (#133) — `null` = chưa nhập (khác 0).
  RealColumn get price => real().nullable()();
  /// UUID thành viên được giao mua (#134) — `null` = chưa giao.
  TextColumn get assignedTo => text().nullable()();
  /// #239: món đã được cất vào kho (BE `inInventory`).
  BoolColumn get inInventory => boolean().withDefault(const Constant(false))();
  /// JSON `[{dishId, slotDate, mealTime}]` (BE `sources`) — `null` = không gắn món.
  TextColumn get sourceRefs => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
