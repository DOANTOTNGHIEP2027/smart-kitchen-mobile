import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/ai_result.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/connectivity/connectivity_gate.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/ai_task.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/model_registry.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/on_device_inference_engine.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/engine/on_device_inference_engine_impl.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/hybrid_ai_runner.dart';
import 'package:smart_kitchen_mobile/data/ai_runtime/tasks/meal_selection_task.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/shared/allergen_derivation.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/utils/sha256.dart';
import 'package:smart_kitchen_mobile/widgets/ai/ai_offline_widgets.dart';

import '../../helpers/pump_app.dart';

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Loader in-memory: path → nội dung; thiếu path → ném như rootBundle.
AssetBytesLoader memLoader(Map<String, String> files) => (path) async {
      final v = files[path];
      if (v == null) throw FlutterError('asset not found: $path');
      return ByteData.sublistView(bytes(v));
    };

const String rulesJson = '{"weights":{"expiringPriority":0.4,"repetitionPenalty":0.5}}';

Map<String, String> rulesPackage({String? checksum, String runtime = 'rules-only'}) => <String, String>{
      'assets/models/rule_based_selection/v1/metadata.json': jsonEncode(<String, dynamic>{
        'task': 'rule_based_selection',
        'modelVersion': 1,
        'runtime': runtime,
        'payloadFile': 'rules_config.json',
        'checksumSha256': checksum ?? sha256Hex(utf8.encode(rulesJson)),
      }),
      'assets/models/rule_based_selection/v1/rules_config.json': rulesJson,
    };

class _Conn extends ConnectivityService {
  _Conn(this.online);
  bool online;
  @override
  Future<bool> isOnline() async => online;
}

class _Engine implements OnDeviceInferenceEngine {
  int runs = 0;
  Object? failWith;
  @override
  Future<void> loadIfNeeded(AITask task) async {}
  @override
  Future<InferenceOutput> run(AITask task, InferenceInput input) async {
    runs++;
    if (failWith != null) throw failWith!;
    return const MealSelectionOutput(MealSelectionResult(selectedDishId: 'local', ruleTrace: <String>[]));
  }
}

