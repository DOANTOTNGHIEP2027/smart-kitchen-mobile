import 'package:drift/drift.dart';

/// Bảng read-cache dùng chung cho mọi màn fetch-list/detail khi mất mạng.
/// Không phải sync-queue: chỉ có `put` (upsert) + `get`.
class ReadCacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  TextColumn get fetchedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}
