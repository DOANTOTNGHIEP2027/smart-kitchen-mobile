import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/demo/demo_perf_seed.dart';
import 'package:smart_kitchen_mobile/demo/fixtures/demo_fixtures.dart';

/// #93 §6.3 — dữ liệu demo cho harness đo; mặc định giữ nguyên demo cũ.
void main() {
  test('mặc định (không --dart-define) giữ hành vi demo cũ', () {
    expect(DemoPerfSeed.seedSession, isFalse);
    expect(DemoPerfSeed.inventoryCount, 0);
    expect(DemoPerfSeed.recipeCount, 0);
    expect(DemoPerfSeed.latencyMs, 450);
  });

  test('expandPerfInventory: count 0 → trả nguyên base', () {
    final base = DemoFixtures.inventory();
    expect(identical(expandPerfInventory(base, 0), base), isTrue);
  });

  test('expandPerfInventory: đúng N item, id duy nhất, có item sắp hết hạn',
      () {
    final base = DemoFixtures.inventory();
    final items =
        expandPerfInventory(base, 100, now: DateTime.utc(2026, 11, 1));
    expect(items, hasLength(100));
    expect(items.map((i) => i['id']).toSet(), hasLength(100));
    expect(items.where((i) => i['isExpiringSoon'] == true), isNotEmpty);
    expect(items.where((i) => i['isExpiringSoon'] == false), isNotEmpty);
    expect(items[9]['name'], '${base[9 % base.length]['name']} #9');
    // LOW-1 review #93: id đi vào URL `/inventory-items/<id>` và route
    // `/inventory/<id>/edit` → chỉ ký tự an toàn cho URL (không `#`).
    expect(items[9]['id'], '${base[9 % base.length]['id']}-p9');
    for (final item in items) {
      final id = item['id'] as String;
      expect(Uri.encodeComponent(id), id, reason: 'id "$id" không URL-safe');
    }
    expect(items[1]['expiryDate'], '2026-11-02');
  });

  test('perfRecipeIds + perfRecipeBaseId: N id perf ánh xạ vòng về base', () {
    const base = <String>['a', 'b', 'c'];
    expect(perfRecipeIds(base, 0), base);
    final ids = perfRecipeIds(base, 5);
    expect(ids, <String>[
      'perf-recipe-0',
      'perf-recipe-1',
      'perf-recipe-2',
      'perf-recipe-3',
      'perf-recipe-4',
    ]);
    expect(ids.map((id) => perfRecipeBaseId(id, base)),
        <String>['a', 'b', 'c', 'a', 'b']);
    expect(perfRecipeBaseId('a', base), 'a');
    expect(perfRecipeBaseId('perf-recipe-x', base), 'perf-recipe-x');
  });
}
