import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/meal_composition_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_composition_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_composition.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_composition_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'fake_meal_plan_api.dart';

class FakeCompositionApi extends MealCompositionApi {
  FakeCompositionApi() : super(DioClient.build(tokenStorage: TokenStorage()));
  int calls = 0, reads = 0;
  String? lastRequest;
  List<String> chosen = [];
  Future<CompositionReceipt> Function(String)? onGenerate, onRead;
  Future<CompositionContext> Function()? onContext;
  CompositionContext currentContext = const CompositionContext(
      0,
      [
        CompositionDiner('member', 'MEMBER', 'Member'),
        CompositionDiner('dependent', 'DEPENDENT', 'Child'),
        CompositionDiner('guest', 'GUEST', 'Guest')
      ],
      null);
  @override
  Future<CompositionContext> context(String pid, String sid) async =>
      onContext == null ? currentContext : await onContext!();
  @override
  Future<CompositionReceipt> generate(String pid, String sid,
      {required String requestId,
      required int version,
      required bool replaceExisting,
      required List<String> dependents,
      required List<String> guests}) async {
    calls++;
    lastRequest = requestId;
    chosen = [...dependents, ...guests];
    return onGenerate == null
        ? CompositionReceipt(requestId, 'INCOMPLETE', null)
        : await onGenerate!(requestId);
  }

