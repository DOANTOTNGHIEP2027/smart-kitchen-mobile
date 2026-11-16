import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_attendance_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/scenes/meal_slot_editor_scene.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/candidate_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/scenes/weekly_meal_plan_scene.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/suggestion_card.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/repetition_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/meal_plan_candidate.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/repetition_summary.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/candidate_insight_scene.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/planning_routes.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/repetition_summary_scene.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/candidate_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/repetition_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/widgets/candidate_card.dart';
import 'package:smart_kitchen_mobile/scenes/planning/widgets/soft_score_breakdown_panel.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import '../mealplan/fake_meal_plan_api.dart';
import 'candidate_repetition_test.dart' show candidateJson, FakeCandidateApi;

class _Session extends Mock implements SessionStore {}

class _Attendance extends Mock implements MealAttendanceApi {}

class _PendingApi implements RepetitionApi {
  final requests = <(int, Completer<RepetitionSummary>)>[];
  @override
  Future<RepetitionSummary> get({required int windowDays}) {
    final pending = Completer<RepetitionSummary>();
    requests.add((windowDays, pending));
    return pending.future;
  }
}

Map<String, dynamic> summaryJson({int days = 14, bool empty = false}) => {
      'windowDays': days,
      'windowStart': days == 14 ? '2026-07-25' : '2026-12-25',
      'windowEnd': days == 14 ? '2026-08-08' : '2027-01-01',
      'repeatedDishes': [
        if (!empty)
          {
            'recipeId': 'r',
            'recipeName': 'Canh',
            'occurrenceCount': 2,
            'occurrences': [
              for (final slot in ['Trưa', 'Tối'])
                {'mealPlanId': 'p', 'mealDate': '2026-08-08', 'slotLabel': slot}
            ]
          }
      ]
    };

Future<void> pumpLocalized(WidgetTester tester, Widget home,
        {String locale = 'vi',
        double scale = 1,
        List<GetPage<dynamic>>? pages}) =>
    tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      getPages: pages,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ));

Finder get range => find.byKey(const ValueKey<String>('repetition-range'));

