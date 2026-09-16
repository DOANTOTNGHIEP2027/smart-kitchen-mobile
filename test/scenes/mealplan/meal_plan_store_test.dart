import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/realtime/ws_event_envelope.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/vote_session_summary.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/stores/realtime_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import 'fake_meal_plan_api.dart';

/// Test `MealPlanStore.handleVoteEvent` — 4 loại event (session_opened /
/// member_voted / session_closed / winner_selected) + household filter +
/// dishId guard. (FE-7 §7's switch-case).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();

  setUp(storageChannel.install);
  tearDown(storageChannel.uninstall);

  late FakeMealPlanApi mealPlanApi;
  late FakeVoteApi voteApi;
  late RealtimeStore fakeRealtimeStore;
  late SessionStore session;
  late MealPlanStore store;

  setUp(() {
    mealPlanApi = FakeMealPlanApi();
    voteApi = FakeVoteApi();
    final tokenStorage = TokenStorage();
    session = SessionStore(
      tokenStorage,
      AuthRefreshUseCase(
        Dio(BaseOptions(baseUrl: 'https://test.local'))
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          ),
      ),
    );
    session.currentUser =
        const UserSummary(id: 'u-self', fullName: 'Me');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    // RealtimeStore chỉ cần `.events` stream — không cần connect thật.
    fakeRealtimeStore = _NoOpRealtimeStore();
    store = MealPlanStore(
      api: mealPlanApi,
      voteApi: voteApi,
      realtimeStore: fakeRealtimeStore,
      sessionStore: session,
    );
    // Seed slot-nhà-Tối vào store để handleVoteEvent có context.
    store.slots['2026-09-16_DINNER'] = MealPlanSlot(
      id: 'slot-1',
      slotDate: DateTime.parse('2026-09-16T00:00:00Z'),
      mealTime: 'DINNER',
      dishes: <MealPlanDish>[
        MealPlanDish(
          id: 'dish-1',
          slotId: 'slot-1',
          sortOrder: 0,
          status: DishUiStatus.empty,
        ),
      ],
    );
  });

  WsEventEnvelope _event(
    Map<String, dynamic> data, {
    String householdId = 'h1',
  }) =>
      WsEventEnvelope(
        eventId: 'e-${DateTime.now().microsecondsSinceEpoch}',
        eventType: 'vote',
        householdId: householdId,
        occurredAt: DateTime.parse('2026-09-16T10:00:00Z'),
        actorId: 'u-other',
        data: data,
      );

  group('handleVoteEvent — 4 loại event', () {
    test('session_opened → thêm session vào activeSessions + set dish VOTING',
        () {
      store.handleVoteEvent(_event(<String, dynamic>{
        'type': 'session_opened',
        'slotId': 'slot-1',
        'dishId': 'dish-1',
        'sessionId': 's-real',
        'deadlineAt': '2026-09-17T10:00:00Z',
        'suggestions': <Map<String, dynamic>>[
          <String, dynamic>{
            'recipeId': 'r1',
            'recipeName': 'M',
            'confidence': 0.5,
            'source': 'KB',
            'rankReason': 'x',
            'missingIngredients': <dynamic>[],
            'allergenTags': <String>[],
            'allergenDerivation': 'INGREDIENT_RULE',
          },
        ],
      }));

      final session = store.activeSessions['dish-1'];
      expect(session, isNotNull);
      expect(session!.dishId, 'dish-1');
      expect(session.status, VoteSessionUiStatus.open);
      expect(session.suggestions.length, 1);

      // Dish status cục bộ phải chuyển VOTING
      final dish = store.slots['2026-09-16_DINNER']!.dishes.first;
      expect(dish.status, DishUiStatus.voting);
    });

    test('member_voted → tally update cho đúng dishId', () {
      // Seed session trước
      store.activeSessions['dish-1'] = VoteSessionSummary(
        sessionId: 's-real',
        slotId: 'slot-1',
        dishId: 'dish-1',
        status: VoteSessionUiStatus.open,
        suggestions: const <MealSuggestion>[
          MealSuggestion(recipeId: 'r1', mealName: 'M'),
        ],
        tally: const <VoteTallyItem>[],
      );

      store.handleVoteEvent(_event(<String, dynamic>{
        'type': 'member_voted',
        'dishId': 'dish-1',
        'tally': <Map<String, dynamic>>[
          <String, dynamic>{
            'recipeId': 'r1',
            'recipeName': 'M',
            'count': 3,
          },
        ],
        'totalMembers': 4,
      }));

      expect(store.activeSessions['dish-1']!.tally.first.count, 3);
      expect(store.activeSessions['dish-1']!.totalMembers, 4);
    });

    test('session_closed → xoá session + set dish về SUGGESTED', () {
      store.activeSessions['dish-1'] = const VoteSessionSummary(
        sessionId: 's',
        slotId: 'slot-1',
        dishId: 'dish-1',
        status: VoteSessionUiStatus.open,
        suggestions: <MealSuggestion>[],
        tally: <VoteTallyItem>[],
      );

      store.handleVoteEvent(_event(<String, dynamic>{
        'type': 'session_closed',
        'slotId': 'slot-1',
        'dishId': 'dish-1',
      }));

      expect(store.activeSessions['dish-1'], isNull);
      expect(
        store.slots['2026-09-16_DINNER']!.dishes.first.status,
        DishUiStatus.suggested,
      );
    });

    test('winner_selected → xoá session + set dish CONFIRMED + gán recipe', () {
      store.activeSessions['dish-1'] = const VoteSessionSummary(
        sessionId: 's',
        slotId: 'slot-1',
        dishId: 'dish-1',
        status: VoteSessionUiStatus.open,
        suggestions: <MealSuggestion>[],
        tally: <VoteTallyItem>[],
      );

      store.handleVoteEvent(_event(<String, dynamic>{
        'type': 'winner_selected',
        'slotId': 'slot-1',
        'dishId': 'dish-1',
        'winnerRecipeId': 'r-winner',
        'winnerRecipeName': 'Canh chua cá lóc',
      }));

      expect(store.activeSessions['dish-1'], isNull);
      final dish = store.slots['2026-09-16_DINNER']!.dishes.first;
      expect(dish.status, DishUiStatus.confirmed);
      expect(dish.recipe!.recipeId, 'r-winner');
      expect(dish.recipe!.source, 'AI');
    });

    test('household khác → bỏ qua toàn bộ event', () {
      store.handleVoteEvent(_event(
        <String, dynamic>{
          'type': 'session_opened',
          'slotId': 'slot-1',
          'dishId': 'dish-1',
          'sessionId': 's-other',
          'deadlineAt': '2026-09-17T10:00:00Z',
          'suggestions': <Map<String, dynamic>>[],
        },
        householdId: 'h2', // khác household
      ));

      expect(store.activeSessions['dish-1'], isNull,
          reason: 'event household khác phải bị bỏ qua');
    });

    test('type lạ → log warning, không crash', () {
      store.handleVoteEvent(_event(<String, dynamic>{
        'type': 'unknown_event',
        'dishId': 'dish-1',
      }));
      // không throw = pass
      expect(store.activeSessions['dish-1'], isNull);
    });

    test(
        '2 dish cùng slot nhận session_opened gần như đồng thời — không ghi đè',
        () {
      // Seed slot với 2 dish
      store.slots['2026-09-16_DINNER'] = MealPlanSlot(
        id: 'slot-1',
        slotDate: DateTime.parse('2026-09-16T00:00:00Z'),
        mealTime: 'DINNER',
        dishes: <MealPlanDish>[
          MealPlanDish(
              id: 'dish-a',
              slotId: 'slot-1',
              sortOrder: 0,
              status: DishUiStatus.empty),
          MealPlanDish(
              id: 'dish-b',
              slotId: 'slot-1',
              sortOrder: 1,
              status: DishUiStatus.empty),
        ],
      );

      // event cho dish-a
      store.handleVoteEvent(_event(<String, dynamic>{
        'type': 'session_opened',
        'slotId': 'slot-1',
        'dishId': 'dish-a',
        'sessionId': 's-a',
        'deadlineAt': '2026-09-17T10:00:00Z',
        'suggestions': <Map<String, dynamic>>[
          <String, dynamic>{
            'recipeId': 'r-a',
            'recipeName': 'A',
            'confidence': 0.5,
            'source': 'KB',
            'rankReason': 'x',
            'missingIngredients': <dynamic>[],
            'allergenTags': <String>[],
            'allergenDerivation': 'INGREDIENT_RULE',
          },
        ],
      }));
      // event cho dish-b
      store.handleVoteEvent(_event(<String, dynamic>{
        'type': 'session_opened',
        'slotId': 'slot-1',
        'dishId': 'dish-b',
        'sessionId': 's-b',
        'deadlineAt': '2026-09-17T10:00:00Z',
        'suggestions': <Map<String, dynamic>>[
          <String, dynamic>{
            'recipeId': 'r-b',
            'recipeName': 'B',
            'confidence': 0.4,
            'source': 'KB',
            'rankReason': 'y',
            'missingIngredients': <dynamic>[],
            'allergenTags': <String>[],
            'allergenDerivation': 'INGREDIENT_RULE',
          },
        ],
      }));

      // Guard §15.11 (sau amendment): 2 session độc lập, không ghi đè
      expect(store.activeSessions['dish-a'], isNotNull);
      expect(store.activeSessions['dish-b'], isNotNull);
      expect(store.activeSessions['dish-a']!.sessionId, 's-a');
      expect(store.activeSessions['dish-b']!.sessionId, 's-b');
      expect(
        store.activeSessions['dish-a']!.suggestions.first.recipeId,
        'r-a',
      );
      expect(
        store.activeSessions['dish-b']!.suggestions.first.recipeId,
        'r-b',
      );
    });
  });

  group('uiStatusOf — 4 trạng thái slot aggregate', () {
    test('rỗng → empty', () {
      store.slots['k'] = MealPlanSlot(
        id: 's',
        slotDate: DateTime.parse('2026-09-16T00:00:00Z'),
        mealTime: 'LUNCH',
        dishes: <MealPlanDish>[],
      );
      expect(store.uiStatusOf('k'), SlotUiStatus.empty);
    });

    test('có dish VOTING → voting', () {
      store.slots['k'] = MealPlanSlot(
        id: 's',
        slotDate: DateTime.parse('2026-09-16T00:00:00Z'),
        mealTime: 'LUNCH',
        dishes: <MealPlanDish>[
          MealPlanDish(
              id: 'd1',
              slotId: 's',
              sortOrder: 0,
              status: DishUiStatus.confirmed),
          MealPlanDish(
              id: 'd2',
              slotId: 's',
              sortOrder: 1,
              status: DishUiStatus.voting),
        ],
      );
      expect(store.uiStatusOf('k'), SlotUiStatus.voting);
    });

    test('mọi dish CONFIRMED → confirmed', () {
      store.slots['k'] = MealPlanSlot(
        id: 's',
        slotDate: DateTime.parse('2026-09-16T00:00:00Z'),
        mealTime: 'LUNCH',
        dishes: <MealPlanDish>[
          MealPlanDish(
              id: 'd1',
              slotId: 's',
              sortOrder: 0,
              status: DishUiStatus.confirmed),
          MealPlanDish(
              id: 'd2',
              slotId: 's',
              sortOrder: 1,
              status: DishUiStatus.confirmed),
        ],
      );
      expect(store.uiStatusOf('k'), SlotUiStatus.confirmed);
    });

    test('mix EMPTY/SUGGESTED/CONFIRMED → inProgress', () {
      store.slots['k'] = MealPlanSlot(
        id: 's',
        slotDate: DateTime.parse('2026-09-16T00:00:00Z'),
        mealTime: 'LUNCH',
        dishes: <MealPlanDish>[
          MealPlanDish(
              id: 'd1',
              slotId: 's',
              sortOrder: 0,
              status: DishUiStatus.confirmed),
          MealPlanDish(
              id: 'd2',
              slotId: 's',
              sortOrder: 1,
              status: DishUiStatus.empty),
        ],
      );
      expect(store.uiStatusOf('k'), SlotUiStatus.inProgress);
    });
  });
}

/// RealtimeStore stub — chỉ cần `.events` stream. KHÔNG connect thật.
class _NoOpRealtimeStore implements RealtimeStore {
  @override
  Stream<WsEventEnvelope> get events => const Stream<WsEventEnvelope>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
