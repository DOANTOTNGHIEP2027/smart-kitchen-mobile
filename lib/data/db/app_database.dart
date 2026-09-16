import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'read_cache_table.dart';

part 'app_database.g.dart';

/// Drift singleton dùng chung cho toàn app. FE-3 ship trước FE-4 nên
/// `schemaVersion = 1` và chỉ có 1 bảng [ReadCacheEntries].
///
/// `drift_flutter` tự handle native (NativeDatabase + ffi) và web (WASM).
@DriftDatabase(tables: <Type>[ReadCacheEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_drift());

  /// Cho test — truyền executor tuỳ ý (vd `NativeDatabase.memory()`).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _drift() => driftDatabase(
      name: 'smart_kitchen',
      native: DriftNativeOptions(
        databasePath: () async => 'smart_kitchen.sqlite',
      ),
    );

