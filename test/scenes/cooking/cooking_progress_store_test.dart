import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';

void main() {
  late AppDatabase db;
  late ReadCacheDao cache;
  late DriftCookingProgressStore progress;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cache = ReadCacheDao(db);
    progress = DriftCookingProgressStore(cache);
  });
  tearDown(() => db.close());

  test(
      'persists across store instances and isolates user, household and session',
      () async {
    await progress.write('u1', 'h1', 's1', 3);
    final reopened = DriftCookingProgressStore(ReadCacheDao(db));
    expect(await reopened.read('u1', 'h1', 's1'), 3);
    expect(await reopened.read('u2', 'h1', 's1'), isNull);
    expect(await reopened.read('u1', 'h2', 's1'), isNull);
    expect(await reopened.read('u1', 'h1', 's2'), isNull);
    await progress.write('u2', 'h1', 's1', 2);
    await progress.clear('u1', 'h1', 's1');
    expect(await progress.read('u1', 'h1', 's1'), isNull);
    expect(await progress.read('u2', 'h1', 's1'), 2);
  });

  test('missing, invalid and unsupported payloads do not restore progress',
      () async {
    const key = 'cooking-progress:v1:u:h:s';
    expect(await progress.read('u', 'h', 's'), isNull);
    for (final payload in <Map<String, dynamic>>[
      {'version': 2, 'step': 3},
      {'version': 1, 'step': -1},
      {'version': 1, 'step': '3'},
      {'version': 1},
    ]) {
      await cache.put(key, payload);
      expect(await progress.read('u', 'h', 's'), isNull);
    }
  });
}
