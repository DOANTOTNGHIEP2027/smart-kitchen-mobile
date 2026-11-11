import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mobx/mobx.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/shopping_list_sink.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/suggestion_store.dart';

import 'fake_meal_plan_api.dart';

class _Sink implements ShoppingListSink {
  @override
  Future<int> addItems(List<IngredientItem> items) async => items.length;
}

const _a = MealSuggestion(id: 'a', recipeId: 'raw-a', mealName: 'A');
const _b = MealSuggestion(id: 'b', recipeId: 'raw-b', mealName: 'B');

MealPlanDto _snapshot({String recipe = 'old', String status = 'DRAFT'}) =>
    MealPlanDto(
      id: 'p',
      householdId: 'h',
      status: status,
      weekStart: DateTime(2026, 11, 2),
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
      ],
    );

class _Harness {
  _Harness() {
    plans.onGetWeek = (_) async => _snapshot();
    plans.onGetById = (_) async => _snapshot();
    api.onList = () async => [_a];
    store = MealPlanStore(api: plans, suggestionApi: api);
    store.currentPlanIdForTesting = 'p';
    store.suggestions['d'] = [_a];
  }
  final plans = FakeMealPlanApi();
  final api = FakeMealSuggestionApi();
  late final MealPlanStore store;
  SuggestionStore panel({String did = 'd'}) => SuggestionStore(
      slotId: 's', dishId: did, mealPlanStore: store, shoppingSink: _Sink());
}