MealCandidate cand(String id,
        {Set<String>? allergens = const <String>{},
        AllergenDerivation derivation = AllergenDerivation.ingredientRule,
        double? rep,
        double? exp}) =>
    MealCandidate(
        dishId: id,
        name: id,
        allergenTags: allergens,
        allergenDerivation: derivation,
        repetitionScore: rep,
        expiringIngredientMatch: exp);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sha256Hex — vector chuẩn FIPS 180-4', () {
    test('"", "abc", 448 bit, 1 triệu chữ a', () {
      expect(sha256Hex(<int>[]), 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(sha256Hex(utf8.encode('abc')), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(sha256Hex(utf8.encode('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')),
          '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
      expect(sha256Hex(List<int>.filled(1000000, 0x61)),
          'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
    });

    test('biên padding 55/56/64 byte', () {
      expect(sha256Hex(List<int>.filled(55, 0x61)),
          '9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318');
      expect(sha256Hex(List<int>.filled(56, 0x61)),
          'b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a');
      expect(sha256Hex(List<int>.filled(64, 0x61)),
          'ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb');
    });
  });

  group('ModelRegistry (Guard #6, #7)', () {
    test('package hợp lệ → khả dụng; task không có asset → chỉ cloud, KHÔNG throw', () async {
      final reg = ModelRegistry(loader: memLoader(rulesPackage()));
      await reg.bootstrap();
      expect(reg.isAvailable(AITask.ruleBasedSelection), isTrue);
      expect(reg.manifestFor(AITask.ruleBasedSelection).modelUsed, 'on-device:rule_based_selection@v1');
      for (final t in <AITask>[AITask.receiptOcr, AITask.calorieEstimate, AITask.repetitionScore]) {
        expect(reg.isAvailable(t), isFalse);
      }
    });

    test('checksum sai / runtime lạ → task đó unavailable, không crash', () async {
      final bad = ModelRegistry(loader: memLoader(rulesPackage(checksum: 'deadbeef')));
      await bad.bootstrap();
      expect(bad.isAvailable(AITask.ruleBasedSelection), isFalse);
      final weird = ModelRegistry(loader: memLoader(rulesPackage(runtime: 'tensorrt')));
      await weird.bootstrap();
      expect(weird.isAvailable(AITask.ruleBasedSelection), isFalse);
    });

    test('modelVersion trong metadata lệch thư mục v<N> → unavailable', () async {
      final files = rulesPackage();
      const metaPath = 'assets/models/rule_based_selection/v1/metadata.json';
      files[metaPath] = files[metaPath]!.replaceFirst('"modelVersion":1', '"modelVersion":2');
      final reg = ModelRegistry(loader: memLoader(files));
      await reg.bootstrap();
      expect(reg.isAvailable(AITask.ruleBasedSelection), isFalse);
    });

    test('package THẬT đang ship trong assets/ có checksum đúng', () async {
      final reg = ModelRegistry(loader: (path) async => ByteData.sublistView(await File(path).readAsBytes()));
      await reg.bootstrap();
      expect(reg.isAvailable(AITask.ruleBasedSelection), isTrue);
    });
  });

  group('HybridAIRunner — bảng quyết định §8', () {
    late ModelRegistry reg;
    late _Engine engine;
    setUp(() async {
      reg = ModelRegistry(loader: memLoader(rulesPackage()));
      await reg.bootstrap();
      engine = _Engine();
    });

    Future<AIResult<String>> run(_Conn conn, Future<String> Function() cloud) =>
        HybridAIRunner(ConnectivityGate(conn), engine, reg).run<String>(
          task: AITask.ruleBasedSelection,
          cloud: cloud,
          cloudModelUsed: 'cloud:x',
          input: const MealSelectionInput(<MealCandidate>[], HouseholdConstraints(hardAllergenExclusions: <String>{})),
          fromOutput: (o) => (o as MealSelectionOutput).result.selectedDishId!,
        );

    test('offline biết trước → on-device, KHÔNG gọi cloud', () async {
      var called = false;
      final r = await run(_Conn(false), () async { called = true; return 'cloud'; });
      expect(called, isFalse);
      expect(r.source, AISource.onDevice);
      expect(r.isDegraded, isTrue);
    });

    test('online + cloud OK → fromCloud, không degraded', () async {
      final r = await run(_Conn(true), () async => 'cloud');
      expect(r.data, 'cloud');
      expect(r.isDegraded, isFalse);
      expect(engine.runs, 0);
    });

    test('NetworkException + re-check offline → on-device', () async {
      final conn = _Conn(true);
      final r = await run(conn, () async { conn.online = false; throw NetworkException(); });
      expect(r.source, AISource.onDevice);
      expect(r.data, 'local');
    });

    test('NetworkException nhưng re-check VẪN online → rethrow (Guard #1)', () async {
      await expectLater(run(_Conn(true), () async => throw NetworkException()), throwsA(isA<NetworkException>()));
      expect(engine.runs, 0);
    });

    test('lỗi có response (ERR_AI_SERVICE_DOWN 5xx) → rethrow, KHÔNG fallback', () async {
      await expectLater(run(_Conn(true), () async => throw ServerException('ERR_AI_SERVICE_DOWN', 'down')),
          throwsA(isA<ServerException>()));
      expect(engine.runs, 0);
    });

    test('model thiếu → ERR_ONDEVICE_MODEL_UNAVAILABLE; run lỗi → ERR_ONDEVICE_INFERENCE_FAILED (không gộp)', () async {
      final empty = ModelRegistry(loader: memLoader(<String, String>{}));
      await empty.bootstrap();
      final r1 = await HybridAIRunner(ConnectivityGate(_Conn(false)), engine, empty).runOnDevice<String>(
          task: AITask.ruleBasedSelection, input: const MealSelectionInput(<MealCandidate>[], HouseholdConstraints(hardAllergenExclusions: <String>{})), fromOutput: (_) => '');
      expect(r1.success, isFalse);
      expect(r1.error!.code, AIResult.errModelUnavailable);
      expect(r1.isDegraded, isFalse);

      engine.failWith = StateError('OOM');
      final r2 = await run(_Conn(false), () async => 'cloud');
      expect(r2.error!.code, AIResult.errInferenceFailed);
    });
  });

  group('OnDeviceMealSelectionRuleEngine', () {
    const engine = OnDeviceMealSelectionRuleEngine(<String, double>{'expiringPriority': 0.4, 'repetitionPenalty': 0.5});

    test('lọc cứng dị ứng TRƯỚC; món chưa kiểm chứng dị ứng bị loại khi có ràng buộc', () {
      final r = engine.select(
        <MealCandidate>[
          cand('gluten', allergens: <String>{'GLUTEN'}, exp: 1),
          cand('unknown', allergens: null, exp: 1),
          cand('safe', exp: 0.1),
        ],
        const HouseholdConstraints(hardAllergenExclusions: <String>{'GLUTEN'}),
      );
      expect(r.selectedDishId, 'safe');
      expect(r.ruleTrace.any((t) => t.contains('gluten') && t.contains('(hard)')), isTrue);
      expect(r.ruleTrace.any((t) => t.contains('unknown') && t.contains('chưa kiểm chứng')), isTrue);
    });

    test('tag RỖNG nhưng derivation ≠ INGREDIENT_RULE = chưa kiểm chứng → bị loại (không coi là an toàn)', () {
      for (final d in <AllergenDerivation>[
        AllergenDerivation.unknown,
        AllergenDerivation.unverified,
        AllergenDerivation.source,
        AllergenDerivation.manual,
      ]) {
        final r = engine.select(<MealCandidate>[cand('emptyTags', derivation: d, exp: 1)],
            const HouseholdConstraints(hardAllergenExclusions: <String>{'GLUTEN'}));
        expect(r.selectedDishId, isNull, reason: '$d');
      }
    });

    test('trọng số âm/thiếu → fromConfig từ chối', () {
      for (final w in <String>[
        '{"weights":{"expiringPriority":0.6,"repetitionPenalty":-0.5}}',
        '{"weights":{"expiringPriority":0.4}}',
      ]) {
        expect(() => OnDeviceMealSelectionRuleEngine.fromConfig(bytes(w)), throwsFormatException);
      }
    });

    test('tín hiệu NaN / ngoài 0..1 không làm sập hay đảo dấu', () {
      final r = engine.select(<MealCandidate>[cand('nan', exp: double.nan), cand('big', rep: 1.5, exp: 0.1)],
          const HouseholdConstraints(hardAllergenExclusions: <String>{}));
      expect(r.selectedDishId, isNotNull);
      expect(r.ruleTrace, contains('big: 0.04'));
    });

    test('không có ràng buộc → món chưa kiểm chứng KHÔNG bị loại', () {
      final r = engine.select(<MealCandidate>[cand('unknown', allergens: null, exp: 0.9)],
          const HouseholdConstraints(hardAllergenExclusions: <String>{}));
      expect(r.selectedDishId, 'unknown');
    });

    test('xếp hạng mềm: sắp hết hạn cao + ít lặp thắng; thiếu tín hiệu → tái chuẩn hoá', () {
      final r = engine.select(
        <MealCandidate>[
          cand('repeated', exp: 0.9, rep: 1.0), // (0.4*0.9 + 0.5*0) / 0.9 = 0.40
          cand('fresh', exp: 0.5, rep: 0.0), //    (0.4*0.5 + 0.5*1) / 0.9 = 0.78
          cand('onlyExp', exp: 0.7), //            0.4*0.7 / 0.4 = 0.70 (tái chuẩn hoá)
        ],
        const HouseholdConstraints(hardAllergenExclusions: <String>{}),
      );
      expect(r.selectedDishId, 'fresh');
      expect(r.ruleTrace, contains('onlyExp: 0.70'));
    });

    test('mọi món bị loại → selectedDishId null, có trace', () {
      final r = engine.select(<MealCandidate>[cand('a', allergens: <String>{'EGG'})],
          const HouseholdConstraints(hardAllergenExclusions: <String>{'EGG'}));
      expect(r.selectedDishId, isNull);
      expect(r.ruleTrace.last, contains('không còn món'));
    });
  });

  test('OnDeviceInferenceEngineImpl: task NN chưa có runtime → modelUnavailable; task 4 chạy thật', () async {
    final reg = ModelRegistry(loader: memLoader(rulesPackage()));
    await reg.bootstrap();
    final impl = OnDeviceInferenceEngineImpl(reg);
    await expectLater(impl.loadIfNeeded(AITask.receiptOcr),
        throwsA(isA<OnDeviceInferenceException>().having((e) => e.modelUnavailable, 'unavailable', isTrue)));
    final out = await impl.run(AITask.ruleBasedSelection,
        MealSelectionInput(<MealCandidate>[cand('x', exp: 1)], const HouseholdConstraints(hardAllergenExclusions: <String>{})));
    expect((out as MealSelectionOutput).result.selectedDishId, 'x');
    expect(out.confidence, isNull);
  });

  group('Widget §9', () {
    final degraded = AIResult<Object?>.fromOnDevice(data: 1, confidence: 0.82, modelUsed: 'on-device:x@v1', latencyMs: 3);
    final cloud = AIResult<Object?>.fromCloud(1, modelUsed: 'cloud:x');
    final unavailable = AIResult<Object?>.unavailable(AITask.receiptOcr);

    testWidgets('banner/badge CHỈ khi degraded; lỗi unavailable KHÔNG hiện banner', (tester) async {
      await tester.pumpAppWidget(Column(children: <Widget>[OfflineModeBanner(result: degraded), AIResultSourceBadge(result: degraded)]));
      expect(find.byKey(const ValueKey<String>('offline-mode-banner')), findsOneWidget);
      expect(find.text('Ước tính offline · 82%'), findsOneWidget);

      for (final r in <AIResult<Object?>>[cloud, unavailable]) {
        await tester.pumpAppWidget(Column(children: <Widget>[OfflineModeBanner(result: r), AIResultSourceBadge(result: r)]));
        expect(find.byKey(const ValueKey<String>('offline-mode-banner')), findsNothing);
        expect(find.byKey(const ValueKey<String>('ai-source-badge')), findsNothing);
      }
    });
  });
}