void main() {
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);
  tearDown(Get.reset);

  RepetitionApi apiFor(Future<ResponseBody> Function(RequestOptions) handler) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = FakeHttpAdapter(handler);
    return RepetitionApi(
        DioClient.build(tokenStorage: TokenStorage(), dio: dio));
  }

  testWidgets('B01 weekly action opens household summary with lookback only',
      (tester) async {
    final requests = <RequestOptions>[];
    Get.put<RepetitionApi>(apiFor((o) async {
      requests.add(o);
      return jsonResponse(200, successEnvelope(summaryJson(empty: true)));
    }));
    final plans = MealPlanStore(
        suggestionApi: FakeMealSuggestionApi(),
        api: FakeMealPlanApi()
          ..onGetWeek = (_) async => MealPlanDto(
              id: 'p',
              householdId: 'h',
              weekStart: DateTime(2040, 1, 2),
              status: 'DRAFT',
              slots: []));
    Get.put<MealPlanStore>(plans);
    final session = _Session();
    when(() => session.role).thenReturn('MEMBER');
    Get.put<SessionStore>(session);
    await pumpLocalized(tester, const WeeklyMealPlanScene(), pages: [
      GetPage(
          name: PlanningRoutes.repetitionSummary,
          page: () => const RepetitionSummaryScene(),
          binding: RepetitionSummaryBinding())
    ]);
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey<String>('meal-plan-repetition'));
    expect(tester.widget<IconButton>(action).tooltip,
        'Xem món lặp trong kế hoạch');
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Món lặp trong kế hoạch'), findsOneWidget);
    expect(requests.single.path,
        '/api/v1/households/me/meal-plans/repetition-summary');
    expect(requests.single.queryParameters, {'windowDays': 14});
    expect(
        tester.widget<Text>(range).data, 'Từ 25 thg 7, 2026 đến 8 thg 8, 2026');
  });

  for (final locale in ['vi', 'en']) {
    for (final empty in [true, false]) {
      testWidgets(
          'B02-04/B07 $locale empty=$empty: server dates, same-day count, 320px/2x',
          (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final requested = <int>[];
        Get.put<RepetitionStore>(RepetitionStore(apiFor((o) async {
          final days = o.queryParameters['windowDays'] as int;
          requested.add(days);
          return jsonResponse(
              200, successEnvelope(summaryJson(days: days, empty: empty)));
        })));
        await pumpLocalized(tester, const RepetitionSummaryScene(),
            locale: locale, scale: 2);
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
            tester.element(find.byType(RepetitionSummaryScene)));
        expect(
            tester.widget<Text>(range).data,
            locale == 'vi'
                ? 'Từ 25 thg 7, 2026 đến 8 thg 8, 2026'
                : 'From Jul 25, 2026 to Aug 8, 2026');
        if (empty) {
          final emptyText = find.text(l10n.planningRepetitionEmpty(14));
          await tester.ensureVisible(emptyText);
          expect(tester.getTopLeft(range).dy,
              lessThan(tester.getTopLeft(emptyText).dy));
          expect(find.byIcon(Icons.celebration_outlined), findsNothing);
        } else {
          final count = find.text(l10n.planningRepetitionCount(2));
          await tester.scrollUntilVisible(count, 150);
          await tester.pumpAndSettle();
          expect(count, findsOneWidget);
          await tester.tap(count);
          await tester.pumpAndSettle();
          expect(find.textContaining('Trưa'), findsOneWidget);
          expect(find.textContaining('Tối'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester
            .tap(find.byKey(const ValueKey<String>('repetition-window-7')));
        await tester.pumpAndSettle();
        expect(requested, [14, 7]);
        expect(
            tester.widget<Text>(range).data,
            locale == 'vi'
                ? 'Từ 25 thg 12, 2026 đến 1 thg 1, 2027'
                : 'From Dec 25, 2026 to Jan 1, 2027');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'B08 editor opens the current dish candidate panel through binding',
      (tester) async {
    final plansApi = FakeMealPlanApi()
      ..onGetWeek = (_) async => MealPlanDto(
              id: 'p',
              householdId: 'h',
              weekStart: DateTime(2026, 11, 16),
              status: 'DRAFT',
              slots: [
                MealPlanSlot(
                    id: 's',
                    slotDate: DateTime(2026, 11, 16),
                    mealTime: 'LUNCH',
                    dishes: [
                      const MealPlanDish(
                          id: 'd',
                          slotId: 's',
                          sortOrder: 0,
                          status: DishUiStatus.confirmed,
                          recipe: AssignedRecipeSummary(
                              recipeId: 'r', recipeName: 'Canh', source: 'AI'))
                    ])
              ]);
    final plans =
        MealPlanStore(api: plansApi, suggestionApi: FakeMealSuggestionApi());
    await plans.loadWeekPlan();
    Get.put<MealPlanStore>(plans);
    final attendance = _Attendance();
    when(() => attendance.get('p', 's'))
        .thenAnswer((_) async => throw NetworkException());
    Get.put<MealAttendanceApi>(attendance);
    final json = candidateJson('a', recommended: true)..['dishId'] = 'd';
    json['softScoreBreakdown'] = {'repetition_penalty': 1.0};
    final candidates = FakeCandidateApi()
      ..items = [MealPlanCandidate.fromJson(json)];
    Get.put<CandidateApi>(candidates);
    await pumpLocalized(
        tester,
        const MealSlotEditorScene(
            slotId: 's', mealLabel: 'Lunch', dateLabel: '16/11'),
        pages: [
          GetPage(
              name: PlanningRoutes.candidates,
              page: () => const CandidateInsightScene(),
              binding: CandidateInsightBinding())
        ]);
    await tester.pumpAndSettle();
    final insights =
        find.byKey(const ValueKey<String>('dish-candidate-insights'));
    await tester.ensureVisible(insights);
    await tester.pumpAndSettle();
    await tester.tap(insights);
    await tester.pumpAndSettle();
    expect(find.byType(CandidateInsightScene), findsOneWidget);
    expect(Get.parameters['dishId'], 'd');
    expect(Get.parameters['slotId'], 's');
    expect(find.text('Tín hiệu gợi ý'), findsOneWidget);
    expect(find.text('Các thanh thể hiện mức tín hiệu tham khảo.'),
        findsOneWidget);
    expect(candidates.calls, 1);
    expect(tester.takeException(), isNull);
  });

  for (final lateError in [false, true]) {
    testWidgets(
        'B05 late 14 response error=$lateError does not replace 7 range/empty',
        (tester) async {
      final api = _PendingApi();
      Get.put<RepetitionStore>(RepetitionStore(api));
      await pumpLocalized(tester, const RepetitionSummaryScene());
      await tester
          .tap(find.byKey(const ValueKey<String>('repetition-window-7')));
      await tester.pump();
      expect(api.requests.map((r) => r.$1), [14, 7]);
      api.requests[1].$2.complete(
          RepetitionSummary.fromJson(summaryJson(days: 7, empty: true)));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(range).data;
      if (lateError) {
        api.requests[0].$2.completeError(NetworkException());
      } else {
        api.requests[0].$2.complete(RepetitionSummary.fromJson(summaryJson()));
      }
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(range).data, text);
      expect(find.byType(AppErrorView), findsNothing);
      expect(find.byKey(const ValueKey<String>('repetition-empty')),
          findsOneWidget);
    });
  }

  testWidgets('B06 offline then retry has no invented range or empty',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _PendingApi();
    Get.put<RepetitionStore>(RepetitionStore(api));
    await pumpLocalized(tester, const RepetitionSummaryScene(), scale: 2);
    expect(find.byType(AppLoadingView), findsOneWidget);
    expect(range, findsNothing);
    api.requests.first.$2.completeError(NetworkException());
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsOneWidget);
    expect(range, findsNothing);
    expect(
        find.byKey(const ValueKey<String>('repetition-empty')), findsNothing);
    final l10n = AppLocalizations.of(
        tester.element(find.byType(RepetitionSummaryScene)));
    expect(find.text(l10n.planningRepetitionWindowHint), findsOneWidget);
    await tester.ensureVisible(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump();
    expect(range, findsNothing);
    api.requests.last.$2
        .complete(RepetitionSummary.fromJson(summaryJson(empty: true)));
    await tester.pumpAndSettle();
    expect(range, findsOneWidget);
    expect(api.requests.map((r) => r.$1), [14, 14]);
  });

  testWidgets(
      'B08-09 panel keeps raw fallback/zero and hides null/inactive/BLOCKED',
      (tester) async {
    for (final value in [1.0, 0.0]) {
      final json = candidateJson('raw', recommended: true);
      json['softScoreBreakdown'] = {
        'repetition_penalty': value,
        'effort_fit': null,
        'diet_match': 0.9,
        'inactive_features': ['diet_match'],
        'profile_version': 'v2'
      };
      final c = MealPlanCandidate.fromJson(json);
      await pumpLocalized(
          tester,
          Scaffold(
              body: SingleChildScrollView(child: CandidateCard(candidate: c))));
      await tester.pumpAndSettle();
      final l10n =
          AppLocalizations.of(tester.element(find.byType(CandidateCard)));
      expect(find.text(l10n.planningCandidateBreakdown), findsOneWidget);
      expect(find.text(l10n.planningCandidateSignalsHint), findsOneWidget);
      expect(find.textContaining('trọng số'), findsNothing);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, value);
      expect(bar.color, AppColors.warning);
      expect(find.text(l10n.planningFeatureDietMatch), findsNothing);
      expect(find.text(l10n.planningFeatureEffortFit), findsNothing);
      expect(c.softScore, 0.5);
      expect(find.byKey(const ValueKey<String>('candidate-badge-final')),
          findsOneWidget);
    }
    final blocked = MealPlanCandidate.fromJson(
        candidateJson('blocked', status: 'BLOCKED', recommended: false));
    await pumpLocalized(
        tester,
        Scaffold(
            body: CandidateCard(
                key: const ValueKey('blocked'), candidate: blocked)));
    await tester.pumpAndSettle();
    expect(find.byType(SoftScoreBreakdownPanel), findsNothing);
    expect(find.byKey(const ValueKey<String>('candidate-badge-blocked')),
        findsOneWidget);
  });

  testWidgets('B11 banner reports signals without promising anti-repetition',
      (tester) async {
    Get.put<CandidateStore>(CandidateStore(
        FakeCandidateApi()
          ..items = [
            MealPlanCandidate.fromJson(candidateJson('a', recommended: true))
          ],
        'p',
        sessionId: 's1'));
    await pumpLocalized(tester, const CandidateInsightScene());
    await tester.pumpAndSettle();
    expect(find.textContaining('tín hiệu lặp món mang tính tham khảo'),
        findsOneWidget);
    expect(find.textContaining('chống lặp món'), findsNothing);
  });

  for (final reason in [
    'Gợi ý dựa trên tổng điểm và các ràng buộc của bữa ăn.',
    'Món vừa nấu gần đây'
  ]) {
    for (final tradeoff in <String?>[
      null,
      'Tận dụng tốt đồ sắp hỏng, nhưng mức đa dạng món theo kế hoạch còn hạn chế.'
    ]) {
      testWidgets('B10/B12 raw reason=$reason tradeoff=$tradeoff stays intact',
          (tester) async {
        final suggestion = MealSuggestion.fromVoteOpen({
          'recipeId': 'r',
          'recipeName': 'Canh',
          'rankReason': reason,
          'tradeoffNote': tradeoff,
          'aiReasoning': 'RAW LLM DO NOT RENDER',
          'generated_answer': 'RAW ANSWER',
          'llm_reason': 'RAW REASON'
        });
        await pumpLocalized(
            tester,
            Scaffold(
                body: SingleChildScrollView(
                    child: SuggestionCard(suggestion: suggestion))));
        await tester.pumpAndSettle();
        final l10n =
            AppLocalizations.of(tester.element(find.byType(SuggestionCard)));
        expect(find.text(reason), findsOneWidget);
        expect(find.text(l10n.planningRepetitionContextHint), findsOneWidget);
        if (tradeoff != null) expect(find.text(tradeoff), findsOneWidget);
        expect(find.textContaining('RAW '), findsNothing);
        expect(suggestion.rankReason, reason);
        expect(suggestion.tradeoffNote, tradeoff);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
