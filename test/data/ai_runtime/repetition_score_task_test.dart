import 'dart:convert';
import 'dart:math';

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
import 'package:smart_kitchen_mobile/data/ai_runtime/tasks/repetition_score_task.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/utils/sha256.dart';

/// Issue #120 — on-device-ai-runtime.md §6.6.
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

class _OtherInput implements InferenceInput {}

const String rulesJson =
    '{"version":1,"windowDays":14,"recentDays":7,"recentScore":1.0,"olderScore":0.5}';
const String v2Dir = 'assets/models/repetition_score/v2';

/// Registry chỉ có package repetition_score/v2. [checksumOf] = bytes dùng để
/// tính checksum trong metadata (mặc định = chính [rules]).
Future<ModelRegistry> registry(
    {String? rules = rulesJson, String? checksumOf}) async {
  final files = <String, String>{
    if (rules != null) ...<String, String>{
      '$v2Dir/metadata.json': jsonEncode(<String, dynamic>{
        'task': 'repetition_score',
        'modelVersion': 2,
        'appMinVersion': '0.1.0',
        'runtime': 'rules-only',
        'payloadFile': 'repetition_rules.json',
        'checksumSha256': sha256Hex(utf8.encode(checksumOf ?? rules)),
        'inputShape': null,
        'inputDType': null,
        'preprocessing': null,
        'outputShape': null,
        'outputType': ModelManifest.outputTypes[AITask.repetitionScore],
        'labelMapFile': null,
        'quantization': 'n/a',
      }),
      '$v2Dir/repetition_rules.json': rules,
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

  final ref = DateTime(2026, 11, 26); // ngày lịch local
  CookedDishRecord cooked(String id, int daysAgo) =>
      CookedDishRecord(dishId: id, cookedAt: DateTime(2026, 11, 26 - daysAgo));
  List<double> scores(List<String> c, List<CookedDishRecord> h,
          [DateTime? day]) =>
      RepetitionScorer.score(c, h, day ?? ref)
          .scores
          .map((s) => s.score)
          .toList();

  group('RepetitionRules (§6.6.1)', () {
    test('hằng số khớp BE MealRepetitionScorer', () {
      expect(RepetitionRules.windowDays, 14);
      expect(RepetitionRules.recentDays, 7);
      expect(RepetitionRules.recentScore, 1.0);
      expect(RepetitionRules.olderScore, 0.5);
    });

    test(
        'verifyPayload: payload hợp lệ (1 hoặc 1.0 đều là số bằng hằng) → không ném',
        () {
      RepetitionRules.verifyPayload(jsonDecode(rulesJson));
      RepetitionRules.verifyPayload(jsonDecode(
          '{"version":1,"windowDays":14,"recentDays":7,"recentScore":1,"olderScore":0.5}'));
    });

    final invalid = <String, Object?>{
      'không phải object': <int>[],
      'null': null,
      'version 2':
          jsonDecode(rulesJson.replaceFirst('"version":1', '"version":2')),
      // LOW-4: ca "số thực" dựa vào `1.0 is! int` — đúng trên Dart VM/AOT
      // (Android/iOS, `flutter test`); trên web `1.0 is int` nên sẽ không ném.
      'version là số thực':
          jsonDecode(rulesJson.replaceFirst('"version":1', '"version":1.0')),
      'thiếu windowDays': (jsonDecode(rulesJson) as Map<String, dynamic>)
        ..remove('windowDays'),
      'windowDays 21': jsonDecode(
          rulesJson.replaceFirst('"windowDays":14', '"windowDays":21')),
      'windowDays là số thực': jsonDecode(
          rulesJson.replaceFirst('"windowDays":14', '"windowDays":14.0')),
      'recentDays là chuỗi': jsonDecode(
          rulesJson.replaceFirst('"recentDays":7', '"recentDays":"7"')),
      'recentScore 0.8': jsonDecode(
          rulesJson.replaceFirst('"recentScore":1.0', '"recentScore":0.8')),
      'olderScore 0.1': jsonDecode(
          rulesJson.replaceFirst('"olderScore":0.5', '"olderScore":0.1')),
      'olderScore null': jsonDecode(
          rulesJson.replaceFirst('"olderScore":0.5', '"olderScore":null')),
      'key thừa similarScore': jsonDecode(rulesJson.replaceFirst(
          '"olderScore":0.5', '"olderScore":0.5,"similarScore":0.3')),
    };
    for (final MapEntry(key: name, value: json) in invalid.entries) {
      test('verifyPayload sai: $name → FormatException', () {
        expect(
            () => RepetitionRules.verifyPayload(json), throwsFormatException);
      });
    }
  });

  group('vnDay (§6.6.2)', () {
    test('UTC → +7h rồi lấy ngày; local → giữ nguyên y/m/d', () {
      expect(vnDay(DateTime.parse('2026-11-24T17:30:00Z')),
          DateTime.utc(2026, 11, 25));
      expect(vnDay(DateTime.parse('2026-11-24T16:30:00Z')),
          DateTime.utc(2026, 11, 24));
      expect(vnDay(DateTime(2026, 11, 20, 23, 59)), DateTime.utc(2026, 11, 20));
      expect(vnDay(DateTime.parse('2026-11-20')), DateTime.utc(2026, 11, 20));
    });

    test('idempotent: vnDay(vnDay(t)) == vnDay(t)', () {
      final d = vnDay(DateTime.parse('2026-11-24T17:30:00Z'));
      expect(vnDay(d), d);
    });
  });

  group('RepetitionScorer — công thức + ca biên (§6.6.1, §6.6.5)', () {
    test('ranh giới days 0/−1/1/7/8/14/15 → 0/0/1.0/1.0/0.5/0.5/0', () {
      final cases = <int, double>{
        0: 0.0,
        -1: 0.0,
        1: 1.0,
        7: 1.0,
        8: 0.5,
        14: 0.5,
        15: 0.0
      };
      for (final MapEntry(key: days, value: expected) in cases.entries) {
        expect(
            scores(<String>['pho'], <CookedDishRecord>[cooked('pho', days)])
                .single,
            expected,
            reason: 'days $days');
      }
    });

    test('nhiều lần nấu → chỉ lần gần nhất quyết định, không cộng dồn', () {
      expect(
          scores(<String>['pho'],
              <CookedDishRecord>[cooked('pho', 10), cooked('pho', 3)]).single,
          1.0);
      expect(
          scores(<String>['pho'],
              <CookedDishRecord>[cooked('pho', 10), cooked('pho', 12)]).single,
          0.5);
      expect(
          scores(<String>[
            'pho'
          ], <CookedDishRecord>[
            cooked('pho', 0),
            cooked('pho', -2),
            cooked('pho', 20),
            cooked('pho', 9)
          ]).single,
          0.5,
          reason:
              'bản ghi cùng ngày / tương lai / ngoài window bị bỏ qua, lấy 9 ngày');
    });

    test('múi giờ quanh nửa đêm: cookedAt UTC quy về ngày VN', () {
      // 2026-11-24T17:30Z = 25/11 00:30 VN → cách 2/12 đúng 7 ngày → 1.0.
      // 2026-11-24T16:30Z = 24/11 23:30 VN → cách 2/12 8 ngày → 0.5.
      final day = DateTime(2026, 12, 2);
      expect(
          scores(<String>[
            'a'
          ], <CookedDishRecord>[
            CookedDishRecord(
                dishId: 'a', cookedAt: DateTime.parse('2026-11-24T17:30:00Z'))
          ], day)
              .single,
          1.0);
      expect(
          scores(<String>[
            'a'
          ], <CookedDishRecord>[
            CookedDishRecord(
                dishId: 'a', cookedAt: DateTime.parse('2026-11-24T16:30:00Z'))
          ], day)
              .single,
          0.5);
      // Với ref 26/11: 17:30Z → 25/11 VN (1 ngày), 16:30Z → 24/11 VN (2 ngày)
      // — cùng nhóm ≤ 7 nên đều 1.0 (kỳ vọng hardcode, qua `score`).
      expect(
          scores(<String>['a', 'b'], <CookedDishRecord>[
            CookedDishRecord(
                dishId: 'a', cookedAt: DateTime.parse('2026-11-24T17:30:00Z')),
            CookedDishRecord(
                dishId: 'b', cookedAt: DateTime.parse('2026-11-24T16:30:00Z')),
          ]),
          <double>[1.0, 1.0]);
    });

    test('cookedAt local DateTime(2026,11,20) đọc nguyên y/m/d → 6 ngày → 1.0',
        () {
      expect(
          scores(<String>[
            'a'
          ], <CookedDishRecord>[
            CookedDishRecord(dishId: 'a', cookedAt: DateTime(2026, 11, 20))
          ]).single,
          1.0);
      expect(
          scores(<String>[
            'a'
          ], <CookedDishRecord>[
            CookedDishRecord(dishId: 'a', cookedAt: DateTime(2026, 11, 18))
          ]).single,
          0.5);
    });

    test(
        'khoá: trim + chữ thường, GIỮ dấu; dishId output = chuỗi input nguyên văn',
        () {
      final r = RepetitionScorer.score(
        <String>[' Pho ', 'pho', 'phở', 'PHỞ'],
        <CookedDishRecord>[cooked('pho', 2), cooked('  Phở', 9)],
        ref,
      );
      expect(r.scores.map((s) => s.dishId),
          <String>[' Pho ', 'pho', 'phở', 'PHỞ']);
      expect(r.scores.map((s) => s.score), <double>[1.0, 1.0, 0.5, 0.5],
          reason: "'phở' không khớp 'pho' (giữ dấu)");
    });

    test('candidate trùng → output 1:1, đúng thứ tự, cùng điểm', () {
      final r = RepetitionScorer.score(<String>['b', 'a', 'b', 'B '],
          <CookedDishRecord>[cooked('b', 1)], ref);
      expect(r.scores.length, 4);
      expect(r.scores.map((s) => (s.dishId, s.score)),
          <(String, double)>[('b', 1.0), ('a', 0.0), ('b', 1.0), ('B ', 1.0)]);
    });

    test('candidate rỗng → []; history rỗng → mọi candidate 0.0', () {
      expect(
          RepetitionScorer.score(
                  <String>[], <CookedDishRecord>[cooked('a', 1)], ref)
              .scores,
          isEmpty);
      expect(
          scores(<String>['a', 'b'], <CookedDishRecord>[]), <double>[0.0, 0.0]);
    });

    test('khoá rỗng sau chuẩn hoá không đặc cách: "" khớp "  "', () {
      expect(scores(<String>[''], <CookedDishRecord>[cooked('  ', 3)]).single,
          1.0);
    });

    test(
        'withinWindowDays luôn = 14 và score ∈ {0, 0.5, 1.0} trên nhiều input ngẫu nhiên',
        () {
      final rnd = Random(120);
      const ids = <String>['a', 'B', ' c ', 'phở', 'pho'];
      for (var i = 0; i < 200; i++) {
        // Rút cận trên MỘT lần/vòng — đặt trong điều kiện `for` sẽ tung lại
        // mỗi lần kiểm và lệch độ dài về 0–2.
        final historyLen = rnd.nextInt(8);
        final candidateLen = rnd.nextInt(6);
        final history = <CookedDishRecord>[
          for (var j = 0; j < historyLen; j++)
            rnd.nextBool()
                ? cooked(ids[rnd.nextInt(ids.length)], rnd.nextInt(24) - 4)
                : CookedDishRecord(
                    dishId: ids[rnd.nextInt(ids.length)],
                    cookedAt: DateTime.utc(2026, 11, 26).subtract(
                        Duration(minutes: rnd.nextInt(60 * 24 * 20)))),
        ];
        final candidates = <String>[
          for (var j = 0; j < candidateLen; j++) ids[rnd.nextInt(ids.length)]
        ];
        final r = RepetitionScorer.score(candidates, history, ref);
        expect(r.scores.length, candidates.length);
        for (final s in r.scores) {
          expect(s.withinWindowDays, RepetitionRules.windowDays);
          expect(s.withinWindowDays, 14);
          expect(<double>{0.0, 0.5, 1.0}, contains(s.score));
          expect(s.score, inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('OnDeviceInferenceEngineImpl — repetitionScore (§6.6.4)', () {
    test('payload hợp lệ → chạy; output confidence == null', () async {
      final engine = OnDeviceInferenceEngineImpl(await registry());
      final out = await engine.run(
          AITask.repetitionScore,
          RepetitionScoreInput(
              <String>['a'], <CookedDishRecord>[cooked('a', 8)], ref));
      expect(out, isA<RepetitionScoreOutput>());
      expect(out.confidence, isNull);
      expect((out as RepetitionScoreOutput).result.scores.single.score, 0.5);
    });

    final badPayloads = <String, String>{
      'JSON hỏng': '{oops',
      'version 2': rulesJson.replaceFirst('"version":1', '"version":2'),
      'windowDays lệch hằng Dart':
          rulesJson.replaceFirst('"windowDays":14', '"windowDays":21'),
      'recentScore lệch hằng Dart':
          rulesJson.replaceFirst('"recentScore":1.0', '"recentScore":0.8'),
    };
    for (final MapEntry(key: name, value: payload) in badPayloads.entries) {
      test('$name → OnDeviceInferenceException(modelUnavailable)', () async {
        final reg = await registry(rules: payload);
        expect(reg.isAvailable(AITask.repetitionScore), isTrue,
            reason: 'checksum khớp — lỗi chỉ lộ ở engine');
        final engine = OnDeviceInferenceEngineImpl(reg);
        await expectLater(
          engine.loadIfNeeded(AITask.repetitionScore),
          throwsA(isA<OnDeviceInferenceException>()
              .having((e) => e.modelUnavailable, 'modelUnavailable', isTrue)),
        );
        final r =
            await HybridAIRunner(ConnectivityGate(_Conn(false)), engine, reg)
                .runOnDevice<RepetitionScoreResult>(
          task: AITask.repetitionScore,
          input: RepetitionScoreInput(
              const <String>['a'], const <CookedDishRecord>[], ref),
          fromOutput: (o) => (o as RepetitionScoreOutput).result,
          offlineFallback: true,
        );
        expect(r.error!.code, AIResult.errModelUnavailable);
      });
    }

    test('checksum lệch → registry checksumMismatch, task unavailable',
        () async {
      final reg = await registry(checksumOf: '{"tampered":true}');
      expect(reg.unavailableReason(AITask.repetitionScore),
          ModelUnavailableReason.checksumMismatch);
      expect(reg.isAvailable(AITask.repetitionScore), isFalse);
    });

    test('input sai kiểu → inferenceFailed (không phải modelUnavailable)',
        () async {
      final reg = await registry();
      final r = await HybridAIRunner(ConnectivityGate(_Conn(false)),
              OnDeviceInferenceEngineImpl(reg), reg)
          .runOnDevice<RepetitionScoreResult>(
        task: AITask.repetitionScore,
        input: _OtherInput(),
        fromOutput: (o) => (o as RepetitionScoreOutput).result,
        offlineFallback: true,
      );
      expect(r.error!.code, AIResult.errInferenceFailed);
    });
  });

  group('RepetitionScoreRepositoryImpl — bảng §8 + cloud == null (§6.6.6)', () {
    late ModelRegistry reg;
    late _Engine engine;
    const onDeviceResult = RepetitionScoreResult(scores: <DishRepetitionScore>[
      DishRepetitionScore(dishId: 'a', score: 1.0, withinWindowDays: 14)
    ]);
    const cloudResult = RepetitionScoreResult(scores: <DishRepetitionScore>[
      DishRepetitionScore(dishId: 'cloud', score: 0.5, withinWindowDays: 14)
    ]);

    setUp(() async {
      reg = await registry();
      engine = _Engine(const RepetitionScoreOutput(onDeviceResult));
    });

    RepetitionScoreRepositoryImpl repo(_Conn conn,
            {DateTime Function()? clock}) =>
        RepetitionScoreRepositoryImpl(
            HybridAIRunner(ConnectivityGate(conn), engine, reg),
            clock: clock);

    test('offline biết trước → on-device isDegraded, KHÔNG gọi cloud',
        () async {
      var called = false;
      final r = await repo(_Conn(false))
          .score(<String>['a'], <CookedDishRecord>[], referenceDate: ref,
              cloud: () async {
        called = true;
        return cloudResult;
      });
      expect(called, isFalse);
      expect(
          (r.success, r.source, r.isDegraded), (true, AISource.onDevice, true));
      expect(r.modelUsed, 'on-device:repetition_score@v2');
      expect(r.confidence, isNull);
      expect(r.data, same(onDeviceResult));
    });

    test('online + cloud OK → fromCloud, engine không chạy', () async {
      final r = await repo(_Conn(true)).score(
          <String>['a'], <CookedDishRecord>[],
          cloud: () async => cloudResult);
      expect((r.source, r.modelUsed, r.data!.scores.single.dishId),
          (AISource.cloud, 'cloud:repetition-score', 'cloud'));
      expect(engine.runs, 0);
    });

    test('NetworkException + re-check offline → on-device', () async {
      final conn = _Conn(true);
      final r = await repo(conn).score(<String>['a'], <CookedDishRecord>[],
          cloud: () async {
        conn.online = false;
        throw NetworkException();
      });
      expect((r.source, r.offlineFallback, r.isDegraded),
          (AISource.onDevice, true, true));
    });

    test('NetworkException + re-check VẪN online → rethrow (Guard #1)',
        () async {
      await expectLater(
          repo(_Conn(true)).score(<String>['a'], <CookedDishRecord>[],
              cloud: () async => throw NetworkException()),
          throwsA(isA<NetworkException>()));
      expect(engine.runs, 0);
    });

    test('ServerException → rethrow, engine không bị gọi', () async {
      await expectLater(
          repo(_Conn(true)).score(<String>['a'], <CookedDishRecord>[],
              cloud: () async =>
                  throw ServerException('ERR_AI_SERVICE_DOWN', 'x')),
          throwsA(isA<ServerException>()));
      expect(engine.runs, 0);
    });

    test('online + cloud == null → on-device, isDegraded == false', () async {
      final r =
          await repo(_Conn(true)).score(<String>['a'], <CookedDishRecord>[]);
      expect((r.success, r.source, r.offlineFallback, r.isDegraded),
          (true, AISource.onDevice, false, false));
      expect(engine.runs, 1);
    });

    test(
        'referenceDate truyền thẳng (đã quy đổi ngày VN) vào input; candidates/history giữ nguyên',
        () async {
      final history = <CookedDishRecord>[cooked('a', 1)];
      await repo(_Conn(false)).score(<String>['a', 'a'], history,
          referenceDate: DateTime.parse('2026-11-25T18:00:00Z'));
      final input = engine.lastInput! as RepetitionScoreInput;
      expect(input.referenceDay, DateTime.utc(2026, 11, 26));
      expect(input.candidates, <String>['a', 'a']);
      expect(input.history, same(history));
    });

    test(
        'referenceDate DateTime.utc (isUtc) → +7h: 25/11 17:00Z = 26/11 VN; 16:59Z = 25/11 VN',
        () async {
      final r = repo(_Conn(false));
      await r.score(<String>['a'], <CookedDishRecord>[],
          referenceDate: DateTime.utc(2026, 11, 25, 17));
      expect((engine.lastInput! as RepetitionScoreInput).referenceDay,
          DateTime.utc(2026, 11, 26));
      await r.score(<String>['a'], <CookedDishRecord>[],
          referenceDate: DateTime.utc(2026, 11, 25, 16, 59));
      expect((engine.lastInput! as RepetitionScoreInput).referenceDay,
          DateTime.utc(2026, 11, 25));
    });

    test(
        'referenceDate null + clock UTC 2026-11-25T18:00Z → hôm nay VN = 26/11',
        () async {
      await repo(_Conn(false), clock: () => DateTime.utc(2026, 11, 25, 18))
          .score(<String>['a'], <CookedDishRecord>[]);
      expect((engine.lastInput! as RepetitionScoreInput).referenceDay,
          DateTime.utc(2026, 11, 26));
    });

    test(
        'isAvailable == false (thiếu package) → AIResult.unavailable, không throw',
        () async {
      reg = await registry(rules: null);
      expect(reg.isAvailable(AITask.repetitionScore), isFalse);
      final r =
          await repo(_Conn(false)).score(<String>['a'], <CookedDishRecord>[]);
      expect((r.success, r.error!.code), (false, AIResult.errModelUnavailable));
      expect(engine.runs, 0);
    });
  });

  group('Asset THẬT repetition_score/v2 (§6.6.8)', () {
    test(
        'rootBundle thật → available, payload có, modelUsed @v2; repository + engine thật offline → success',
        () async {
      final reg = ModelRegistry(appVersion: AppVersion.current);
      await reg.bootstrap();
      expect(reg.isAvailable(AITask.repetitionScore), isTrue);
      expect(reg.payloadFor(AITask.repetitionScore), isNotNull);
      expect(reg.manifestFor(AITask.repetitionScore).modelUsed,
          'on-device:repetition_score@v2');

      final repository = RepetitionScoreRepositoryImpl(HybridAIRunner(
          ConnectivityGate(_Conn(false)),
          OnDeviceInferenceEngineImpl(reg),
          reg));
      final r = await repository.score(
        <String>['Phở bò', 'Cơm tấm', 'Bún chả'],
        <CookedDishRecord>[
          cooked('phở bò', 3),
          cooked('Cơm tấm', 10),
          cooked('Bún chả', 20)
        ],
        referenceDate: ref,
      );
      expect(r.success, isTrue);
      expect(r.isDegraded, isTrue);
      expect(r.modelUsed, 'on-device:repetition_score@v2');
      expect(
          r.data!.scores.map((s) => (s.dishId, s.score, s.withinWindowDays)), <(
        String,
        double,
        int
      )>[('Phở bò', 1.0, 14), ('Cơm tấm', 0.5, 14), ('Bún chả', 0.0, 14)]);
    });
  });
}
