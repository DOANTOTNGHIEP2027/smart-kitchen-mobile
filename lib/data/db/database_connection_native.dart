import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openDatabaseConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return openDatabaseFile(File(p.join(dir.path, 'smart_kitchen.sqlite')));
    });

/// Mở SQLite trên isolate nền (#93 F3 — app-performance-audit §7.1): truy vấn
/// Drift không còn chiếm main isolate. Tách ra để test mở được file tạm.
QueryExecutor openDatabaseFile(File file) =>
    NativeDatabase.createInBackground(file);
