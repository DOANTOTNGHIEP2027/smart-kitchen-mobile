import 'package:drift/drift.dart';

/// Queue riêng cho Shopping. Không dùng chung queue Inventory vì tập thao tác
/// và quy tắc coalesce khác nhau.
class ShoppingSyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get householdId => text()();
  TextColumn get itemId => text()();
  TextColumn get operation => text()(); // CREATE | TOGGLE_COMPLETE
  TextColumn get payload => text()();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get createdAt => text()();
}
