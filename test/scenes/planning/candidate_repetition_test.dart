import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/vote_session_summary.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/candidate_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/repetition_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/meal_plan_candidate.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/repetition_summary.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/candidate_insight_scene.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/planning_routes.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/repetition_summary_scene.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/candidate_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/repetition_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/widgets/repetition_bar_chart.dart';
import 'package:smart_kitchen_mobile/scenes/planning/widgets/soft_score_breakdown_panel.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_empty_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

/// Shape thật của `MealPlanCandidateResponse` (BE): `algorithmRecommended`
/// không tiền tố `is`; `softScoreBreakdown` = `feature_breakdown` snake_case của AI.
Map<String, dynamic> candidateJson(
  String id, {
  String sessionId = 's1',
  String status = 'PASSED',
  bool recommended = false,
  double? score = 0.5,
  String? blockedReason,
  String evaluatedAt = '2026-10-19T03:00:00Z',
}) =>
    <String, dynamic>{
      'id': id,
      'sessionId': sessionId,
      'recipeId': 'r-$id',
      'recipeName': 'Món $id',
      'hardConstraintStatus': status,
      'blockedReason': blockedReason,
      'algorithmRecommended': recommended,
      'softScore': score,
      'softScoreBreakdown': status == 'BLOCKED'
          ? null
          : <String, dynamic>{
              'expiry_urgency': 0.86,
              'repetition_penalty': 0.12,
              'effort_fit': null,
              'weights': <String, dynamic>{'expiry_urgency': 0.28, 'repetition_penalty': -0.22},
              'contributions': <String, dynamic>{'expiry_urgency': 0.39},
              'profile_version': 'v2',
            },
      'repetitionPenalty': 0.12,
      'allergenTags': <String>['GLUTEN'],
      'evaluatedAt': evaluatedAt,
    };

MealPlanCandidate candidate(String id, {String sessionId = 's1', String status = 'PASSED', bool recommended = false, double? score = 0.5, String? blockedReason, String evaluatedAt = '2026-10-19T03:00:00Z'}) =>
    MealPlanCandidate.fromJson(candidateJson(id,
        sessionId: sessionId, status: status, recommended: recommended, score: score, blockedReason: blockedReason, evaluatedAt: evaluatedAt));

class FakeCandidateApi implements CandidateApi {
  List<MealPlanCandidate> items = <MealPlanCandidate>[];
  ApiException? error;
  int calls = 0;
  Completer<void>? gate;

  @override
  Future<List<MealPlanCandidate>> list(String mealPlanId) async {
    calls++;
    await gate?.future;
    if (error != null) throw error!;
    return items;
  }
}

class FakeRepetitionApi implements RepetitionApi {
  final List<int> requested = <int>[];
  ApiException? error;
  List<RepeatedDish> dishes = <RepeatedDish>[];
  Completer<void>? gate;

  @override
  Future<RepetitionSummary> get({required int windowDays}) async {
    requested.add(windowDays);
    await gate?.future;
    if (error != null) throw error!;
    return RepetitionSummary(
      windowDays: windowDays,
      windowStart: DateTime(2026, 10, 5),
      windowEnd: DateTime(2026, 10, 19),
      repeatedDishes: dishes,
    );
  }
}

VoteSessionSummary session(String id) => VoteSessionSummary(
      sessionId: id,
      slotId: 'slot-1',
      dishId: 'dish-1',
      status: VoteSessionUiStatus.open,
      suggestions: const [],
      tally: const [],
    );

