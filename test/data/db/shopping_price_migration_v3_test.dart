import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';

void main() {
  test('DB v3 (chưa có bảng shopping) nâng lên v5 → createTable đã có cột price, KHÔNG addColumn trùng', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.userVersion = 3;
    }));
    addTearDown(db.close);
    // Mở DB chạy migration; truy vấn bảng shopping không được ném lỗi
    // duplicate column / no such column.
    expect(await ShoppingDao(db).getById('none'), isNull);
  });
}