void main() {
  test('V8b reads requested during generate wait and coalesce after success',
      () async {
    final response = Completer<List<MealSuggestion>>();
    var reads = 0;
    final api = FakeMealSuggestionApi()
      ..onGenerate = (() => response.future)
      ..onList = () async {
        reads++;
        return [const MealSuggestion(id: 'b', recipeId: 'b', mealName: 'B')];
      };
    final plan = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    plan.currentPlanIdForTesting = 'p';
    final write = plan.loadSuggestions('s', 'd', regenerate: true);
    final read1 = plan.loadSuggestions('s', 'd');
    final read2 = plan.loadSuggestions('s', 'd');
    await Future<void>.delayed(Duration.zero);
    final readsWhilePending = reads;
    response.complete(
        [const MealSuggestion(id: 'b', recipeId: 'b', mealName: 'B')]);
    await Future.wait([write, read1, read2]);
    expect(readsWhilePending, 0);
    expect(reads, 1);
    expect(plan.suggestions['d']?.single.id, 'b');
  });

  test('V8f two scene stores share one pending mutation per dish', () async {
    final response = Completer<List<MealSuggestion>>();
    var writes = 0;
    final api = FakeMealSuggestionApi()
      ..onGenerate = () {
        writes++;
        return response.future;
      };
    final plan = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    plan.currentPlanIdForTesting = 'p';
    final first = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: plan, shoppingSink: _Sink());
    final second = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: plan, shoppingSink: _Sink());
    final a = first.refreshSuggestions();
    final b = second.refreshSuggestions();
    response.complete([]);
    await Future.wait([a, b]);
    expect(writes, 1);
  });

  test('V7a network outcome survives reopening the suggestion panel', () async {
    final api = FakeMealSuggestionApi()
      ..onGenerate = () async => throw NetworkException();
    final plan = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
    plan.currentPlanIdForTesting = 'p';
    final first = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: plan, shoppingSink: _Sink());
    await first.refreshSuggestions();
    final reopened = SuggestionStore(
        slotId: 's', dishId: 'd', mealPlanStore: plan, shoppingSink: _Sink());
    expect(reopened.actionError, isA<NetworkException>());
  });

  test('V7a,b rechecks before and after commit are snapshots, not completion',
      () async {
    final h = _Harness();
    var writes = 0;
    var serverRows = [_a];
    h.api.onGenerate = () async {
      writes++;
      throw NetworkException();
    };
    h.api.onList = () async => serverRows;
    final view = h.panel();
    await view.refreshSuggestions();
    expect(view.outcomeUnknown, true);
    expect(view.canContinue, false);
    await view.recheck(); // GET before server commit.
    expect(view.currentSuggestion?.id, 'a');
    expect(view.outcomeUnknown, true);
    expect(view.canContinue, true);
    serverRows = [_b]; // Simulate the earlier request committing later.
    await view.recheck();
    expect(view.currentSuggestion?.id, 'b');
    expect(view.outcomeUnknown, true);
    expect(view.canWrite, false);
    expect(writes, 1);
    view.continueFromSnapshot();
    expect(view.outcomeUnknown, false);
    expect(view.canWrite, true);
    expect(writes, 1); // Acknowledgment sends no mutation.
  });

  test('V7c unknown selection rechecks the plan before and after late commit',
      () async {
    final h = _Harness();
    await h.store.loadWeekPlan();
    h.store.suggestions['d'] = [_a];
    var selected = 'old';
    var reads = 0;
    var writes = 0;
    h.plans.onGetById = (_) async {
      reads++;
      return _snapshot(recipe: selected);
    };
    h.api.onSelect = (_) async {
      writes++;
      throw NetworkException();
    };
    final view = h.panel();
    expect(await view.acceptSuggestion(), false);
    expect(view.outcomeUnknown, true);
    await view.recheck();
    expect(h.store.slots.values.single.dishes.single.recipe?.recipeId, 'old');
    selected = 'chosen';
    await view.recheck();
    expect(
        h.store.slots.values.single.dishes.single.recipe?.recipeId, 'chosen');
    expect(view.outcomeUnknown, true);
    expect(view.canContinue, true);
    expect(reads, 2);
    expect(writes, 1);
  });

  test('V7d failed or denied recheck cannot acknowledge unknown outcome',
      () async {
    final h = _Harness();
    h.api.onGenerate = () async => throw NetworkException();
    final view = h.panel();
    await view.refreshSuggestions();
    h.api.onList = () async => throw NetworkException();
    await view.recheck();
    expect(view.canContinue, false);
    expect(view.currentSuggestion?.id, 'a');
    h.api.onList =
        () async => throw BusinessException('ERR_PLAN_NO_HOUSEHOLD', 'denied');
    await view.recheck();
    view.continueFromSnapshot();
    expect(view.outcomeUnknown, true);
    expect(view.canWrite, false);
  });

  test('V7d stale selection refetches only and preserves rejection', () async {
    final h = _Harness();
    var selects = 0;
    var reads = 0;
    h.api.onSelect = (_) async {
      selects++;
      throw BusinessException('ERR_PLAN_SUGGESTION_NOT_FOUND', 'changed');
    };
    h.api.onList = () async {
      reads++;
      return [_b];
    };
    final view = h.panel();
    expect(await view.acceptSuggestion(), false);
    await Future<void>.delayed(Duration.zero);
    expect(view.currentSuggestion?.id, 'b');
    expect(view.actionError?.code, 'ERR_PLAN_SUGGESTION_NOT_FOUND');
    expect(view.outcomeUnknown, false);
    expect(selects, 1);
    expect(reads, 1);
  });

  test('V7d confirmed rejection refetches plan and freezes menu', () async {
    final h = _Harness();
    h.api.onSelect =
        (_) async => throw BusinessException('ERR_PLAN_003', 'confirmed');
    h.plans.onGetById = (_) async => _snapshot(status: 'CONFIRMED');
    final view = h.panel();
    expect(await view.acceptSuggestion(), false);
    await Future<void>.delayed(Duration.zero);
    expect(h.store.isConfirmed, true);
    expect(view.canWrite, false);
    expect(view.canContinue, false);
    expect(view.outcomeUnknown, false);
  });

  test('V7e definitive AI timeout differs from raw proxy and selection errors',
      () async {
    for (final error in [
      ServerException('ERR_AI_TIMEOUT', 'timeout'),
      ServerException('ERR_AI_SERVICE_DOWN', 'down'),
      ServerException('ERR_AI_INVALID_OUTPUT', 'invalid')
    ]) {
      final h = _Harness();
      h.api.onGenerate = () async => throw error;
      final view = h.panel();
      await view.refreshSuggestions();
      expect(view.outcomeUnknown, false);
      expect(view.canWrite, true);
      expect(view.currentSuggestion?.id, 'a');
    }
    final h = _Harness();
    h.api.onGenerate =
        () async => throw ServerException('ERR_INTERNAL', 'proxy');
    final view = h.panel();
    await view.refreshSuggestions();
    expect(view.outcomeUnknown, true);
    final other = _Harness();
    other.api.onSelect =
        (_) async => throw ServerException('ERR_INTERNAL', 'error');
    await other.panel().acceptSuggestion();
    expect(other.panel().outcomeUnknown, true);
  });

  test('V8c deferred GET failure retains successful mutation data and outcome',
      () async {
    final h = _Harness();
    final response = Completer<List<MealSuggestion>>();
    h.api.onGenerate = () => response.future;
    h.api.onList = () async => throw NetworkException();
    final write = h.store.loadSuggestions('s', 'd', regenerate: true);
    final read = h.store.loadSuggestions('s', 'd');
    response.complete([_b]);
    expect(await write, DishRequestResult.applied);
    expect(await read, DishRequestResult.rejected);
    expect(h.panel().currentSuggestion?.id, 'b');
    expect(h.store.suggestionState('d').mutationError, null);
    expect(h.store.suggestionState('d').readError, isA<NetworkException>());
    expect(h.panel().outcomeUnknown, false);
  });

  test('V8d deferred read drains after timeout without clearing uncertainty',
      () async {
    final h = _Harness();
    final response = Completer<List<MealSuggestion>>();
    h.api.onGenerate = () => response.future;
    final write = h.store.loadSuggestions('s', 'd', regenerate: true);
    final read = h.store.loadSuggestions('s', 'd');
    response.completeError(NetworkException());
    expect(await write, DishRequestResult.rejected);
    expect(await read, DishRequestResult.applied);
    expect(h.panel().outcomeUnknown, true);
    expect(h.panel().currentSuggestion?.id, 'a');
    expect(h.panel().canContinue, true);
  });

  test(
      'V8e disposal settles mutation and queued reads before network completes',
      () async {
    final h = _Harness();
    final response = Completer<List<MealSuggestion>>();
    h.api.onGenerate = () => response.future;
    final view = h.panel();
    final write = h.store.loadSuggestions('s', 'd', regenerate: true);
    final read = h.store.loadSuggestions('s', 'd');
    h.store.dispose();
    expect(await write, DishRequestResult.ignored);
    expect(await read, DishRequestResult.ignored);
    expect(view.canWrite, false);
    response.complete([_b]);
    await Future<void>.delayed(Duration.zero);
    expect(h.store.suggestions['d']?.single.id, 'a');
  });

  test('V8e old request cannot clear a new owner after plan round trip',
      () async {
    final h = _Harness();
    final old = Completer<List<MealSuggestion>>();
    final fresh = Completer<List<MealSuggestion>>();
    h.api.onGenerate = () => old.future;
    final oldWrite = h.store.loadSuggestions('s', 'd', regenerate: true);
    h.store.currentPlanIdForTesting = 'q';
    h.store.currentPlanIdForTesting = 'p';
    h.api.onGenerate = () => fresh.future;
    final newWrite = h.store.loadSuggestions('s', 'd', regenerate: true);
    expect(await oldWrite, DishRequestResult.ignored);
    old.complete([_a]);
    await Future<void>.delayed(Duration.zero);
    expect(h.store.suggestionState('d').pending, DishMutation.generate);
    fresh.complete([_b]);
    expect(await newWrite, DishRequestResult.applied);
    expect(h.store.suggestions['d']?.single.id, 'b');
  });

  test(
      'V8e reopening joins pending reads while a different dish remains usable',
      () async {
    final h = _Harness();
    final response = Completer<List<MealSuggestion>>();
    var reads = 0;
    h.api.onGenerate = () => response.future;
    h.api.onList = () async {
      reads++;
      return [_b];
    };
    final write = h.panel().refreshSuggestions();
    final reopened = h.panel();
    expect(reopened.actionStatus, SuggestionActionStatus.rerolling);
    final read = reopened.load();
    await h.store.loadSuggestions('s', 'other');
    expect(reads, 1);
    response.complete([_b]);
    await Future.wait([write, read]);
    expect(reads, 2);
    expect(reopened.currentSuggestion?.id, 'b');
  });

  test('V8e same-week reload preserves outcome observation', () async {
    final h = _Harness();
    await h.store.loadWeekPlan();
    h.store.suggestions['d'] = [_a];
    h.api.onGenerate = () async => throw NetworkException();
    final view = h.panel();
    await view.refreshSuggestions();
    await h.store.loadWeekPlan();
    expect(view.outcomeUnknown, true);
    expect(view.currentSuggestion?.id, 'a');
    expect(h.panel().outcomeUnknown, true);
  });

  test('V8a selection invalidates a suggestion read begun before mutation',
      () async {
    final h = _Harness();
    final oldRead = Completer<List<MealSuggestion>>();
    h.api.onList = () => oldRead.future;
    final read = h.store.loadSuggestions('s', 'd');
    h.api.onSelect =
        (_) async => _snapshot(recipe: 'selected').slots.single.dishes.single;
    expect(await h.store.selectSuggestion('s', 'd', 'a'),
        DishRequestResult.applied);
    expect(await read, DishRequestResult.ignored);
    oldRead.complete([_b]);
    await Future<void>.delayed(Duration.zero);
    expect(h.store.suggestions['d']?.single.id, 'a');
  });

  test(
      'V8e session identity loss retires queued operations without waiting for HTTP',
      () async {
    final session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()));
    runInAction(() => session.currentUser = const UserSummary(id: 'user'));
    final response = Completer<List<MealSuggestion>>();
    final api = FakeMealSuggestionApi()..onGenerate = () => response.future;
    final store = MealPlanStore(
        api: FakeMealPlanApi(), suggestionApi: api, session: session);
    store.currentPlanIdForTesting = 'p';
    final write = store.loadSuggestions('s', 'd', regenerate: true);
    final read = store.loadSuggestions('s', 'd');
    runInAction(() => session.currentUser = null);
    expect(await write, DishRequestResult.ignored);
    expect(await read, DishRequestResult.ignored);
    expect(store.currentPlanId, null);
    response.complete([_b]);
    await Future<void>.delayed(Duration.zero);
    expect(store.suggestions, isEmpty);
    store.dispose();
  });

  test('V8e Get DI disposal invokes store cleanup', () async {
    final h = _Harness();
    Get.put<MealPlanStore>(h.store);
    final response = Completer<List<MealSuggestion>>();
    h.api.onGenerate = () => response.future;
    final write = h.store.loadSuggestions('s', 'd', regenerate: true);
    await Get.delete<MealPlanStore>();
    expect(await write, DishRequestResult.ignored);
    response.complete([_b]);
    await Future<void>.delayed(Duration.zero);
    expect(h.store.suggestions['d']?.single.id, 'a');
    Get.reset();
  });

  test('V8a selection reconciliation cannot reuse a pre-mutation plan GET',
      () async {
    final h = _Harness();
    await h.store.loadWeekPlan();
    final oldPlan = Completer<MealPlanDto>();
    final selection = Completer<MealPlanDish>();
    var reads = 0;
    h.plans.onGetById = (_) =>
        reads++ == 0 ? oldPlan.future : Future.value(_snapshot(recipe: 'new'));
    final oldRefresh = h.store.refreshPlan();
    h.api.onSelect = (_) => selection.future;
    final write = h.store.selectSuggestion('s', 'd', 'a');
    final recheck = h.store.recheckSuggestion('s', 'd');
    selection.complete(_snapshot(recipe: 'new').slots.single.dishes.single);
    expect(await write, DishRequestResult.applied);
    oldPlan.complete(_snapshot(recipe: 'old'));
    expect(await oldRefresh, false);
    expect(await recheck, DishRequestResult.applied);
    expect(reads, 2);
    expect(h.store.slots.values.single.dishes.single.recipe?.recipeId, 'new');
  });

  test('V7d known confirmed rejection stays read-only even when plan GET fails',
      () async {
    final h = _Harness();
    h.api.onSelect =
        (_) async => throw BusinessException('ERR_PLAN_003', 'confirmed');
    h.plans.onGetById = (_) async => throw NetworkException();
    expect(await h.panel().acceptSuggestion(), false);
    await Future<void>.delayed(Duration.zero);
    expect(h.store.isConfirmed, true);
    expect(h.panel().canWrite, false);
  });

  test('V8f manual selection shares dish ownership with suggestion actions',
      () async {
    final h = _Harness();
    final response = Completer<MealPlanDish>();
    h.plans.onAssignDishRecipe =
        (p, s, d, {required recipeId, required recipeName}) => response.future;
    var aiCalls = 0;
    h.api.onGenerate = () async {
      aiCalls++;
      return [_b];
    };
    final manual = h.store.assignManual('s', 'd', 'catalog', 'Manual');
    await h.panel().refreshSuggestions();
    expect(h.panel().actionStatus, SuggestionActionStatus.accepting);
    expect(aiCalls, 0);
    response.complete(_snapshot(recipe: 'catalog').slots.single.dishes.single);
    expect(await manual, true);
    expect(h.panel().actionStatus, SuggestionActionStatus.idle);
  });
}