RepeatedDish repeated(String name, int count) => RepeatedDish(
      recipeId: 'r-$name',
      recipeName: name,
      occurrenceCount: count,
      occurrences: <RepetitionOccurrence>[
        for (var i = 0; i < count; i++)
          RepetitionOccurrence(mealPlanId: 'p', mealDate: DateTime(2026, 10, 10 + i), slotLabel: 'Bữa tối'),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API parse theo BE thật', () {
    final storageChannel = FakeSecureStorageChannel();
    setUpAll(storageChannel.install);
    tearDownAll(storageChannel.uninstall);

    DioClient clientFor(Future<ResponseBody> Function(RequestOptions) handler, List<RequestOptions> sink) {
      final adapter = FakeHttpAdapter((o) {
        sink.add(o);
        return handler(o);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = adapter;
      return DioClient.build(tokenStorage: TokenStorage(), dio: dio);
    }

    test('candidates: algorithmRecommended + breakdown động, không hardcode trọng số', () async {
      final reqs = <RequestOptions>[];
      final api = CandidateApi(clientFor(
          (_) async => jsonResponse(200, successEnvelope(<dynamic>[candidateJson('a', recommended: true)])), reqs));

      final c = (await api.list('plan-1')).single;

      expect(reqs.single.path, '/api/v1/meal-plans/plan-1/candidates');
      expect(c.isAlgorithmRecommended, isTrue);
      expect(c.sessionId, 's1');
      expect(c.profileVersion, 'v2');
      expect(c.features.map((f) => f.key), <String>['expiry_urgency', 'repetition_penalty', 'effort_fit']);
      final expiry = c.features.first;
      expect(expiry.value, 0.86);
      expect(expiry.weight, 0.28);
      expect(expiry.contribution, 0.39);
      expect(c.features.last.value, isNull);
    });

    test('candidates: feature trong inactive_features (không tính điểm) không được vẽ', () {
      final json = candidateJson('i');
      (json['softScoreBreakdown'] as Map<String, dynamic>)
        ..['graph_path'] = 0.5
        ..['inactive_features'] = <String>['graph_path'];
      final c = MealPlanCandidate.fromJson(json);
      expect(c.features.map((f) => f.key), isNot(contains('graph_path')));
      expect(c.features.map((f) => f.key), contains('expiry_urgency'));
    });

    test('candidates: BLOCKED không có breakdown → features rỗng, không throw', () {
      final c = candidate('b', status: 'BLOCKED', score: null, blockedReason: 'Gluten');
      expect(c.isBlocked, isTrue);
      expect(c.features, isEmpty);
      expect(c.softScore, isNull);
    });

    test('candidates: hardConstraintStatus null/lạ → BLOCKED (fail-safe, không hiện là an toàn)', () {
      for (final raw in <Object?>[null, 'PENDING', 'passed']) {
        final json = candidateJson('u')..['hardConstraintStatus'] = raw;
        expect(MealPlanCandidate.fromJson(json).isBlocked, isTrue, reason: 'status=$raw');
      }
    });

    test('candidates: lỗi BE → ApiException giữ code', () async {
      final api = CandidateApi(clientFor(
          (_) async => jsonResponse(404, errorEnvelope('ERR_MEAL_PLAN_NOT_FOUND', 'x')), <RequestOptions>[]));
      await expectLater(api.list('p'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'ERR_MEAL_PLAN_NOT_FOUND')));
    });

    test('repetition: gửi windowDays, parse LocalDate, sort giảm dần theo số lần', () async {
      final reqs = <RequestOptions>[];
      final api = RepetitionApi(clientFor(
          (_) async => jsonResponse(
              200,
              successEnvelope(<String, dynamic>{
                'windowDays': 7,
                'windowStart': '2026-10-12',
                'windowEnd': '2026-10-19',
                'repeatedDishes': <dynamic>[
                  <String, dynamic>{'recipeId': 'r1', 'recipeName': 'Canh', 'occurrenceCount': 2, 'occurrences': <dynamic>[]},
                  <String, dynamic>{
                    'recipeId': 'r2',
                    'recipeName': 'Cá kho',
                    'occurrenceCount': 3,
                    'occurrences': <dynamic>[
                      <String, dynamic>{'mealPlanId': 'p', 'mealDate': '2026-10-13', 'slotLabel': 'Bữa tối'},
                    ],
                  },
                ],
              })),
          reqs));

      final s = await api.get(windowDays: 7);

      expect(reqs.single.queryParameters['windowDays'], 7);
      expect(s.windowStart, DateTime(2026, 10, 12));
      expect(s.repeatedDishes.map((d) => d.recipeName), <String>['Cá kho', 'Canh']);
      expect(s.repeatedDishes.first.occurrences.single.slotLabel, 'Bữa tối');
    });
  });

  group('CandidateStore', () {
    late FakeCandidateApi api;
    setUp(() => api = FakeCandidateApi());

    test('sessionId thật → chỉ nhóm của phiên đó, sắp ⭐ → PASSED theo điểm → BLOCKED', () async {
      api.items = <MealPlanCandidate>[
        candidate('blocked', status: 'BLOCKED', score: null),
        candidate('low', score: 0.2),
        candidate('star', recommended: true, score: 0.4),
        candidate('high', score: 0.9),
        candidate('other', sessionId: 's2'),
      ];
      final store = CandidateStore(api, 'plan-1', sessionId: 's1');
      await store.load();

      final groups = (store.groupsState as SuccessState<List<CandidateGroup>>).data;
      expect(groups, hasLength(1));
      expect(groups.single.candidates.map((c) => c.id), <String>['star', 'high', 'low', 'blocked']);
    });

    test('sessionId sentinel → không lọc, nhóm cả tuần, phiên mới nhất trước', () async {
      api.items = <MealPlanCandidate>[
        candidate('a', sessionId: 'old', evaluatedAt: '2026-10-18T01:00:00Z'),
        candidate('b', sessionId: 'new', evaluatedAt: '2026-10-19T01:00:00Z'),
      ];
      final store = CandidateStore(api, 'plan-1', sessionId: VoteSessionSummary.unknownSessionId);
      await store.load();

      final groups = (store.groupsState as SuccessState<List<CandidateGroup>>).data;
      expect(groups.map((g) => g.sessionId), <String>['new', 'old']);
    });

    test('món chưa từng mở phiên → rỗng, KHÔNG hiện ứng viên của món khác, không gọi API', () async {
      api.items = <MealPlanCandidate>[candidate('x', sessionId: 'other-dish')];
      final store = CandidateStore(api, 'plan-1', dishHasNoSession: true, openSession: () async => session('s9'));
      await store.load();
      expect(store.groupsState, isA<EmptyState<List<CandidateGroup>>>());
      expect(api.calls, 0);
      expect(store.canGenerate, isTrue);
    });

    test('generate → lấy sessionId thật từ vote/open rồi lọc đúng phiên mới', () async {
      api.items = <MealPlanCandidate>[candidate('x', sessionId: 'other-dish'), candidate('mine', sessionId: 's9')];
      final store = CandidateStore(api, 'plan-1', dishHasNoSession: true, openSession: () async => session('s9'));
      await store.load();

      final ok = await store.generate();

      expect(ok, isTrue);
      expect(store.sessionId, 's9');
      final groups = (store.groupsState as SuccessState<List<CandidateGroup>>).data;
      expect(groups.single.candidates.single.id, 'mine');
    });

    test('generate lỗi AI → failure, giữ lỗi; không có openSession thì không sinh', () async {
      final store = CandidateStore(api, 'plan-1',
          dishHasNoSession: true, openSession: () async => throw BusinessException('ERR_AI_TIMEOUT', 'AI chậm'));
      expect(await store.generate(), isFalse);
      expect(store.generateError!.code, 'ERR_AI_TIMEOUT');

      final weekStore = CandidateStore(api, 'plan-1');
      expect(weekStore.canGenerate, isFalse);
      expect(await weekStore.generate(), isFalse);
    });

    test('đã biết phiên thật → không sinh lại (tránh 409 → sentinel làm mất bộ lọc phiên)', () async {
      var opened = 0;
      final store = CandidateStore(api, 'plan-1', sessionId: 's1', openSession: () async {
        opened++;
        return session(VoteSessionSummary.unknownSessionId);
      });
      await store.load();
      expect(await store.generate(), isFalse);
      expect(opened, 0);
      expect(store.sessionId, 's1');
    });

    test('candidatesOf: chỉ gửi slotId+dishId khi có đủ cả hai; noSession=1', () {
      expect(PlanningRoutes.candidatesOf('p1'), '/meal-plan/plan/p1/candidates');
      final uri = Uri.parse(PlanningRoutes.candidatesOf('p1',
          sessionId: 's1', slotId: 'sl', dishId: 'd', dishHasNoSession: true));
      expect(uri.queryParameters, <String, String>{'sessionId': 's1', 'slotId': 'sl', 'dishId': 'd', 'noSession': '1'});
      // Món đã chốt: editor truyền slotId=null → không lộ dishId → không sinh được.
      expect(Uri.parse(PlanningRoutes.candidatesOf('p1', dishId: 'd')).queryParameters, isEmpty);
    });

    test('allBlocked chỉ khi mọi ứng viên BLOCKED; [] không tính', () {
      expect(const CandidateGroup(sessionId: 's', candidates: <MealPlanCandidate>[]).allBlocked, isFalse);
      expect(
        CandidateGroup(sessionId: 's', candidates: <MealPlanCandidate>[candidate('a', status: 'BLOCKED', score: null)]).allBlocked,
        isTrue,
      );
    });

    test('load lỗi → ErrorState', () async {
      api.error = ServerException('ERR_SERVER', 'down');
      final store = CandidateStore(api, 'plan-1');
      await store.load();
      expect(store.groupsState, isA<ErrorState<List<CandidateGroup>>>());
    });
  });

  group('RepetitionStore', () {
    test('mặc định 14; đổi 7 gọi lại; giá trị ngoài enum bị bỏ qua', () async {
      final api = FakeRepetitionApi();
      final store = RepetitionStore(api);
      await store.load();
      await store.setWindowDays(7);
      await store.setWindowDays(30);
      await store.setWindowDays(7);
      expect(api.requested, <int>[14, 7]);
      expect(store.windowDays, 7);
    });

    test('[] là SuccessState (empty tích cực), không phải lỗi', () async {
      final store = RepetitionStore(FakeRepetitionApi());
      await store.load();
      final s = (store.summaryState as SuccessState<RepetitionSummary>).data;
      expect(s.repeatedDishes, isEmpty);
    });

    test('response cũ (14 ngày) về SAU không ghi đè window mới (7 ngày)', () async {
      final slow = Completer<void>();
      final api = FakeRepetitionApi()..gate = slow;
      final store = RepetitionStore(api);
      final first = store.load(); // 14 ngày, treo
      api.gate = null;
      await store.setWindowDays(7); // xong trước
      slow.complete();
      await first;
      expect(api.requested, <int>[14, 7]);
      expect((store.summaryState as SuccessState<RepetitionSummary>).data.windowDays, 7);
    });
  });

  group('Widget', () {
    tearDown(Get.reset);

    testWidgets('dòng legacy (evaluatedAt=null) → badge CHƯA kiểm chứng, không phải "đã qua"', (tester) async {
      final legacy = MealPlanCandidate.fromJson(candidateJson('legacy')..['evaluatedAt'] = null);
      expect(legacy.isUnverified, isTrue);
      expect(
        CandidateGroup.sortForDisplay(<MealPlanCandidate>[legacy, candidate('ok', score: 0.1)]).map((c) => c.id),
        <String>['ok', 'legacy'],
      );
      final api = FakeCandidateApi()..items = <MealPlanCandidate>[legacy];
      Get.put<CandidateStore>(CandidateStore(api, 'plan-1', sessionId: 's1'));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('candidate-badge-unverified')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('candidate-badge-passed')), findsNothing);
    });

    testWidgets('generate lỗi không từ BE (StateError) → copy l10n, không lộ message nội bộ', (tester) async {
      Get.put<CandidateStore>(CandidateStore(FakeCandidateApi(), 'plan-1',
          dishHasNoSession: true, openSession: () async => throw StateError('no plan')));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('candidate-generate')));
      await tester.pumpAndSettle();
      expect(find.text('Không sinh được gợi ý.'), findsOneWidget);
    });

    testWidgets('CandidateInsightScene: loading → success với đủ 3 badge, BLOCKED không có bảng điểm', (tester) async {
      final api = FakeCandidateApi()
        ..gate = Completer<void>()
        ..items = <MealPlanCandidate>[
          candidate('star', recommended: true, score: 0.8),
          candidate('pass', score: 0.5),
          candidate('block', status: 'BLOCKED', score: null, blockedReason: 'Gluten'),
        ];
      Get.put<CandidateStore>(CandidateStore(api, 'plan-1', sessionId: 's1'));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      expect(find.byType(AppLoadingView), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('candidate-explainer')), findsOneWidget);

      api.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('candidate-badge-final')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('candidate-badge-passed')), findsOneWidget);
      expect(find.text('Bị loại — Gluten'), findsOneWidget);
      // Chỉ lựa chọn cuối cùng mở sẵn bảng điểm.
      expect(find.byType(SoftScoreBreakdownPanel), findsOneWidget);
      expect(find.text('Thực phẩm sắp hết hạn'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('candidate-generate')), findsNothing);
    });

    testWidgets('CandidateInsightScene: toàn bộ BLOCKED → banner, card vẫn hiện (I7)', (tester) async {
      final api = FakeCandidateApi()
        ..items = <MealPlanCandidate>[candidate('b1', status: 'BLOCKED', score: null)];
      Get.put<CandidateStore>(CandidateStore(api, 'plan-1', sessionId: 's1'));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('candidate-all-blocked-s1')), findsOneWidget);
      expect(find.text('Bị loại — dị ứng chưa kiểm chứng'), findsOneWidget);
    });

    testWidgets('CandidateInsightScene: chế độ cả tuần chỉ 1 phiên → vẫn hiện tiêu đề phiên', (tester) async {
      final api = FakeCandidateApi()..items = <MealPlanCandidate>[candidate('a', sessionId: 'other-dish')];
      Get.put<CandidateStore>(CandidateStore(api, 'plan-1', sessionId: VoteSessionSummary.unknownSessionId));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Phiên gợi ý'), findsOneWidget);
    });

    testWidgets('SoftScoreBreakdownPanel: repetition_penalty không có trọng số vẫn tô cảnh báo', (tester) async {
      await tester.pumpAppWidget(const SoftScoreBreakdownPanel(
        features: <SoftScoreFeature>[SoftScoreFeature(key: 'repetition_penalty', value: 0.8)],
      ));
      final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.color, AppColors.warning);
    });

    testWidgets('SoftScoreBreakdownPanel: feature KG của AI có nhãn l10n, không lộ key snake_case', (tester) async {
      await tester.pumpAppWidget(const SoftScoreBreakdownPanel(
        features: <SoftScoreFeature>[
          SoftScoreFeature(key: 'nutrient_balance', value: 0.4),
          SoftScoreFeature(key: 'risk_penalty', value: 0.3),
          SoftScoreFeature(key: 'constraint_match', value: 0.2),
          SoftScoreFeature(key: 'graph_path', value: 0.1),
        ],
      ));
      for (final key in <String>['nutrient_balance', 'risk_penalty', 'constraint_match', 'graph_path']) {
        expect(find.text(key), findsNothing, reason: key);
      }
    });

    testWidgets('CandidateInsightScene: đã biết phiên nhưng rỗng → KHÔNG hiện nút Sinh', (tester) async {
      Get.put<CandidateStore>(CandidateStore(FakeCandidateApi(), 'plan-1',
          sessionId: 's1', openSession: () async => session('s1')));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('candidate-generate')), findsNothing);
    });

    testWidgets('CandidateInsightScene: empty món mới → nút Sinh; bấm → hiện danh sách', (tester) async {
      final api = FakeCandidateApi()..items = <MealPlanCandidate>[candidate('mine', sessionId: 's9', recommended: true)];
      Get.put<CandidateStore>(CandidateStore(api, 'plan-1', dishHasNoSession: true, openSession: () async => session('s9')));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.byType(AppEmptyView), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('candidate-generate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('candidate-badge-final')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('candidate-generate')), findsNothing);
    });

    testWidgets('CandidateInsightScene: error + generate lỗi → banner lỗi', (tester) async {
      Get.put<CandidateStore>(CandidateStore(FakeCandidateApi()..error = ServerException('ERR_SERVER', 'down'), 'plan-1'));
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorView), findsOneWidget);

      Get.reset();
      Get.put<CandidateStore>(CandidateStore(FakeCandidateApi(), 'plan-1',
          dishHasNoSession: true, openSession: () async => throw BusinessException('ERR_AI_TIMEOUT', 'AI chậm')));
      await tester.pumpAppWidget(const SizedBox(), wrapInScaffold: false);
      await tester.pumpAppWidget(const CandidateInsightScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('candidate-generate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('candidate-generate-error')), findsOneWidget);
      expect(find.text('AI chậm'), findsOneWidget);
    });

    testWidgets('RepetitionSummaryScene: loading → empty tích cực → đổi 7 ngày', (tester) async {
      final api = FakeRepetitionApi()..gate = Completer<void>();
      Get.put<RepetitionStore>(RepetitionStore(api));
      await tester.pumpAppWidget(const RepetitionSummaryScene(), wrapInScaffold: false);
      expect(find.byType(AppLoadingView), findsOneWidget);

      api.gate!.complete();
      api.gate = null;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('repetition-empty')), findsOneWidget);
      expect(find.textContaining('14 ngày qua'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('repetition-window-7')));
      await tester.pumpAndSettle();
      expect(api.requested.last, 7);
      expect(find.textContaining('7 ngày qua'), findsOneWidget);
    });

    testWidgets('RepetitionSummaryScene: có món lặp → biểu đồ + danh sách; lỗi → AppErrorView', (tester) async {
      final api = FakeRepetitionApi()..dishes = <RepeatedDish>[repeated('Cá kho', 3), repeated('Canh', 2)];
      Get.put<RepetitionStore>(RepetitionStore(api));
      await tester.pumpAppWidget(const RepetitionSummaryScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.byType(RepetitionBarChart), findsOneWidget);
      expect(find.text('3 lần'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('repetition-dish-r-Canh')), findsOneWidget);

      Get.reset();
      Get.put<RepetitionStore>(RepetitionStore(FakeRepetitionApi()..error = ServerException('ERR_SERVER', 'down')));
      await tester.pumpAppWidget(const SizedBox(), wrapInScaffold: false);
      await tester.pumpAppWidget(const RepetitionSummaryScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorView), findsOneWidget);
    });
  });
}
