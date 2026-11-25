import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/data/receipt_api.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/data/receipt_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_matched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_unmatched_item.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// Mẫu `data` đúng receipt-scan.yaml (camelCase). 2 dòng matched cùng
/// shoppingItemId (D23).
Map<String, dynamic> fullScanJson() => <String, dynamic>{
      'scanId': '5b0c7a8e-1111-4c1a-9a55-000000000001',
      'storeName': 'WinMart',
      'purchaseDate': '2026-11-20',
      'totalAmount': 185000,
      'currency': 'VND',
      'matchedItems': <Map<String, dynamic>>[
        <String, dynamic>{
          'shoppingItemId': 'si-1',
          'shoppingItemName': 'Cà chua',
          'rawName': 'CA CHUA DA LAT',
          'mappedName': 'Cà chua',
          'quantity': 1.5,
          'unit': 'kg',
          'unitPrice': 30000,
          'totalPrice': 45000,
          'matchConfidence': 0.95,
        },
        <String, dynamic>{
          'shoppingItemId': 'si-1',
          'shoppingItemName': 'Cà chua',
          'rawName': 'CA CHUA BI',
          'mappedName': '',
          'quantity': 1,
          'unit': 'hop',
          'unitPrice': null,
          'totalPrice': null,
          'matchConfidence': 0.87,
        },
      ],
      'unmatchedItems': <Map<String, dynamic>>[
        <String, dynamic>{
          'itemId': 'u-1',
          'rawName': 'SUA TUOI VINAMILK',
          'mappedName': 'Sữa tươi',
          'quantity': 2,
          'unit': 'hop',
          'unitPrice': 35000,
          'totalPrice': 70000,
          'matchConfidence': 0.71,
          'suggestedCategory': 'Sữa',
        },
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);

  group('ReceiptMapper', () {
    test('parse đủ field camelCase, lineKey theo vị trí, unit unmatched null',
        () {
      final result = ReceiptMapper.scanResultFromJson(fullScanJson());

      expect(result.meta.scanId, '5b0c7a8e-1111-4c1a-9a55-000000000001');
      expect(result.meta.storeName, 'WinMart');
      expect(result.meta.purchaseDate, DateTime(2026, 11, 20));
      expect(result.meta.totalAmount, 185000.0);
      expect(result.meta.isVnd, isTrue);

      final first = result.matchedItems[0];
      expect(first.lineKey, 'm0');
      expect(first.shoppingItemId, 'si-1');
      expect(first.shoppingItemName, 'Cà chua');
      expect(first.rawName, 'CA CHUA DA LAT');
      expect(first.mappedName, 'Cà chua');
      expect(first.quantity, 1.5);
      expect(first.unit, 'kg');
      expect(first.unitPrice, 30000.0);
      expect(first.totalPrice, 45000.0);
      expect(first.matchConfidence, 0.95);
      expect(first.needsReview, isFalse);

      final unmatched = result.unmatchedItems.single;
      expect(unmatched.itemId, 'u-1');
      expect(unmatched.name, 'Sữa tươi');
      expect(unmatched.category, 'Sữa');
      expect(unmatched.quantity, 2.0);
      expect(unmatched.unit, isNull); // D9
      expect(unmatched.rawName, 'SUA TUOI VINAMILK');
      expect(unmatched.rawQuantity, 2.0);
      expect(unmatched.rawUnit, 'hop');
      expect(unmatched.totalPrice, 70000.0);
      expect(unmatched.matchConfidence, 0.71);
      expect(unmatched.confirmStatus, ReceiptConfirmStatus.pending);
      expect(unmatched.isValidForConfirm, isFalse);
    });

    test('2 dòng cùng shoppingItemId → 2 item, lineKey khác nhau', () {
      final lines =
          ReceiptMapper.scanResultFromJson(fullScanJson()).matchedItems;

      expect(lines.map((l) => l.shoppingItemId), <String>['si-1', 'si-1']);
      expect(lines.map((l) => l.lineKey), <String>['m0', 'm1']);
      expect(lines[1].mappedName, isNull); // rỗng → null
      expect(lines[1].totalPrice, isNull);
      expect(lines[1].needsReview, isTrue);
    });

    test('field nullable null → null; unmatched không mappedName lấy rawName',
        () {
      final json = fullScanJson()
        ..['storeName'] = null
        ..['purchaseDate'] = null
        ..['totalAmount'] = null;
      final unmatched =
          (json['unmatchedItems'] as List<Map<String, dynamic>>).single
            ..['mappedName'] = null
            ..['suggestedCategory'] = null
            ..['matchConfidence'] = null
            ..['unitPrice'] = null
            ..['totalPrice'] = null;
      expect(unmatched, isNotNull);

      final result = ReceiptMapper.scanResultFromJson(json);

      expect(result.meta.storeName, isNull);
      expect(result.meta.purchaseDate, isNull);
      expect(result.meta.totalAmount, isNull);
      final item = result.unmatchedItems.single;
      expect(item.name, 'SUA TUOI VINAMILK');
      expect(item.category, isNull);
      expect(item.matchConfidence, isNull);
      expect(item.totalPrice, isNull);
    });

    test('2 danh sách rỗng là kết quả hợp lệ', () {
      final result = ReceiptMapper.scanResultFromJson(<String, dynamic>{
        'scanId': 's',
        'storeName': null,
        'purchaseDate': null,
        'totalAmount': null,
        'currency': 'USD',
        'matchedItems': <dynamic>[],
        'unmatchedItems': <dynamic>[],
      });

      expect(result.matchedItems, isEmpty);
      expect(result.unmatchedItems, isEmpty);
      expect(result.meta.isVnd, isFalse);
    });
  });

  group('ReceiptMatchedItem.needsReview', () {
    ReceiptMatchedItem line(double confidence) => ReceiptMatchedItem(
          lineKey: 'm0',
          shoppingItemId: 'si',
          shoppingItemName: 'x',
          rawName: 'x',
          quantity: 1,
          unit: 'kg',
          matchConfidence: confidence,
        );

    test('0.85 và 0.899 → true; 0.9 và 1.0 → false', () {
      expect(line(0.85).needsReview, isTrue);
      expect(line(0.899).needsReview, isTrue);
      expect(line(0.9).needsReview, isFalse);
      expect(line(1.0).needsReview, isFalse);
    });
  });

  group('ReceiptUnmatchedItem', () {
    const base = ReceiptUnmatchedItem(
      itemId: 'u',
      name: 'Trứng',
      quantity: 10,
      rawName: 'TRUNG',
      rawQuantity: 10,
      rawUnit: 'qua',
    );

    test('isValidForConfirm cùng luật OcrItem', () {
      expect(base.isValidForConfirm, isFalse); // chưa chọn unit
      expect(base.copyWith(unit: 'quả').isValidForConfirm, isTrue);
      expect(base.copyWith(unit: 'quả', quantity: 1.5).isValidForConfirm,
          isFalse); // đơn vị nguyên
      expect(
          base.copyWith(unit: 'kg', quantity: 1.5).isValidForConfirm, isTrue);
      expect(base.copyWith(unit: 'hộp').isValidForConfirm, isFalse);
      expect(base.copyWith(unit: 'kg', quantity: 0).isValidForConfirm, isFalse);
      expect(base.copyWith(unit: 'kg', name: '  ').isValidForConfirm, isFalse);
    });

    test('copyWith(unit: null) xoá được; không truyền thì giữ', () {
      final withUnit = base.copyWith(unit: 'kg', category: 'Trứng');
      expect(withUnit.copyWith(unit: null).unit, isNull);
      expect(withUnit.copyWith().unit, 'kg');
      expect(withUnit.copyWith(category: null).category, isNull);
    });
  });

  group('ReceiptApiImpl.scan', () {
    late List<RequestOptions> requests;

    ReceiptApi apiWith(Future<ResponseBody> Function(RequestOptions) handler) {
      final adapter = FakeHttpAdapter(handler);
      requests = adapter.requests;
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter;
      return ReceiptApiImpl(
        DioClient.build(tokenStorage: TokenStorage(), dio: dio),
      );
    }

    Future<void> scan(ReceiptApi api) => api.scan(
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
          idempotencyKey: 'key-1',
        );

    test('200: path, multipart chỉ field image, header key, timeout 35s',
        () async {
      final api = apiWith(
        (_) async => jsonResponse(200, successEnvelope(fullScanJson())),
      );

      final result = await api.scan(
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
        idempotencyKey: 'key-1',
      );

      expect(result.matchedItems, hasLength(2));
      final request = requests.single;
      expect(request.path, '/api/v1/receipts/scan');
      expect(request.method, 'POST');
      expect(request.headers['X-Idempotency-Key'], 'key-1');
      expect(request.receiveTimeout, const Duration(seconds: 35));
      final form = request.data as FormData;
      expect(form.fields, isEmpty); // không household_id/shopping_list_id
      expect(form.files.map((f) => f.key), <String>['image']);
      expect(form.files.single.value.length, 3);
    });

    const cases = <(int, String, Type)>[
      (400, 'ERR_RECEIPT_IMAGE_INVALID', BusinessException),
      (400, 'ERR_RECEIPT_IMAGE_TOO_LARGE', BusinessException),
      (400, 'ERR_VALIDATION_FAILED', BusinessException),
      (403, 'ERR_RECEIPT_NO_HOUSEHOLD', BusinessException),
      (409, 'ERR_RECEIPT_SCAN_IN_PROGRESS', BusinessException),
      (422, 'ERR_AI_CONTENT_FILTERED', BusinessException),
      (429, 'ERR_AI_RATE_LIMIT', BusinessException),
      (502, 'ERR_AI_INVALID_OUTPUT', ServerException),
      (503, 'ERR_AI_SERVICE_DOWN', ServerException),
      (504, 'ERR_AI_TIMEOUT', ServerException),
    ];
    for (final (status, code, type) in cases) {
      test('$status $code → $type giữ code', () async {
        final api = apiWith(
          (_) async => jsonResponse(status, errorEnvelope(code, 'x')),
        );

        await expectLater(
          scan(api),
          throwsA(
            isA<ApiException>()
                .having((e) => e.runtimeType, 'type', type)
                .having((e) => e.code, 'code', code),
          ),
        );
      });
    }

    test('mất mạng → NetworkException', () async {
      final api = apiWith((_) async => throw const SocketException('offline'));

      await expectLater(
        scan(api),
        throwsA(isA<NetworkException>()
            .having((e) => e.code, 'code', 'ERR_NETWORK')),
      );
    });

    test('200 nhưng success:false → ServerException ERR_UNKNOWN', () async {
      final api = apiWith(
        (_) async => jsonResponse(200, <String, dynamic>{
          'success': false,
          'data': null,
          'error': null,
          'timestamp': '2026-11-25T00:00:00Z',
        }),
      );

      await expectLater(
        scan(api),
        throwsA(isA<ServerException>()
            .having((e) => e.code, 'code', 'ERR_UNKNOWN')),
      );
    });

    test('DioException có error == null → ServerException ERR_UNKNOWN',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = FakeHttpAdapter(
          (_) async => jsonResponse(200, successEnvelope(fullScanJson())),
        );
      final client = DioClient.build(tokenStorage: TokenStorage(), dio: dio);
      // Chặn ngay onRequest, không qua ErrorMappingInterceptor → DioException
      // thô, error == null, tới thẳng _unwrap.
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(requestOptions: options),
          ),
        ),
      );

      await expectLater(
        scan(ReceiptApiImpl(client)),
        throwsA(isA<ServerException>()
            .having((e) => e.code, 'code', 'ERR_UNKNOWN')),
      );
    });

    test('200 nhưng data sai hình dạng (parse lỗi) → ServerException',
        () async {
      final api = apiWith(
        (_) async => jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            ...fullScanJson(),
            'scanId': 123, // phải là String
          }),
        ),
      );

      await expectLater(
        scan(api),
        throwsA(isA<ServerException>()
            .having((e) => e.code, 'code', 'ERR_UNKNOWN')),
      );
    });
  });
}
