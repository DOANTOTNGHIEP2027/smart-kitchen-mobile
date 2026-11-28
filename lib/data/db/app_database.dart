import 'package:drift/drift.dart';

import 'database_connection_native.dart'
    if (dart.library.js_interop) 'database_connection_web.dart';
import 'inventory_items_table.dart';
import 'inventory_sync_queue_table.dart';
import 'read_cache_table.dart';
import 'shopping_categories_table.dart';
import 'shopping_list_items_table.dart';
import 'shopping_sync_queue_table.dart';

part 'app_database.g.dart';

/// Drift singleton dùng chung cho toàn app.
///
/// Lịch sử schemaVersion:
/// - 1 (FE-3): chỉ bảng [ReadCacheEntries].
/// - 2 (FE-5): thêm bảng [InventoryItems] cho kho household. Migration
///   `CREATE TABLE` thuần tăng — không đụng bảng cũ, không ALTER, không DROP.
/// - 3 (P0-2): thêm [InventorySyncQueue] để mutation offline sống qua restart.
/// - 4 (P1): thêm item và queue riêng cho Shopping offline-first.
/// - 5 (#133): thêm cột `price` cho shopping_list_items. DB đi từ <4 tạo bảng
///   mới đã có cột này nên chỉ ALTER khi đi từ đúng v4.
/// - 6 (#134): thêm cột `assigned_to` — ALTER khi đi từ v4 hoặc v5.
/// - 7 (#69): thêm bảng [ShoppingCategories] (category local-only).
/// - 8 (#239): thêm cột `in_inventory` cho shopping_list_items. DB đi từ <4
///   tạo bảng mới đã có cột này nên chỉ ALTER khi đi từ v4..v7.
/// - 9: sửa DB v8 của bản local từng dùng cùng version nhưng thiếu
///   `in_inventory`; giữ nguyên dữ liệu và hàng đợi offline.
/// - 10: thêm cột `source_refs` (món thực đơn sinh ra dòng đi chợ). DB đi từ
///   <4 tạo bảng mới đã có cột này nên chỉ ALTER khi đi từ v4..v9.
@DriftDatabase(tables: <Type>[
  ReadCacheEntries,
  InventoryItems,
  InventorySyncQueue,
  ShoppingListItems,
  ShoppingSyncQueueEntries,
  ShoppingCategories,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  /// Cho test — truyền executor tuỳ ý (vd `NativeDatabase.memory()`).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // FE-5 — schemaVersion 2: thêm bảng inventory_items.
            await m.createTable(inventoryItems);
          }
          if (from < 3) {
            await m.createTable(inventorySyncQueue);
          }
          if (from < 4) {
            await m.createTable(shoppingListItems);
            await m.createTable(shoppingSyncQueueEntries);
          }
          if (from == 4) {
            // #133 — giá khi tick hoàn thành món đi chợ.
            await m.addColumn(shoppingListItems, shoppingListItems.price);
          }
          if (from == 4 || from == 5) {
            // #134 — người được giao mua.
            await m.addColumn(shoppingListItems, shoppingListItems.assignedTo);
          }
          if (from < 7) {
            await m.createTable(shoppingCategories);
          }
          if (from >= 4 && from < 8) {
            // #239 — món đã cất vào kho.
            await m.addColumn(shoppingListItems, shoppingListItems.inInventory);
          }
          if (from == 8) {
            final columns = await customSelect(
              'PRAGMA table_info(shopping_list_items)',
            ).get();
            if (!columns.any(
              (column) => column.read<String>('name') == 'in_inventory',
            )) {
              await m.addColumn(
                  shoppingListItems, shoppingListItems.inInventory);
            }
          }
          if (from >= 4 && from < 10) {
            await m.addColumn(shoppingListItems, shoppingListItems.sourceRefs);
          }
        },
      );
}
