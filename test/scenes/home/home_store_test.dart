import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/home/domain/upcoming_meal.dart';
import 'package:smart_kitchen_mobile/scenes/home/stores/home_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import 'home_fixtures.dart';

class _MockMealPlanApi extends Mock implements MealPlanApi {}


void main() {
  late _MockMealPlanApi mealPlanApi;
  late HomeStore store;
  final now = DateTime(2026, 11, 28, 10);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    mealPlanApi = _MockMealPlanApi();
    store = HomeStore(
      mealPlanApi: mealPlanApi,
      clock: () => now,
    );
  });

  group('load', () {
    test('có bữa sắp tới trong tuần hiện tại → Success', () async {
      when(() => mealPlanApi.getCurrent()).thenAnswer((_) async => plan([
            slot('lunch', DateTime(2026, 11, 28), 'LUNCH',
                [dish('d1', recipeId: 'r1')]),
          ]));

      await store.load();

      final state = store.upcoming;
      expect(state, isA<SuccessState<UpcomingMeal>>());
      expect((state as SuccessState<UpcomingMeal>).data.slot.id, 'lunch');
      verifyNever(() => mealPlanApi.getWeek(any()));
    });

    test('tuần hiện tại hết bữa → đọc tuần kế tiếp (thứ Hai)', () async {
      when(() => mealPlanApi.getCurrent()).thenAnswer((_) async => plan([]));
      when(() => mealPlanApi.getWeek(any())).thenAnswer((_) async => plan([
            slot('next', DateTime(2026, 11, 30), 'BREAKFAST',
                [dish('d1', recipeId: 'r1')]),
          ], id: 'mp-2'));

      await store.load();

      expect(store.upcoming, isA<SuccessState<UpcomingMeal>>());
      verify(() => mealPlanApi.getWeek(DateTime(2026, 11, 30))).called(1);
    });

    test('không có plan nào → Empty', () async {
      when(() => mealPlanApi.getCurrent())
          .thenThrow(BusinessException('ERR_PLAN_NOT_FOUND', 'x'));
      when(() => mealPlanApi.getWeek(any()))
          .thenThrow(BusinessException('ERR_PLAN_NOT_FOUND', 'x'));

      await store.load();

      expect(store.upcoming, isA<EmptyState<UpcomingMeal>>());
    });

    test('lỗi mạng → Error', () async {
      when(() => mealPlanApi.getCurrent()).thenThrow(NetworkException());

      await store.load();

      expect(store.upcoming, isA<ErrorState<UpcomingMeal>>());
    });
  });

}
