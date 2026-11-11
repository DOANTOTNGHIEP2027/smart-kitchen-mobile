import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/candidate_insight_scene.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/candidate_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/candidate_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/meal_plan_candidate.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/shopping_list_sink.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/suggestion_store.dart';
import 'fake_meal_plan_api.dart';

class Sink implements ShoppingListSink {
  @override
  Future<int> addItems(List<IngredientItem> items) async => 0;
}

MealPlanDto snapshot({String status = 'DRAFT', String recipe = 'old'}) =>
    MealPlanDto(
        id: 'p',
        householdId: 'h',
        weekStart: DateTime(2026, 11, 2),
        status: status,
        slots: [
          MealPlanSlot(
              id: 's',
              slotDate: DateTime(2026, 11, 2),
              mealTime: 'LUNCH',
              dishes: [
                MealPlanDish(
                    id: 'd',
                    slotId: 's',
                    sortOrder: 0,
                    status: DishUiStatus.confirmed,
                    recipe: AssignedRecipeSummary(
                        recipeId: recipe, recipeName: recipe, source: 'AI'))
              ])
        ]);
const a = MealSuggestion(id: 'a', recipeId: 'a', mealName: 'A');
const b = MealSuggestion(id: 'b', recipeId: 'b', mealName: 'B');
const c = MealSuggestion(id: 'c', recipeId: 'c', mealName: 'C');

class Candidates implements CandidateApi {
  int reads = 0;
  @override
  Future<List<MealPlanCandidate>> list(String plan) async {
    reads++;
    return [];
  }
}

Future<(MealPlanStore, FakeMealPlanApi, SuggestionStore)>
    unknownSelection() async {
  final plans = FakeMealPlanApi();
  plans.onGetWeek = (_) async => snapshot();
  final api = FakeMealSuggestionApi();
  api.onSelect = (_) async => throw NetworkException();
  final store = MealPlanStore(api: plans, suggestionApi: api);
  await store.loadWeekPlan();
  store.suggestions['d'] = [a];
  final panel = SuggestionStore(
      slotId: 's', dishId: 'd', mealPlanStore: store, shoppingSink: Sink());
  await panel.acceptSuggestion();
  return (store, plans, panel);
}

