import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_version.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/ai_result.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/connectivity/connectivity_gate.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/ai_task.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/model_manifest.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/model_registry.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/on_device_inference_engine.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/on_device_inference_engine_impl.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/hybrid_ai_runner.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/tasks/calorie_estimate_task.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/tasks/receipt_ocr_task.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/receipt_ocr_cloud.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/domain/ocr_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/domain/ocr_scan_result.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/utils/sha256.dart';

/// Issue #119 — on-device-ai-runtime.md §6.5.
class _Conn extends ConnectivityService {
  _Conn(this.online);
  bool online;
  @override
  Future<bool> isOnline() async => online;
}

/// Engine giả: trả output cố định hoặc ném lỗi.
class _Engine implements OnDeviceInferenceEngine {
  _Engine(this.output);
  InferenceOutput output;
  Object? failWith;
  int runs = 0;
  InferenceInput? lastInput;

  @override
  Future<void> loadIfNeeded(AITask task) async {}

  @override
  Future<InferenceOutput> run(AITask task, InferenceInput input) async {
    runs++;
    lastInput = input;
    if (failWith != null) throw failWith!;
    return output;
  }
}

class _FakeOcrApi implements OcrApi {
  final List<String> keys = <String>[];
  @override
  Future<OcrScanResult> scan({required Uint8List imageBytes, required String idempotencyKey}) async {
    keys.add(idempotencyKey);
    return const OcrScanResult(scanId: 's1', items: <OcrItem>[
      OcrItem(
        itemId: 'p1',
        name: 'Cà chua bi',
        category: 'VEGETABLE',
        quantity: 0.5,
        unit: 'kg',
        needsManualReview: false,
        rawQuantity: 500,
        rawUnit: 'G',
        duplicate: true,
        existingItemId: 'inv-9',
      ),
      OcrItem(
        itemId: 'p2',
        name: 'Sữa',
        quantity: null,
        unit: null,
        needsManualReview: true,
        rawQuantity: null,
        rawUnit: null,
        duplicate: false,
      ),
    ]);
  }
}

String meta(AITask task, Map<String, dynamic> o) => jsonEncode(<String, dynamic>{
      'task': task.assetDir,
      'modelVersion': 1,
      'appMinVersion': '0.1.0',
      'runtime': 'rules-only',
      'payloadFile': null,
      'checksumSha256': null,
      'inputShape': null,
      'inputDType': null,
      'preprocessing': null,
      'outputShape': null,
      'outputType': ModelManifest.outputTypes[task],
      'labelMapFile': null,
      'quantization': 'n/a',
      ...o,
    });

const String tableJson = '{"version":1,"entries":['
    '{"name":"cơm trắng","aliases":["com trang","Cơm"],"kcalPer100g":130,"gramsPerUnit":null},'
    '{"name":"trứng gà","aliases":["trung ga"],"kcalPer100g":155,"gramsPerUnit":50},'
    '{"name":"sữa tươi","aliases":[],"kcalPer100g":62,"gramsPerUnit":null}]}';

