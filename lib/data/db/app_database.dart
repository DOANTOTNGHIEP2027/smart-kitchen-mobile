import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'read_cache_table.dart';

part 'app_database.g.dart';

/// Drift singleton dùng chung cho toàn app. FE-3 ship trước FE-4 nên
/// `schemaVersion = 1` và chỉ có 1 bảng [ReadCacheEntries].
@DriftDatabase(tables: <Type>[ReadCacheEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_filesystemBackend());

  /// Cho test — truyền executor tuỳ ý (vd `NativeDatabase.memory()`).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _filesystemBackend() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'smart_kitchen.sqlite'));
    return NativeDatabase(file);
  });
}
