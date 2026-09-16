import 'dart:convert';

import '../db/app_database.dart';

class CachedEntry {
  const CachedEntry({required this.payload, required this.fetchedAt});

  final Map<String, dynamic> payload;
  final DateTime fetchedAt;
}

class ReadCacheDao {
  ReadCacheDao(this._db);

  final AppDatabase _db;

  Future<CachedEntry?> get(String key) async {
    final row = await (_db.select(_db.readCacheEntries)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return CachedEntry(
      payload: jsonDecode(row.payload) as Map<String, dynamic>,
      fetchedAt: DateTime.parse(row.fetchedAt),
    );
  }

  Future<void> put(String key, Map<String, dynamic> payload) {
    return _db.into(_db.readCacheEntries).insertOnConflictUpdate(
          ReadCacheEntriesCompanion.insert(
            key: key,
            payload: jsonEncode(payload),
            fetchedAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
  }
}
