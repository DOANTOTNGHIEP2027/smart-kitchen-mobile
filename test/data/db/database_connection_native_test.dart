import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/database_connection_native.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';

/// #93 F3 (app-performance-audit §7.1): Drift mở file trên isolate nền.
/// Dùng `test()` thay vì `testWidgets` — FakeAsync làm treo cổng giao tiếp
/// với isolate nền.
void main() {
  test('openDatabaseFile (createInBackground) ghi rồi đọc lại được qua DAO',
      () async {
    final dir = await Directory.systemTemp.createTemp('sk_db_bg_');
    final file = File('${dir.path}${Platform.pathSeparator}test.sqlite');
    final db = AppDatabase.forTesting(openDatabaseFile(file));
    try {
      final dao = ReadCacheDao(db);
      await dao.put('k', <String, dynamic>{'v': 1});
      final cached = await dao.get('k');
      expect(cached, isNotNull);
      expect(cached!.payload['v'], 1);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
    expect(file.existsSync(), isFalse);
  });
}