/// Registry với receipt_ocr (mlkit) + calorie_estimate (đã ship bảng [table]).
Future<ModelRegistry> registry({String? table = tableJson, bool ocr = true}) async {
  final ocrMeta = jsonDecode(meta(AITask.receiptOcr, <String, dynamic>{'runtime': 'mlkit-bundled'}))
      as Map<String, dynamic>;
  ocrMeta['checksumSha256'] = sha256Hex(ModelManifest.canonicalManifestJson(ocrMeta));
  final files = <String, String>{
    if (ocr) 'assets/models/receipt_ocr/v1/metadata.json': jsonEncode(ocrMeta),
    if (table != null) ...<String, String>{
      'assets/models/calorie_estimate/v1/metadata.json': meta(AITask.calorieEstimate, <String, dynamic>{
        'payloadFile': 'nutrition_table.json',
        'checksumSha256': sha256Hex(utf8.encode(table)),
      }),
      'assets/models/calorie_estimate/v1/nutrition_table.json': table,
    },
  };
  final reg = ModelRegistry(
    appVersion: '0.1.0',
    loader: (path) async {
      final v = files[path];
      if (v == null) throw FlutterError('missing $path');
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(v)));
    },
  );
  await reg.bootstrap();
  return reg;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final image = Uint8List.fromList(<int>[1, 2, 3]);

  group('ReceiptLineParser (§6.5.3)', () {
    List<ReceiptLineItem> parse(List<String> lines) => ReceiptLineParser.parse(lines, confidence: 0.7).items;

    test('dòng hoá đơn mẫu → quantity/unit/price chỉ khi chắc chắn; rawName NGUYÊN VĂN', () {
      final cases = <String, (double?, String?, double?)>{
        'Ca chua bi 500G 25.000': (500, 'g', 25000),
        'Sua tuoi 1L 32,500đ': (1, 'l', 32500),
        'Trứng gà 10 quả 35000': (10, 'quả', 35000),
        'Thit heo 0,5kg 60.000 VND': (0.5, 'kg', 60000),
        'Thit bo 1.200g 250.000': (null, null, 250000),
        'Nuoc mam 500ml': (500, 'ml', null),
        'Banh mi 2 cái 10.000 ₫': (2, 'cái', 10000),
        'Rau muong': (null, null, null),
        'Bơ250g': (null, null, null),
        'Nam 2026': (null, null, 2026),
        'Hop 3 cai 9.000': (null, null, 9000),
        'Ma SP 8934563123456': (null, null, null),
        'SP 123456789': (null, null, 123456789), // mã ≤9 số = giá (giới hạn đã biết)
      };
      for (final MapEntry(key: line, value: expected) in cases.entries) {
        final item = parse(<String>['  $line  ']).single;
        expect(item.rawName, line, reason: 'chỉ trim, không chuẩn hoá');
        expect((item.quantity, item.unit, item.price), expected, reason: line);
        expect(item.confidence, 0.7);
      }
    });

    test('số có đơn vị ở cuối dòng không bị đọc thành price', () {
      final item = parse(<String>['Gao 5000g']).single;
      expect((item.quantity, item.unit, item.price), (5000, 'g', null));
    });

    test('bỏ dòng rỗng / không có chữ; dòng tổng VẪN thành item (giới hạn Q8)', () {
      final items = parse(<String>['', '   ', '12.000', '--- 2026/11/25 ---', 'TONG CONG 120.000']);
      expect(items.map((i) => i.rawName), <String>['TONG CONG 120.000']);
      expect(items.single.price, 120000);
    });

    test('không có confidence → null; danh sách rỗng → rỗng', () {
      expect(ReceiptLineParser.parse(<String>['Muoi']).items.single.confidence, isNull);
      expect(ReceiptLineParser.parse(<String>[]).items, isEmpty);
    });
  });

  group('ReceiptOcrRepositoryImpl — bảng §8', () {
    late ModelRegistry reg;
    late _Engine engine;
    setUp(() async {
      reg = await registry();
      engine = _Engine(const ReceiptOcrOutput(<String>['Ca chua bi 500G 25.000'], confidence: 0.9));
    });

    ReceiptOcrRepositoryImpl repo(_Conn conn, ReceiptOcrCloudScan? cloud) =>
        ReceiptOcrRepositoryImpl(HybridAIRunner(ConnectivityGate(conn), engine, reg), cloud: cloud);

    const cloudResult = ReceiptOcrResult(items: <ReceiptLineItem>[ReceiptLineItem(rawName: 'cloud')]);

    test('offline biết trước → on-device, KHÔNG gọi cloud; parse output', () async {
      var called = false;
      final r = await repo(_Conn(false), (_) async {
        called = true;
        return cloudResult;
      }).scan(image);
      expect(called, isFalse);
      expect(r.source, AISource.onDevice);
      expect(r.isDegraded, isTrue);
      expect(r.modelUsed, 'on-device:receipt_ocr@v1');
      expect(r.confidence, 0.9);
      final item = r.data!.items.single;
      expect((item.rawName, item.quantity, item.unit, item.price), ('Ca chua bi 500G 25.000', 500, 'g', 25000));
      expect((engine.lastInput! as ReceiptOcrInput).imageBytes, image);
    });

    test('online + cloud OK → fromCloud, engine không chạy', () async {
      final r = await repo(_Conn(true), (_) async => cloudResult).scan(image);
      expect((r.source, r.modelUsed, r.data!.items.single.rawName),
          (AISource.cloud, 'cloud:inventory-items-scan#38', 'cloud'));
      expect(engine.runs, 0);
    });

    test('NetworkException + re-check offline → on-device', () async {
      final conn = _Conn(true);
      final r = await repo(conn, (_) async {
        conn.online = false;
        throw NetworkException();
      }).scan(image);
      expect(r.source, AISource.onDevice);
      expect(r.offlineFallback, isTrue);
    });

    test('NetworkException + re-check VẪN online → rethrow (Guard #1)', () async {
      await expectLater(repo(_Conn(true), (_) async => throw NetworkException()).scan(image),
          throwsA(isA<NetworkException>()));
      expect(engine.runs, 0);
    });

    test('lỗi có response (ServerException) → rethrow, không fallback', () async {
      await expectLater(repo(_Conn(true), (_) async => throw ServerException('ERR_AI_SERVICE_DOWN', 'x')).scan(image),
          throwsA(isA<ServerException>()));
      expect(engine.runs, 0);
    });

    test('isAvailable(receiptOcr) == false → AIResult.unavailable', () async {
      reg = await registry(ocr: false);
      final r = await repo(_Conn(false), null).scan(image);
      expect((r.success, r.error!.code), (false, AIResult.errModelUnavailable));
      expect(engine.runs, 0);
    });

    test('engine THẬT (stub OCR) → MODEL_UNAVAILABLE, không phải INFERENCE_FAILED', () async {
      final r = await ReceiptOcrRepositoryImpl(
              HybridAIRunner(ConnectivityGate(_Conn(false)), OnDeviceInferenceEngineImpl(reg), reg))
          .scan(image);
      expect(r.error!.code, AIResult.errModelUnavailable);
    });
  });

  group('receiptOcrCloudScan adapter (§6.5.1/§6.5.2)', () {
    test('idempotency key = sha256(bytes): cùng ảnh → cùng key; khác ảnh → khác key', () async {
      final api = _FakeOcrApi();
      final scan = receiptOcrCloudScan(api);
      await scan(image);
      await scan(Uint8List.fromList(<int>[1, 2, 3]));
      await scan(Uint8List.fromList(<int>[9]));
      expect(api.keys[0], sha256Hex(image));
      expect(api.keys[1], api.keys[0]);
      expect(api.keys[2], isNot(api.keys[0]));
    });

    test('map OcrItem → ReceiptLineItem: tên cloud, quantity/unit giữ, price/confidence null', () async {
      final result = await receiptOcrCloudScan(_FakeOcrApi())(image);
      final items = result.items;
      expect((items[0].rawName, items[0].quantity, items[0].unit, items[0].price, items[0].confidence),
          ('Cà chua bi', 0.5, 'kg', null, null));
      expect((items[1].rawName, items[1].quantity, items[1].unit), ('Sữa', null, null));
    });
  });

  group('NutritionTable (§6.5.4)', () {
    NutritionTable table(String json) => NutritionTable.fromJson(Uint8List.fromList(utf8.encode(json)));
    String entries(String e) => '{"version":1,"entries":[$e]}';

    test('hợp lệ; tra theo name/alias, chuẩn hoá khoảng trắng + hoa/thường, GIỮ dấu', () {
      final t = table(tableJson);
      expect(t.lookup('  CƠM   TRẮNG ')!.kcalPer100g, 130);
      expect(t.lookup('com trang')!.kcalPer100g, 130);
      expect(t.lookup('cơm')!.kcalPer100g, 130);
      expect(t.lookup('com'), isNull, reason: 'không bỏ dấu, không fuzzy');
      expect(t.lookup('trung'), isNull);
    });

    test('kcalPer100g = 0 hợp lệ (vd. nước)', () {
      expect(table(entries('{"name":"nước","aliases":[],"kcalPer100g":0,"gramsPerUnit":null}')).lookup('nước')!.kcalPer100g, 0);
    });

    test('alias trùng name của chính mục → bỏ qua (hợp lệ)', () {
      expect(table(entries('{"name":"Gạo","aliases":["gạo"],"kcalPer100g":360,"gramsPerUnit":null}')).lookup('gạo'),
          isNotNull);
    });

    final invalid = <String, String>{
      'không phải object': '[]',
      'version sai': '{"version":2,"entries":[{"name":"a","aliases":[],"kcalPer100g":1,"gramsPerUnit":null}]}',
      'entries rỗng': '{"version":1,"entries":[]}',
      'entry không phải object': entries('1'),
      'name rỗng': entries('{"name":"  ","aliases":[],"kcalPer100g":1,"gramsPerUnit":null}'),
      'aliases không phải mảng chuỗi': entries('{"name":"a","aliases":[1],"kcalPer100g":1,"gramsPerUnit":null}'),
      'kcal âm': entries('{"name":"a","aliases":[],"kcalPer100g":-1,"gramsPerUnit":null}'),
      'kcal không phải số': entries('{"name":"a","aliases":[],"kcalPer100g":"1","gramsPerUnit":null}'),
      'gramsPerUnit = 0': entries('{"name":"a","aliases":[],"kcalPer100g":1,"gramsPerUnit":0}'),
      'trùng khoá giữa 2 mục': entries('{"name":"a","aliases":["b"],"kcalPer100g":1,"gramsPerUnit":null},'
          '{"name":"B","aliases":[],"kcalPer100g":2,"gramsPerUnit":null}'),
      'dấu tổ hợp (không NFC)': entries('{"name":"côm","aliases":[],"kcalPer100g":1,"gramsPerUnit":null}'),
      'JSON hỏng': '{oops',
      'version là số thực 1.0': '{"version":1.0,"entries":[{"name":"a","aliases":[],"kcalPer100g":1,"gramsPerUnit":null}]}',
      'gramsPerUnit âm': entries('{"name":"a","aliases":[],"kcalPer100g":1,"gramsPerUnit":-5}'),
      'gramsPerUnit không phải số': entries('{"name":"a","aliases":[],"kcalPer100g":1,"gramsPerUnit":"50"}'),
      'name không phải chuỗi': entries('{"name":1,"aliases":[],"kcalPer100g":1,"gramsPerUnit":null}'),
      'thiếu aliases': entries('{"name":"a","kcalPer100g":1,"gramsPerUnit":null}'),
      'dấu tổ hợp trong alias': entries('{"name":"a","aliases":["côm"],"kcalPer100g":1,"gramsPerUnit":null}'),
    };
    for (final MapEntry(key: name, value: json) in invalid.entries) {
      test('sai: $name → FormatException', () {
        expect(() => table(json), throwsFormatException);
      });
    }
  });

  group('CalorieLookupEngine (§6.5.4)', () {
    final engine = CalorieLookupEngine(NutritionTable.fromJson(Uint8List.fromList(utf8.encode(tableJson))));
    CalorieEstimateItem one(RecognizedFoodItem item) => engine.estimate(<RecognizedFoodItem>[item]).result.items.single;

    test('bảng quy đổi đơn vị + confidence', () {
      final cases = <String, (RecognizedFoodItem, double, double)>{
        'g': (const RecognizedFoodItem(name: 'cơm trắng', quantity: 200, unit: 'g'), 260, 1),
        'kg (unit hoa + khoảng trắng)': (const RecognizedFoodItem(name: 'cơm trắng', quantity: 0.5, unit: ' KG '), 650, 1),
        'ml (giả định 1g/ml)': (const RecognizedFoodItem(name: 'sữa tươi', quantity: 200, unit: 'ml'), 124, 0.8),
        'l': (const RecognizedFoodItem(name: 'sữa tươi', quantity: 1, unit: 'l'), 620, 0.8),
        'quả × gramsPerUnit': (const RecognizedFoodItem(name: 'trứng gà', quantity: 2, unit: 'quả'), 155, 1),
        'cái × gramsPerUnit': (const RecognizedFoodItem(name: 'trung ga', quantity: 1, unit: 'cái'), 77.5, 1),
        'unit null + quantity = số cái': (const RecognizedFoodItem(name: 'trứng gà', quantity: 4), 310, 1),
        'quantity + unit null, không có gramsPerUnit → không tính': (const RecognizedFoodItem(name: 'cơm trắng', quantity: 2), 0, 0),
        'không quantity/unit → 1 khẩu phần gramsPerUnit': (const RecognizedFoodItem(name: 'trứng gà'), 77.5, 0.5),
        'không quantity/unit, không gramsPerUnit → 100 g': (const RecognizedFoodItem(name: 'cơm trắng'), 130, 0.5),
        'quantity 0 → 0 kcal, tính được': (const RecognizedFoodItem(name: 'cơm trắng', quantity: 0, unit: 'g'), 0, 1),
        'có unit thiếu quantity → không tính': (const RecognizedFoodItem(name: 'cơm trắng', unit: 'g'), 0, 0),
        'unit lạ → không tính': (const RecognizedFoodItem(name: 'cơm trắng', quantity: 1, unit: 'bát'), 0, 0),
        'quantity âm → không tính': (const RecognizedFoodItem(name: 'cơm trắng', quantity: -1, unit: 'g'), 0, 0),
        'quantity NaN → không tính': (const RecognizedFoodItem(name: 'cơm trắng', quantity: double.nan, unit: 'g'), 0, 0),
        'không có trong bảng': (const RecognizedFoodItem(name: 'phở bò', quantity: 300, unit: 'g'), 0, 0),
      };
      for (final MapEntry(key: name, value: (item, kcal, confidence)) in cases.entries) {
        final r = one(item);
        expect(r.kcal, closeTo(kcal, 1e-9), reason: name);
        expect(r.confidence, confidence, reason: name);
        expect(r.name, item.name, reason: 'giữ nguyên tên đầu vào');
      }
    });

    test('tổng + thứ tự + món không khớp KHÔNG bị ẩn + confidence chung + estimationMethod', () {
      final out = engine.estimate(const <RecognizedFoodItem>[
        RecognizedFoodItem(name: 'phở bò', quantity: 300, unit: 'g'),
        RecognizedFoodItem(name: 'cơm trắng', quantity: 200, unit: 'g'),
        RecognizedFoodItem(name: 'trứng gà', quantity: 2, unit: 'quả'),
      ]);
      expect(out.result.items.map((i) => i.name), <String>['phở bò', 'cơm trắng', 'trứng gà']);
      expect(out.result.totalKcal, closeTo(415, 1e-9));
      expect(out.result.estimationMethod, CalorieEstimateResult.lookupTable);
      expect(out.confidence, closeTo(2 / 3, 1e-9));
    });

    test('danh sách rỗng → total 0, items rỗng, confidence null', () {
      final out = engine.estimate(const <RecognizedFoodItem>[]);
      expect((out.result.totalKcal, out.confidence), (0.0, null));
      expect(out.result.items, isEmpty);
    });
  });

  group('CalorieEstimateRepositoryImpl — bảng §8 + engine thật', () {
    const input = <RecognizedFoodItem>[RecognizedFoodItem(name: 'cơm trắng', quantity: 100, unit: 'g')];
    const cloudResult = CalorieEstimateResult(totalKcal: 1, items: <CalorieEstimateItem>[], estimationMethod: CalorieEstimateResult.llm);

    Future<(CalorieEstimateRepositoryImpl, ModelRegistry)> make(_Conn conn, {String? table = tableJson}) async {
      final reg = await registry(table: table);
      return (CalorieEstimateRepositoryImpl(HybridAIRunner(ConnectivityGate(conn), OnDeviceInferenceEngineImpl(reg), reg)), reg);
    }

    test('offline → lookup_table on-device, modelUsed đúng, confidence từ engine', () async {
      final (repo, _) = await make(_Conn(false));
      final r = await repo.estimate(input, cloud: () async => cloudResult);
      expect((r.source, r.isDegraded, r.modelUsed), (AISource.onDevice, true, 'on-device:calorie_estimate@v1'));
      expect((r.data!.totalKcal, r.data!.estimationMethod), (130.0, CalorieEstimateResult.lookupTable));
      expect(r.confidence, 1.0);
    });

    test('cloud null + online → chạy cục bộ, KHÔNG báo offline', () async {
      final (repo, _) = await make(_Conn(true));
      final r = await repo.estimate(input);
      expect((r.source, r.offlineFallback, r.isDegraded), (AISource.onDevice, false, false));
    });

    test('online + cloud OK → llm từ cloud', () async {
      final (repo, _) = await make(_Conn(true));
      final r = await repo.estimate(input, cloud: () async => cloudResult);
      expect((r.source, r.modelUsed, r.data!.estimationMethod), (AISource.cloud, 'cloud:calorie-estimate', 'llm'));
    });

    test('NetworkException → re-check offline → on-device; VẪN online → rethrow; ServerException → rethrow', () async {
      final conn = _Conn(true);
      final (repo, _) = await make(conn);
      final r = await repo.estimate(input, cloud: () async {
        conn.online = false;
        throw NetworkException();
      });
      expect(r.source, AISource.onDevice);

      conn.online = true;
      await expectLater(repo.estimate(input, cloud: () async => throw NetworkException()), throwsA(isA<NetworkException>()));
      await expectLater(repo.estimate(input, cloud: () async => throw ServerException('ERR_X', 'x')),
          throwsA(isA<ServerException>()));
    });

    test('bảng chưa ship → MODEL_UNAVAILABLE', () async {
      final (repo, _) = await make(_Conn(false), table: null);
      expect((await repo.estimate(input)).error!.code, AIResult.errModelUnavailable);
    });

    test('engine: payload đã verify nhưng schema hỏng → modelUnavailable (không phải inference failed)', () async {
      final (repo, reg) = await make(_Conn(false), table: '{"version":1,"entries":[]}');
      expect(reg.isAvailable(AITask.calorieEstimate), isTrue, reason: 'checksum khớp, chỉ schema hỏng');
      expect((await repo.estimate(input)).error!.code, AIResult.errModelUnavailable);
    });
  });

  test('engine gọi THẲNG: thiếu payload calo → modelUnavailable', () async {
    final reg = await registry(table: null);
    await expectLater(OnDeviceInferenceEngineImpl(reg).loadIfNeeded(AITask.calorieEstimate),
        throwsA(isA<OnDeviceInferenceException>().having((e) => e.modelUnavailable, 'unavailable', isTrue)));
  });

  test('asset THẬT đang ship: OCR + calo offline → MODEL_UNAVAILABLE (§6.5.4 trạng thái build)', () async {
    final reg = ModelRegistry(appVersion: AppVersion.current);
    await reg.bootstrap();
    final runner = HybridAIRunner(ConnectivityGate(_Conn(false)), OnDeviceInferenceEngineImpl(reg), reg);
    expect((await ReceiptOcrRepositoryImpl(runner).scan(image)).error!.code, AIResult.errModelUnavailable);
    expect((await CalorieEstimateRepositoryImpl(runner).estimate(const <RecognizedFoodItem>[])).error!.code,
        AIResult.errModelUnavailable);
  });
}
