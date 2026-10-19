import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';

void main() {
  test('DB v5 (có price, chưa có assigned_to) nâng lên v6 → thêm cột, dữ liệu cũ còn', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE shopping_list_items (
          id TEXT NOT NULL PRIMARY KEY, household_id TEXT NOT NULL, shopping_list_id TEXT,
          name TEXT NOT NULL, quantity REAL NOT NULL, unit TEXT NOT NULL,
          display_quantity REAL NOT NULL, display_unit TEXT NOT NULL, category TEXT,
          status TEXT NOT NULL, source TEXT NOT NULL, version INTEGER NOT NULL,
          created_by TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'SYNCED', price REAL
        )''');
      raw.execute(
          "INSERT INTO shopping_list_items VALUES ('old','h1',NULL,'Cũ',1,'kg',1,'kg',NULL,'COMPLETED','MANUAL',1,NULL,'2026-10-01T00:00:00Z','2026-10-01T00:00:00Z','SYNCED',55000)");
      raw.userVersion = 5;
    }));
    addTearDown(db.close);
    final dao = ShoppingDao(db);

    final old = await dao.getById('old');
    expect(old!.price, 55000);
    expect(old.assignedTo, isNull);

    // Đọc không đủ để phát hiện thiếu cột (SELECT * trả null cho cột vắng) —
    // phải GHI rồi đọc lại.
    await dao.upsert(old.copyWith(assignedTo: 'u-1'));
    expect((await dao.getById('old'))!.assignedTo, 'u-1');
  });
}
