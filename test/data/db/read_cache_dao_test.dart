import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';

void main() {
  late AppDatabase db;
  late ReadCacheDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ReadCacheDao(db);
  });

  tearDown(() => db.close());

  test('get với key chưa từng put → null', () async {
    expect(await dao.get('missing'), isNull);
  });

  test('put rồi get → trả đủ payload + fetchedAt parse được', () async {
    await dao.put('health_profile:u1', <String, dynamic>{
      'userId': 'u1',
      'allergens': <Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'name': 'Fish'},
      ],
    });

    final cached = await dao.get('health_profile:u1');

    expect(cached, isNotNull);
    expect(cached!.payload['userId'], 'u1');
    expect((cached.payload['allergens'] as List<dynamic>).length, 1);
    expect(cached.fetchedAt, isA<DateTime>());
  });

  test('put 2 lần cùng key → upsert (không nhân bản row)', () async {
    await dao.put('k', <String, dynamic>{'v': 1});
    await dao.put('k', <String, dynamic>{'v': 2});

    final cached = await dao.get('k');
    expect(cached!.payload['v'], 2);

    final count = await db.select(db.readCacheEntries).get();
    expect(count.length, 1, reason: 'upsert không được nhân bản row');
  });
}