  @override
  Future<CompositionReceipt> read(
      String pid, String sid, String requestId) async {
    reads++;
    return onRead == null
        ? CompositionReceipt(requestId, 'RUNNING', null)
        : await onRead!(requestId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MealPlanStore plans;
  late FakeMealPlanApi planApi;
  late FakeCompositionApi api;
  late MealCompositionStore store;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    planApi = FakeMealPlanApi();
    plans = MealPlanStore(api: planApi, suggestionApi: FakeMealSuggestionApi())
      ..currentPlanIdForTesting = 'plan';
    api = FakeCompositionApi();
    store = MealCompositionStore(api, plans);
  });
  test(
      'defaults include dependents and guests; toggles affect only the next request',
      () async {
    await store.load('slot');
    expect(api.calls, 0);
    store.toggle('slot', 'guest', false);
    await store.generate('slot', replaceExisting: false);
    expect(api.chosen, ['dependent']);
    expect(store.messages['slot'], 'INCOMPLETE');
  });
  test('double tap creates only one request', () async {
    final pending = Completer<CompositionReceipt>();
    api.onGenerate = (id) => pending.future;
    await store.load('slot');
    final first = store.generate('slot', replaceExisting: false);
    await Future<void>.delayed(Duration.zero);
    await store.generate('slot', replaceExisting: false);
    expect(api.calls, 1);
    pending.complete(CompositionReceipt(api.lastRequest!, 'INCOMPLETE', null));
    await first;
    expect(store.busy['slot'], false);
  });
  test('network uncertainty is recovered without posting a second request',
      () async {
    api.onGenerate = (id) async => throw NetworkException();
    await store.load('slot');
    await store.generate('slot', replaceExisting: false);
    await store.generate('slot', replaceExisting: false);
    expect(api.calls, 1);
    expect(api.reads, 2);
    expect(store.messages['slot'], 'RUNNING');
  });
  test('a reopened store recovers the durable request', () async {
    await const FlutterSecureStorage()
        .write(key: 'meal-compose:plan:slot', value: 'old-request');
    await store.load('slot');
    expect(api.reads, 1);
    expect(api.calls, 0);
    expect(store.messages['slot'], 'RUNNING');
  });
  test('applied result refreshes the server plan rather than creating one',
      () async {
    var refreshed = 0;
    planApi.onGetById = (id) async {
      refreshed++;
      return MealPlanDto(
          id: id,
          householdId: 'house',
          weekStart: DateTime(2026, 11, 9),
          slots: const []);
    };
    api.onGenerate = (id) async => CompositionReceipt(id, 'APPLIED', null);
    await store.load('slot');
    await store.generate('slot', replaceExisting: false);
    expect(refreshed, 1);
    expect(
        await const FlutterSecureStorage().read(key: 'meal-compose:plan:slot'),
        null);
  });
  testWidgets(
      'panel shows diner defaults and incomplete outcome without selecting candidates',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: SingleChildScrollView(
                child: MealCompositionPanel(
                    store: store,
                    slotId: 'slot',
                    hasDishes: false,
                    readOnly: false)))));
    await tester.pumpAndSettle();
    expect(find.text('3 diners'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pump();
    expect(find.text('2 diners'), findsOneWidget);
    await tester.tap(find.text('Create meal menu'));
    await tester.pumpAndSettle();
    expect(api.calls, 1);
    expect(
        find.text(
            'No complete suitable menu was found. Your existing menu is preserved.'),
        findsOneWidget);
  });
  test(
      'new diners default to included while explicit exclusions survive refresh',
      () async {
    await store.load('slot');
    store.toggle('slot', 'guest', false);
    api.currentContext = const CompositionContext(
        0,
        [
          CompositionDiner('member', 'MEMBER', 'Member'),
          CompositionDiner('dependent', 'DEPENDENT', 'Child'),
          CompositionDiner('guest', 'GUEST', 'Guest'),
          CompositionDiner('new-guest', 'GUEST', 'New guest'),
          CompositionDiner('new-child', 'DEPENDENT', 'New child')
        ],
        null);
    await store.load('slot');
    expect(store.selected('slot', 'new-guest'), true);
    expect(store.selected('slot', 'new-child'), true);
    expect(store.selected('slot', 'guest'), false);
    await store.generate('slot', replaceExisting: false);
    expect(api.chosen, containsAll(['new-guest', 'new-child']));
    expect(api.chosen, isNot(contains('guest')));
  });
  test('APPLIED stays recoverable until calendar reload succeeds', () async {
    var refreshes = 0;
    planApi.onGetById = (id) async {
      refreshes++;
      throw NetworkException();
    };
    api.onGenerate = (id) async => CompositionReceipt(id, 'APPLIED', null);
    api.onRead = (id) async => CompositionReceipt(id, 'APPLIED', null);
    await store.load('slot');
    await store.generate('slot', replaceExisting: false);
    expect(
        await const FlutterSecureStorage().read(key: 'meal-compose:plan:slot'),
        api.lastRequest);
    expect(store.messages['slot'], 'APPLIED_SYNC_PENDING');
    expect(refreshes, 1);
    planApi.onGetById = (id) async {
      refreshes++;
      return MealPlanDto(
          id: id,
          householdId: 'home',
          weekStart: DateTime(2026, 11, 9),
          slots: const []);
    };
    final reopened = MealCompositionStore(api, plans);
    await reopened.load('slot');
    expect(refreshes, 2);
    expect(api.reads, 1);
    expect(api.calls, 1);
    expect(reopened.messages['slot'], 'APPLIED');
    expect(
        await const FlutterSecureStorage().read(key: 'meal-compose:plan:slot'),
        null);
  });
  test('older concurrent refresh cannot overwrite newer plan snapshot',
      () async {
    final older = Completer<MealPlanDto>();
    final newer = Completer<MealPlanDto>();
    var calls = 0;
    planApi.onGetById = (id) => calls++ == 0 ? older.future : newer.future;
    MealPlanDto snapshot(String dish) => MealPlanDto(
            id: 'plan',
            householdId: 'house',
            weekStart: DateTime(2026, 11, 9),
            slots: [
              MealPlanSlot(
                  id: 'slot',
                  slotDate: DateTime(2026, 11, 9),
                  mealTime: 'LUNCH',
                  dishes: [
                    MealPlanDish(
                        id: dish,
                        slotId: 'slot',
                        sortOrder: 1,
                        status: DishUiStatus.confirmed)
                  ])
            ]);
    final a = plans.refreshPlan();
    final b = plans.refreshPlan();
    newer.complete(snapshot('new'));
    await b;
    older.complete(snapshot('old'));
    await a;
    expect(plans.slots.values.single.dishes.single.id, 'new');
  });
  test(
      'context reload failure preserves the applied request without regenerating',
      () async {
    var failContext = false;
    api.onContext = () async {
      if (failContext) throw NetworkException();
      return api.currentContext;
    };
    planApi.onGetById = (id) async => MealPlanDto(
        id: id,
        householdId: 'home',
        weekStart: DateTime(2026, 11, 9),
        slots: const []);
    api.onGenerate = (id) async {
      failContext = true;
      return CompositionReceipt(id, 'APPLIED', null);
    };
    api.onRead = (id) async => CompositionReceipt(id, 'APPLIED', null);
    await store.load('slot');
    await store.generate('slot', replaceExisting: false);
    expect(store.messages['slot'], 'APPLIED_SYNC_PENDING');
    expect(
        await const FlutterSecureStorage().read(key: 'meal-compose:plan:slot'),
        api.lastRequest);
    failContext = false;
    await store.generate('slot', replaceExisting: false);
    expect(api.calls, 1);
    expect(api.reads, 1);
    expect(store.messages['slot'], 'APPLIED');
    expect(
        await const FlutterSecureStorage().read(key: 'meal-compose:plan:slot'),
        null);
  });

  test('superseded calendar reload keeps the applied journal for recovery',
      () async {
    final older = Completer<MealPlanDto>();
    final newer = Completer<MealPlanDto>();
    var loads = 0;
    planApi.onGetById = (_) => loads++ == 0 ? older.future : newer.future;
    api.onGenerate = (id) async => CompositionReceipt(id, 'APPLIED', null);
    await store.load('slot');
    final generation = store.generate('slot', replaceExisting: false);
    while (loads == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    final refresh = plans.refreshPlan();
    final snapshot = MealPlanDto(
        id: 'plan',
        householdId: 'home',
        weekStart: DateTime(2026, 11, 9),
        slots: const []);
    newer.complete(snapshot);
    expect(await refresh, true);
    older.complete(snapshot);
    await generation;
    expect(store.messages['slot'], 'APPLIED_SYNC_PENDING');
    expect(
        await const FlutterSecureStorage().read(key: 'meal-compose:plan:slot'),
        api.lastRequest);
  });
}
