import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/allergen_derivation.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/shopping_list_sink.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/vote_session_summary.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/suggestion_store.dart';
import 'package:smart_kitchen_mobile/stores/realtime_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import 'fake_meal_plan_api.dart';

/// Regression test cho Finding #1 HIGH (review pass 1): rollback
/// `acceptSuggestion` phải khôi phục ĐÚNG `activeSessions[dishId]`, không chỉ
/// `_slots[key]` — trước fix, sau 1 PUT lỗi user mất vote session và phải
/// fallback degraded (mất suggestions giàu field) chỉ vì 1 lỗi tạm thời.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  setUp(storageChannel.install);
  tearDown(storageChannel.uninstall);

  late FakeMealPlanApi mealPlanApi;
  late FakeVoteApi voteApi;
  late MealPlanStore mealPlanStore;
  late SuggestionStore suggestionStore;

  setUp(() {
    mealPlanApi = FakeMealPlanApi();
    voteApi = FakeVoteApi();
    final tokenStorage = TokenStorage();
    final session = SessionStore(
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
    mealPlanStore = MealPlanStore(
      api: mealPlanApi,
      voteApi: voteApi,
      realtimeStore: _NoOpRealtimeStore(),
      sessionStore: session,
    );
    // Seed slot-dish-session state:
    mealPlanStore.slots['2026-09-16_DINNER'] = MealPlanSlot(
      id: 'slot-1',
      slotDate: DateTime.parse('2026-09-16T00:00:00Z'),
      mealTime: 'DINNER',
      dishes: <MealPlanDish>[
        const MealPlanDish(
          id: 'dish-1',
          slotId: 'slot-1',
          sortOrder: 0,
          status: DishUiStatus.voting,
        ),
      ],
    );
    mealPlanStore.activeSessions['dish-1'] = const VoteSessionSummary(
      sessionId: 's-rich',
      slotId: 'slot-1',
      dishId: 'dish-1',
      status: VoteSessionUiStatus.open,
      suggestions: <MealSuggestion>[
        MealSuggestion(
          recipeId: 'r-1',
          mealName: 'Canh chua cá lóc',
          rankReason: 'cá lóc còn 1 ngày hết hạn',
          source: 'KB',
          allergenDerivation: AllergenDerivation.ingredientRule,
        ),
      ],
      tally: <VoteTallyItem>[],
      suggestionsSourceDegraded: false,
    );
    mealPlanStore.currentPlanIdForTesting = 'plan-1';

    suggestionStore = SuggestionStore(
      slotId: 'slot-1',
      dishId: 'dish-1',
      mealPlanStore: mealPlanStore,
      api: mealPlanApi,
      shoppingSink: const NoOpShoppingListSink(),
    );
  });

  test(
      '⭐ HIGH #1 regression: accept fail → activeSessions[dishId] phải được '
      'khôi phục đúng snapshot gốc, không phải degraded',
      () async {
    expect(mealPlanStore.activeSessions['dish-1'], isNotNull);
    expect(
      mealPlanStore.activeSessions['dish-1']!.suggestions.first.rankReason,
      'cá lóc còn 1 ngày hết hạn',
    );
    expect(
      mealPlanStore.activeSessions['dish-1']!.suggestionsSourceDegraded,
      isFalse,
    );

    // assignDishRecipe lỗi → rollback
    mealPlanApi.onAssignDishRecipe =
        (_, __, ___, {required recipeId, required recipeName}) async {
      throw BusinessException(
          'ERR_VALIDATION_FAILED', 'recipe_id không hợp lệ');
    };

    final ok = await suggestionStore.acceptSuggestion();

    expect(ok, isFalse);
    expect(suggestionStore.actionError!.code, 'ERR_VALIDATION_FAILED');

    // ⭐ HIGH #1: session phải còn, VẪN giàu field
    final restored = mealPlanStore.activeSessions['dish-1'];
    expect(restored, isNotNull,
        reason: 'trước fix: session biến mất → user rơi nhánh degraded');
    expect(restored!.sessionId, 's-rich',
        reason: 'khôi phục ĐÚNG sessionId thật, không sentinel');
    expect(restored.suggestionsSourceDegraded, isFalse);
    expect(restored.suggestions.first.rankReason,
        'cá lóc còn 1 ngày hết hạn');

    // Dish rollback về status==voting, không phải empty
    final dish = mealPlanStore.slots['2026-09-16_DINNER']!.dishes.first;
    expect(dish.status, DishUiStatus.voting);
    expect(dish.recipe, isNull);
  });

  test('accept success → activeSessions bị XÓA (CONFIRMED không cần session)',
      () async {
    mealPlanApi.onAssignDishRecipe =
        (_, __, ___, {required recipeId, required recipeName}) async {
      return const MealPlanDish(
        id: 'dish-1',
        slotId: 'slot-1',
        sortOrder: 0,
        status: DishUiStatus.confirmed,
        recipe: AssignedRecipeSummary(
            recipeId: 'r-1', recipeName: 'Canh chua', source: 'MANUAL'),
      );
    };

    final ok = await suggestionStore.acceptSuggestion();

    expect(ok, isTrue);
    expect(mealPlanStore.activeSessions['dish-1'], isNull);
    expect(
      mealPlanStore.slots['2026-09-16_DINNER']!.dishes.first.status,
      DishUiStatus.confirmed,
    );
  });

  test('missing ingredients → chuyển nguyên danh sách sang ShoppingListSink',
      () async {
    final sink = _RecordingShoppingSink();
    mealPlanStore.activeSessions['dish-1'] = const VoteSessionSummary(
      sessionId: 's-rich',
      slotId: 'slot-1',
      dishId: 'dish-1',
      status: VoteSessionUiStatus.open,
      suggestions: <MealSuggestion>[
        MealSuggestion(
          recipeId: 'r-1',
          mealName: 'Canh chua',
          missingIngredients: <IngredientItem>[
            IngredientItem(name: 'Cà chua', quantity: 200, unit: 'g'),
            IngredientItem(name: 'Cá lóc', quantity: 500, unit: 'g'),
          ],
        ),
      ],
      tally: <VoteTallyItem>[],
    );
    final store = SuggestionStore(
      slotId: 'slot-1',
      dishId: 'dish-1',
      mealPlanStore: mealPlanStore,
      api: mealPlanApi,
      shoppingSink: sink,
    );

    final count = await store.addMissingToShoppingList();

    expect(count, 2);
    expect(sink.received.map((item) => item.name),
        <String>['Cà chua', 'Cá lóc']);
  });
}

class _RecordingShoppingSink implements ShoppingListSink {
  final List<IngredientItem> received = <IngredientItem>[];

  @override
  Future<int> addItems(List<IngredientItem> items) async {
    received.addAll(items);
    return items.length;
  }
}

class _NoOpRealtimeStore implements RealtimeStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
