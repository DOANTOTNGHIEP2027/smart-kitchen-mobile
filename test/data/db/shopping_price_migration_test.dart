import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/domain/shopping_item.dart';

void main() {
  test('DB v4 (chưa có cột price) nâng lên v5 → thêm cột, ghi/đọc giá được, dữ liệu cũ còn', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      // Schema shopping_list_items đúng như v4 (trước #133).
      raw.execute('''
        CREATE TABLE shopping_list_items (
          id TEXT NOT NULL PRIMARY KEY, household_id TEXT NOT NULL, shopping_list_id TEXT,
          name TEXT NOT NULL, quantity REAL NOT NULL, unit TEXT NOT NULL,
          display_quantity REAL NOT NULL, display_unit TEXT NOT NULL, category TEXT,
          status TEXT NOT NULL, source TEXT NOT NULL, version INTEGER NOT NULL,
          created_by TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'SYNCED'
        )''');
      raw.execute(
          "INSERT INTO shopping_list_items VALUES ('old','h1',NULL,'Cũ',1,'kg',1,'kg',NULL,'PENDING','MANUAL',1,NULL,'2026-10-01T00:00:00Z','2026-10-01T00:00:00Z','SYNCED')");
      raw.userVersion = 4;
    }));
    addTearDown(db.close);
    final dao = ShoppingDao(db);

    final old = await dao.getById('old');
    expect(old!.name, 'Cũ');
    expect(old.price, isNull);

    await dao.upsert(old.copyWith(status: ShoppingItemStatus.completed, price: 55000));
    expect((await dao.getById('old'))!.price, 55000);
  });
}
