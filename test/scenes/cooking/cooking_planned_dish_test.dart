import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/dish_cooked_dialog.dart';

import 'cooking_session_store_test.dart' show MemoryProgressStore;
import 'fake_cooking_api.dart';

/// R3 mục 10: nấu từ món thực đơn gửi `mealPlanDishId`; 409 món đã nấu.
void main() {
  late FakeCookingApi cookingApi;

  setUp(() => cookingApi = FakeCookingApi());

  CookingSessionStore store({String? dishId}) => CookingSessionStore(
        cookingApi: cookingApi,
        recipeApi: FakeRecipeApi(),
        progressStore: CookingProgressCoordinator(MemoryProgressStore()),
        userId: 'u1',
        entryMode: CookingEntryMode.start,
        recipeId: 'r1',
        mealPlanDishId: dishId,
      );

  test('start gửi kèm mealPlanDishId (null khi nấu ngoài thực đơn)', () async {
    cookingApi.onStartError = NetworkException();
    await store(dishId: 'dish-1').init();
    await store().init();
    expect(cookingApi.startDishIds, <String?>['dish-1', null]);
  });

  test('409 ERR_DISH_ALREADY_COOKED → phase error, không cho thử lại',
      () async {
    cookingApi.onStartError = BusinessException(
        kDishAlreadyCookedCode, 'cooked',
        details: <String, dynamic>{'cookedAt': '2026-11-02T05:00:00Z'});
    final s = store(dishId: 'dish-1');
    await s.init();

    expect(s.phase, CookingScreenPhase.error);
    expect(s.loadError?.code, kDishAlreadyCookedCode);
    expect(s.loadErrorIsRetryable, isFalse);
    expect(cookedAtFromDetails(s.loadError?.details)?.toUtc(),
        DateTime.utc(2026, 11, 2, 5));
  });
}