void main() {
  test('recovery plan read cannot roll back a newer weekly confirmed snapshot',
      () async {
    final plans = FakeMealPlanApi();
    plans.onGetWeek = (_) async => snapshot();
    final api = FakeMealSuggestionApi();
    api.onSelect = (_) async => throw NetworkException();
    final store = MealPlanStore(api: plans, suggestionApi: api);
    await store.loadWeekPlan();
    store.suggestions['d'] = [a];
    final view = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: store, shoppingSink: Sink());
    await view.acceptSuggestion();
    final old = Completer<MealPlanDto>();
    plans.onGetById = (_) => old.future;
    final recovery = view.recheck();
    plans.onGetWeek = (_) async => snapshot(status: 'CONFIRMED', recipe: 'new');
    await store.loadWeekPlan();
    expect(store.isConfirmed, true);
    old.complete(snapshot());
    await recovery;
    expect(store.isConfirmed, true);
    expect(store.slots.values.single.dishes.single.recipe?.recipeId, 'new');
  });
  test('pager can advance after a manual GET shrinks the batch', () async {
    final api = FakeMealSuggestionApi();
    var rows = [a, b, c];
    api.onList = () async => rows;
    final store = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    store.currentPlanIdForTesting = 'p';
    final view = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: store, shoppingSink: Sink());
    await view.load();
    view.viewNext();
    view.viewNext();
    expect(view.index, 2);
    rows = [a, b];
    await view.load();
    expect(view.index, 0);
    expect(view.hasNext, true);
    view.viewNext();
    expect(view.index, 1);
    expect(view.currentSuggestion?.id, 'b');
  });
  test(
      'candidate generation callback must not report success when shared operation was rejected',
      () async {
    final api = FakeMealSuggestionApi();
    api.onGenerate =
        () async => throw ServerException('ERR_AI_TIMEOUT', 'timeout');
    final store = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    store.currentPlanIdForTesting = 'p';
    final candidates = CandidateStore(Candidates(), 'p',
        dishId: 'd',
        generationState: store.suggestionState('d'),
        openSession: () => store.loadSuggestions('s', 'd', regenerate: true));
    final ok = await candidates.generate();
    expect(ok, false);
    expect(candidates.generateError?.code, 'ERR_AI_TIMEOUT');
  });

  test('CFE146-01 recovery cannot replace a newer public refresh', () async {
    final (store, plans, panel) = await unknownSelection();
    final old = Completer<MealPlanDto>();
    var reads = 0;
    plans.onGetById = (_) => reads++ == 0
        ? old.future
        : Future.value(snapshot(status: 'CONFIRMED', recipe: 'new'));
    final recovery = panel.recheck();
    expect(await store.refreshPlan(), true);
    old.complete(snapshot());
    await recovery;
    expect(store.isConfirmed, true);
    expect(store.slots.values.single.dishes.single.recipe?.recipeId, 'new');
  });

  test('CFE146-01 public refresh cannot replace newer recovery data', () async {
    final (store, plans, panel) = await unknownSelection();
    final old = Completer<MealPlanDto>();
    var reads = 0;
    plans.onGetById = (_) => reads++ == 0
        ? old.future
        : Future.value(snapshot(status: 'CONFIRMED', recipe: 'new'));
    final refresh = store.refreshPlan();
    await panel.recheck();
    old.complete(snapshot());
    expect(await refresh, false);
    expect(store.isConfirmed, true);
    expect(store.slots.values.single.dishes.single.recipe?.recipeId, 'new');
  });

  test('CFE146-01 weekly response cannot replace newer recovery data',
      () async {
    final (store, plans, panel) = await unknownSelection();
    final old = Completer<MealPlanDto>();
    plans.onGetWeek = (_) => old.future;
    final week = store.loadWeekPlan();
    plans.onGetById = (_) async => snapshot(status: 'CONFIRMED', recipe: 'new');
    await panel.recheck();
    old.complete(snapshot());
    await week;
    expect(store.isConfirmed, true);
    expect(store.status, MealPlanLoadStatus.ready);
    expect(store.slots.values.single.dishes.single.recipe?.recipeId, 'new');
  });

  test('CFE146-01 stale weekly error does not hide a newer applied snapshot',
      () async {
    final (store, plans, panel) = await unknownSelection();
    final old = Completer<MealPlanDto>();
    plans.onGetWeek = (_) => old.future;
    final week = store.loadWeekPlan();
    plans.onGetById = (_) async => snapshot(recipe: 'new');
    await panel.recheck();
    old.completeError(NetworkException());
    await week;
    expect(store.status, MealPlanLoadStatus.ready);
    expect(store.slots.values.single.dishes.single.recipe?.recipeId, 'new');
  });

  test('CFE146-01 successful confirm invalidates an older recovery read',
      () async {
    final (store, plans, panel) = await unknownSelection();
    final old = Completer<MealPlanDto>();
    plans.onGetById = (_) => old.future;
    final recovery = panel.recheck();
    expect(await store.confirm(), true);
    old.complete(snapshot());
    await recovery;
    expect(store.isConfirmed, true);
  });

  test('CFE146-01 local dish removal invalidates earlier plan snapshots',
      () async {
    final plans = FakeMealPlanApi();
    plans.onGetWeek = (_) async => snapshot();
    plans.onRemoveDish = (_, __, ___) async {};
    final api = FakeMealSuggestionApi();
    api.onSelect = (_) async => snapshot().slots.single.dishes.single;
    final store = MealPlanStore(api: plans, suggestionApi: api);
    await store.loadWeekPlan();
    await store.selectSuggestion('s', 'd', 'a');
    final old = Completer<MealPlanDto>();
    plans.onGetById = (_) => old.future;
    final recovery = store.recheckSuggestion('s', 'd');
    await store.removeDish('s', 'd');
    old.complete(snapshot());
    expect(await recovery, DishRequestResult.ignored);
    expect(store.slots.values.single.dishes, isEmpty);
  });

  test(
      'CFE146-02 only applied generation reloads candidates and reports success',
      () async {
    final api = FakeMealSuggestionApi();
    api.onGenerate = () async => [a];
    final store = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    store.currentPlanIdForTesting = 'p';
    final reads = Candidates();
    final candidates = CandidateStore(reads, 'p',
        dishId: 'd',
        dishHasNoSession: true,
        generationState: store.suggestionState('d'),
        openSession: () => store.loadSuggestions('s', 'd', regenerate: true));
    expect(await candidates.generate(), true);
    expect(candidates.generateStatus, FormStatus.success);
    expect(reads.reads, 1);
  });

  test('CFE146-02 network outcome stays unknown without mutation retry',
      () async {
    final api = FakeMealSuggestionApi();
    var writes = 0;
    api.onGenerate = () async {
      writes++;
      throw NetworkException();
    };
    final store = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    store.currentPlanIdForTesting = 'p';
    final reads = Candidates();
    final candidates = CandidateStore(reads, 'p',
        dishId: 'd',
        dishHasNoSession: true,
        generationState: store.suggestionState('d'),
        openSession: () => store.loadSuggestions('s', 'd', regenerate: true));
    expect(await candidates.generate(), false);
    expect(candidates.generateStatus, FormStatus.failure);
    expect(candidates.generateError, isA<NetworkException>());
    expect(candidates.outcomeUnknown, true);
    expect(candidates.canSubmitGeneration, false);
    expect(await candidates.generate(), false);
    expect(writes, 1);
    expect(reads.reads, 0);
    await store.recheckSuggestion('s', 'd');
    expect(candidates.outcomeUnknown, true);
    expect(store.acknowledgeSuggestion('d'), true);
    expect(candidates.outcomeUnknown, false);
    expect(candidates.canSubmitGeneration, true);
  });

  for (final dispose in [false, true]) {
    test(
        'CFE146-02 ignored generation leaves groups intact after ${dispose ? 'dispose' : 'plan change'}',
        () async {
      final api = FakeMealSuggestionApi();
      final pending = Completer<List<MealSuggestion>>();
      api.onGenerate = () => pending.future;
      final store = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
      store.currentPlanIdForTesting = 'p';
      final reads = Candidates();
      final candidates = CandidateStore(reads, 'p',
          dishId: 'd',
          dishHasNoSession: true,
          generationState: store.suggestionState('d'),
          openSession: () => store.loadSuggestions('s', 'd', regenerate: true));
      await candidates.load();
      final groups = candidates.groupsState;
      final generation = candidates.generate();
      if (dispose) {
        store.dispose();
      } else {
        store.currentPlanIdForTesting = 'q';
      }
      expect(await generation, false);
      expect(candidates.generateStatus, FormStatus.idle);
      expect(identical(candidates.groupsState, groups), true);
      expect(reads.reads, 0);
      pending.complete([a]);
      await Future<void>.delayed(Duration.zero);
    });
  }

  testWidgets(
      'CFE146-02 Candidate shows unknown and delegates to existing recovery panel',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeMealSuggestionApi();
    api.onGenerate = () async => throw NetworkException();
    final store = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    store.currentPlanIdForTesting = 'p';
    final candidates = CandidateStore(Candidates(), 'p',
        slotId: 's',
        dishId: 'd',
        dishHasNoSession: true,
        generationState: store.suggestionState('d'),
        openSession: () => store.loadSuggestions('s', 'd', regenerate: true));
    Get.put<CandidateStore>(candidates);
    addTearDown(Get.reset);
    await tester.pumpWidget(const GetMaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CandidateInsightScene()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('candidate-generate')));
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CandidateInsightScene)));
    expect(find.text(l10n.mealplanOutcomeUnknown), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('candidate-recover-generation')),
        findsOneWidget);
    final button = tester.widget<AppButton>(
        find.byKey(const ValueKey<String>('candidate-generate')));
    expect(button.onPressed, null);
  });

  test('CFE146-03 empty and shorter batches do not trap pager navigation',
      () async {
    final api = FakeMealSuggestionApi();
    var rows = [a, b, c];
    api.onList = () async => rows;
    api.onGenerate = () async => [a, b, c];
    final store = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    store.currentPlanIdForTesting = 'p';
    final view = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: store, shoppingSink: Sink());
    await view.load();
    view.viewNext();
    view.viewNext();
    rows = [];
    await view.load();
    expect(view.currentSuggestion, null);
    rows = [a, b];
    await view.load();
    view.viewNext();
    expect(view.currentSuggestion?.id, 'b');
    view.viewPrevious();
    expect(view.currentSuggestion?.id, 'a');
    view.viewNext();
    await view.refreshSuggestions();
    expect(view.index, 0);
    expect(view.currentSuggestion?.id, 'a');
  });
}
