import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/demo/demo_backend_adapter.dart';
import 'package:smart_kitchen_mobile/demo/fixtures/demo_fixtures.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/data/receipt_api.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_scan_result.dart';

import '../helpers/secure_storage_channel.dart';

/// Demo Mode #68 (shopping-receipt-scan.md §2, D27): chạy ReceiptApi production
/// trên DemoBackendAdapter — fixture tất định, xoay vòng theo key mới.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  late ReceiptApi api;
  final image = Uint8List.fromList(<int>[1, 2, 3]);

  setUp(() {
    storage.install();
    final client = DioClient.build(
      tokenStorage: TokenStorage(),
      dio: Dio(BaseOptions(baseUrl: 'https://demo.local')),
    )..dio.httpClientAdapter = DemoBackendAdapter();
    api = ReceiptApiImpl(client);
  });
  tearDown(storage.uninstall);

  Future<ReceiptScanResult> scan(String key) =>
      api.scan(imageBytes: image, idempotencyKey: key);

  test('xoay vòng bình thường → trùng món → rỗng → bình thường', () async {
    final normal = await scan('k1');
    final duplicate = await scan('k2');
    final empty = await scan('k3');
    final again = await scan('k4');

    expect(normal.matchedItems.map((line) => line.shoppingItemId),
        <String>['demo-shop-001', 'demo-shop-004']);
    expect(normal.matchedItems.where((line) => line.needsReview), hasLength(1));
    expect(normal.matchedItems[1].matchConfidence, 0.86);
    expect(normal.unmatchedItems, hasLength(1));
    expect(normal.unmatchedItems.single.unit, isNull); // D9 — phải chọn
    expect(normal.meta.storeName, isNotNull);
    expect(normal.meta.purchaseDate, isNotNull);
    expect(normal.meta.totalAmount, isNotNull);
    expect(normal.meta.isVnd, isTrue);

    expect(duplicate.matchedItems, hasLength(2));
    expect(
      duplicate.matchedItems.map((line) => line.shoppingItemId).toSet(),
      <String>{'demo-shop-002'},
    );
    expect(
      duplicate.matchedItems.every((line) => line.totalPrice != null),
      isTrue,
    );

    expect(empty.matchedItems, isEmpty);
    expect(empty.unmatchedItems, isEmpty);

    expect(again.matchedItems.map((line) => line.shoppingItemId),
        <String>['demo-shop-001', 'demo-shop-004']);
    expect(again.meta.scanId, isNot(normal.meta.scanId));
  });

  test('cùng key → đúng fixture cũ, không tăng bộ đếm', () async {
    final first = await scan('same');
    final retry = await scan('same');
    final next = await scan('other');

    expect(retry.meta.scanId, first.meta.scanId);
    expect(retry.matchedItems, hasLength(first.matchedItems.length));
    // Lần key mới kế tiếp vẫn là fixture thứ 2 (trùng món).
    expect(
      next.matchedItems.map((line) => line.shoppingItemId).toSet(),
      <String>{'demo-shop-002'},
    );
  });

  test('mọi shoppingItemId matched là món PENDING có thật trong fixture', () {
    final pendingIds = DemoFixtures.shoppingItems()
        .where((item) => item['status'] == 'PENDING')
        .map((item) => item['id'])
        .toSet();
    for (final fixture in <Map<String, dynamic>>[
      DemoFixtures.receiptScanNormal('s'),
      DemoFixtures.receiptScanDuplicate('s'),
      DemoFixtures.receiptScanEmpty('s'),
    ]) {
      for (final line in fixture['matchedItems'] as List<dynamic>) {
        expect(
          pendingIds,
          contains((line as Map<String, dynamic>)['shoppingItemId']),
        );
      }
    }
  });
}
