import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'inventory_items_table.dart';
import 'read_cache_table.dart';

part 'app_database.g.dart';

/// Drift singleton dùng chung cho toàn app.
///
/// Lịch sử schemaVersion:
/// - 1 (FE-3): chỉ bảng [ReadCacheEntries].
/// - 2 (FE-5): thêm bảng [InventoryItems] cho kho household. Migration
///   `CREATE TABLE` thuần tăng — không đụng bảng cũ, không ALTER, không DROP.
@DriftDatabase(tables: <Type>[ReadCacheEntries, InventoryItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_filesystemBackend());

  /// Cho test — truyền executor tuỳ ý (vd `NativeDatabase.memory()`).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // FE-5 — schemaVersion 2: thêm bảng inventory_items.
            await m.createTable(inventoryItems);
          }
        },
      );
}

LazyDatabase _filesystemBackend() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smart_kitchen.sqlite'));
    return NativeDatabase(file);
  });
}
