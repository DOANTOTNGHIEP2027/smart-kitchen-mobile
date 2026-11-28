import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';

AppDatabase legacyDatabase(
    {required bool hasInventoryColumn, int version = 8}) {
  return AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
    raw.execute('''
      CREATE TABLE shopping_list_items (
        id TEXT NOT NULL PRIMARY KEY,
        household_id TEXT NOT NULL, shopping_list_id TEXT,
        name TEXT NOT NULL, quantity REAL NOT NULL, unit TEXT NOT NULL,
        display_quantity REAL NOT NULL, display_unit TEXT NOT NULL,
        category TEXT, status TEXT NOT NULL, source TEXT NOT NULL,
        version INTEGER NOT NULL, created_by TEXT,
        created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED', price REAL,
        assigned_to TEXT
        ${hasInventoryColumn ? ', in_inventory BOOLEAN NOT NULL DEFAULT 0' : ''}
      )
    ''');
    raw.execute('''
      INSERT INTO shopping_list_items (
        id, household_id, name, quantity, unit, display_quantity, display_unit,
        status, source, version, created_at, updated_at, sync_status, price,
        assigned_to ${hasInventoryColumn ? ', in_inventory' : ''}
      ) VALUES (
        'old', 'h1', 'Món cũ', 2, 'kg', 2, 'kg', 'PENDING', 'MANUAL', 3,
        '2026-11-27T00:00:00Z', '2026-11-27T00:00:00Z',
        'PENDING_CREATE', 45000, 'member-1'
        ${hasInventoryColumn ? ', 1' : ''}
      )
    ''');
    raw.execute('''
      CREATE TABLE shopping_sync_queue_entries (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        household_id TEXT NOT NULL, item_id TEXT NOT NULL,
        operation TEXT NOT NULL, payload TEXT NOT NULL,
        base_version INTEGER, created_at TEXT NOT NULL
      )
    ''');
    raw.execute('''
      INSERT INTO shopping_sync_queue_entries (
        household_id, item_id, operation, payload, created_at
      ) VALUES ('h1', 'old', 'CREATE', '{}', '2026-11-27T00:00:00Z')
    ''');
    raw.userVersion = version;
  }));
}

void main() {
  for (final hasColumn in [false, true]) {
    test('DB v8 có in_inventory=$hasColumn: nâng cấp giữ món và queue offline',
        () async {
      final db = legacyDatabase(hasInventoryColumn: hasColumn);
      addTearDown(db.close);
      final dao = ShoppingDao(db);

      final old = (await dao.getAll('h1')).single;
      expect(old.inInventory, hasColumn);
      expect(old.price, 45000);
      expect(old.assignedTo, 'member-1');
      expect(old.isPendingSync, isTrue);
      expect((await dao.queue('h1')).single.itemId, 'old');

      // Phải ghi được cột mới, không chỉ đọc SELECT * với cột bị thiếu.
      await dao.upsert(old.copyWith(inInventory: !hasColumn));
      expect((await dao.getById('old'))!.inInventory, !hasColumn);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 9);
      final columns =
          await db.customSelect('PRAGMA table_info(shopping_list_items)').get();
      expect(columns.where((c) => c.read<String>('name') == 'in_inventory'),
          hasLength(1));
    });
  }

  test('DB v7 vẫn nâng cấp đúng, không thêm in_inventory hai lần', () async {
    final db = legacyDatabase(hasInventoryColumn: false, version: 7);
    addTearDown(db.close);
    final dao = ShoppingDao(db);
    final item = (await dao.getAll('h1')).single;
    expect(item.inInventory, isFalse);
    await dao.upsert(item.copyWith(inInventory: true));
    expect((await dao.getById('old'))!.inInventory, isTrue);
  });

  test('DB mới tạo đủ schema v9', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await ShoppingDao(db).getAll('h1'), isEmpty);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 9);
  });
}
