import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

// Assets are prepared by tool/prepare_web.dart before Flutter's web build.
QueryExecutor openDatabaseConnection() => DatabaseConnection.delayed(
      Future(() async {
        final database = await WasmDatabase.open(
          databaseName: 'smart_kitchen',
          sqlite3Uri: Uri.parse('sqlite3.wasm'),
          driftWorkerUri: Uri.parse('drift_worker.dart.js'),
        );
        return database.resolvedExecutor;
      }),
    );
