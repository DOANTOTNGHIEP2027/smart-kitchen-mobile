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

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
