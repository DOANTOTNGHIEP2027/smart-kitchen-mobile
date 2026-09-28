import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_mapper.dart';

void main() {
  test('maps the backend camelCase OCR contract including nullable raw values',
      () {
    final result = OcrMapper.scanResultFromJson(<String, dynamic>{
      'scanId': 'scan-1',
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'itemId': 'item-1',
          'name': 'Sữa tươi',
          'category': null,
          'quantity': null,
          'unit': null,
          'needsManualReview': true,
          'rawQuantity': null,
          'rawUnit': null,
          'expiryDate': '2026-10-01',
          'duplicate': false,
          'existingItemId': null,
        },
      ],
    });

    expect(result.scanId, 'scan-1');
    expect(result.items, hasLength(1));
    final item = result.items.single;
    expect(item.itemId, 'item-1');
    expect(item.needsManualReview, isTrue);
    expect(item.quantity, isNull);
    expect(item.rawQuantity, isNull);
    expect(item.rawUnit, isNull);
    expect(item.expiryEstimate, DateTime(2026, 10, 1));
    expect(item.isValidForConfirm, isFalse);
  });
}
