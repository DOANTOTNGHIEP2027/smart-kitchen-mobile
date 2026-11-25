import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/compliance.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/nutrition_models.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../mealplan/fake_meal_plan_api.dart';
import 'nutrition_fakes.dart';

Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeMealPlanApi planApi;
  late MealPlanStore mealPlan;
  late NutritionRecipeApi recipeApi;
  late NutritionHealthApi healthApi;
  late NutritionStore store;
  late DateTime week;

  Future<void> setUpWith(List<MealPlanSlot> Function(DateTime week) slots,
      {Map<String, dynamic>? nutrition, int? target = 2000}) async {
    planApi = FakeMealPlanApi();
    mealPlan = MealPlanStore(api: planApi, suggestionApi: FakeMealSuggestionApi());
    week = mealPlan.currentWeekStart;
    planApi.onGetWeek = (w) async => planOf(w, slots(w));
    await mealPlan.loadWeekPlan();
    recipeApi = NutritionRecipeApi(<String, dynamic>{...?nutrition}.cast());
    healthApi = NutritionHealthApi(target: target);
    store = NutritionStore(recipeApi: recipeApi, healthApi: healthApi, mealPlanApi: planApi);
  }

  tearDown(() => store.onClose());

  group('attach(MealPlanStore)', () {
    test('tải lần đầu: Loading → Success, đúng tổng và điểm', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[
          plannedSlot(w, 0, 'LUNCH', <String>['a']),
          plannedSlot(w, 1, 'LUNCH', <String>['b']),
        ],
        nutrition: <String, dynamic>{'a': kcal(2000), 'b': kcal(2300)},
      );
      store.attach(mealPlan);
      expect(store.state, isA<LoadingState<NutritionWeekSummary>>());
      await settle();

      final summary = store.summary!;
      expect(summary.totalCalories, 4300);
      expect(store.complianceScore, 90);
      expect(store.complianceLevel, ComplianceLevel.excellent);
      expect(store.avgDailyCalories, 2150);
      expect(recipeApi.getByIdCalls.toSet(), <String>{'a', 'b'});
    });

    test('AC: slots đổi (recipe đã cache) → số đổi NGAY, không qua Loading', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(500), 'b': kcal(700)},
      );
      store.attach(mealPlan);
      await settle();
      // Đưa 'b' vào cache trước.
      runInAction(() => mealPlan.slots['x_DINNER'] = plannedSlot(week, 1, 'DINNER', <String>['b']));
      await settle();
      expect(store.summary!.totalCalories, 1200);

      final seen = <ViewState<NutritionWeekSummary>>[];
      final dispose = reaction((_) => store.state, seen.add);
      runInAction(() => mealPlan.slots['y_LUNCH'] = plannedSlot(week, 2, 'LUNCH', <String>['a']));
      expect(store.summary!.totalCalories, 1700, reason: 'đồng bộ, cùng lượt');
      expect(seen.whereType<LoadingState<NutritionWeekSummary>>(), isEmpty);
      dispose();
    });

    test('recipe mới → fetch đúng recipe đó (cache), rồi cập nhật', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(500), 'c': kcal(800)},
      );
      store.attach(mealPlan);
      await settle();
      runInAction(() => mealPlan.slots['z_DINNER'] = plannedSlot(week, 0, 'DINNER', <String>['c', 'a']));
      expect(store.state, isA<LoadingState<NutritionWeekSummary>>());
      await settle();
      expect(store.summary!.days.first.calories, 1800);
      expect(recipeApi.getByIdCalls.where((id) => id == 'a'), hasLength(1));
      expect(recipeApi.getByIdCalls.where((id) => id == 'c'), hasLength(1));
    });

    test('món SUGGESTED không tính và không fetch', () async {
      await setUpWith((w) => <MealPlanSlot>[
            plannedSlot(w, 0, 'LUNCH', <String>['s'], status: DishUiStatus.suggested),
          ]);
      store.attach(mealPlan);
      await settle();
      expect(store.state, isA<EmptyState<NutritionWeekSummary>>());
      expect(recipeApi.getByIdCalls, isEmpty);
    });

    test('ERR_RECIPE_NOT_FOUND → món thiếu dữ liệu, không lỗi', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['gone', 'a'])],
        nutrition: <String, dynamic>{'a': kcal(600)},
      );
      recipeApi.errors['gone'] = notFound();
      store.attach(mealPlan);
      await settle();
      expect(store.summary!.missingNutritionCount, 1);
      expect(store.summary!.totalCalories, 600);
    });

    test('recipe 429/403 KHÔNG cache thành "thiếu dữ liệu" → Error, retry lấy lại', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(600)},
      );
      recipeApi.errors['a'] = BusinessException('ERR_RATE_LIMIT', 'slow');
      store.attach(mealPlan);
      await settle();
      expect(store.state, isA<ErrorState<NutritionWeekSummary>>());
      expect(store.nutritionCache.containsKey('a'), isFalse);

      recipeApi.errors.clear();
      await store.retry();
      await settle();
      expect(store.summary!.totalCalories, 600);
    });

    test('lỗi recipe của tuần khác không làm lỗi tuần đang xem', () async {
      await setUpWith(
        (w) => w == week
            ? <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['bad'])]
            : <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['ok'])],
        nutrition: <String, dynamic>{'ok': kcal(700)},
      );
      recipeApi.errors['bad'] = NetworkException();
      store.attach(mealPlan);
      await settle();
      expect(store.state, isA<ErrorState<NutritionWeekSummary>>());
      await mealPlan.navigateWeek(1);
      await settle();
      expect(store.summary!.totalCalories, 700);
    });

    test('followTarget: nguồn target đổi → điểm đổi ngay', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(2300)},
        target: null,
      );
      final source = Observable<int?>(null);
      store
        ..attach(mealPlan)
        ..followTarget(() {
          final v = source.value;
          return v == null ? null : () => v;
        });
      await settle();
      expect(store.complianceScore, isNull);
      runInAction(() => source.value = 2000);
      expect(store.complianceScore, 90);
    });

    test('lỗi mạng → Error; retry thành công', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(600)},
      );
      recipeApi.errors['a'] = NetworkException();
      store.attach(mealPlan);
      await settle();
      expect(store.state, isA<ErrorState<NutritionWeekSummary>>());

      recipeApi.errors.clear();
      await store.retry();
      await settle();
      expect(store.summary!.totalCalories, 600);
    });

    test('target lỗi → Error; target null → Success với level unknown', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(600)},
        target: null,
      );
      healthApi.error = StateError('boom');
      store.attach(mealPlan);
      await settle();
      expect(store.state, isA<ErrorState<NutritionWeekSummary>>());

      healthApi.error = null;
      await store.retry();
      await settle();
      expect(store.complianceLevel, ComplianceLevel.unknown);
      expect(store.complianceScore, isNull);
    });

    test('refreshTarget sau khi đặt mục tiêu → có điểm', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(2000)},
        target: null,
      );
      store.attach(mealPlan);
      await settle();
      expect(store.complianceScore, isNull);
      healthApi.target = 2000;
      await store.refreshTarget();
      expect(store.complianceScore, 100);
    });

    test('đổi tuần: không hiện số tuần cũ trong lúc chờ recipe tuần mới', () async {
      await setUpWith(
        (w) => w == week
            ? <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])]
            : <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['n'])],
        nutrition: <String, dynamic>{'a': kcal(500), 'n': kcal(900)},
      );
      store.attach(mealPlan);
      await settle();
      recipeApi.hold['n'] = Completer<void>();
      await mealPlan.navigateWeek(1);
      expect(store.state, isA<LoadingState<NutritionWeekSummary>>());
      recipeApi.hold['n']!.complete();
      await settle();
      expect(store.summary!.totalCalories, 900);
    });

    test('attach 2 lần không đăng ký thêm; onClose dừng fetch', () async {
      await setUpWith(
        (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['a'])],
        nutrition: <String, dynamic>{'a': kcal(500), 'b': kcal(500)},
      );
      store
        ..attach(mealPlan)
        ..attach(mealPlan);
      await settle();
      expect(recipeApi.getByIdCalls, <String>['a']);
      store.onClose();
      runInAction(() => mealPlan.slots['n_LUNCH'] = plannedSlot(week, 3, 'LUNCH', <String>['b']));
      await settle();
      expect(recipeApi.getByIdCalls, <String>['a']);
    });
  });

  group('loadCurrentWeek (Profile)', () {
    test('tải plan + target rồi tính', () async {
      await setUpWith(
        (_) => const <MealPlanSlot>[],
        nutrition: <String, dynamic>{'a': kcal(1900)},
      );
      planApi.onGetCurrent = () async => planOf(week, <MealPlanSlot>[plannedSlot(week, 0, 'LUNCH', <String>['a'])]);
      await store.loadCurrentWeek();
      await settle();
      expect(store.summary!.totalCalories, 1900);
      expect(store.complianceScore, 100);
    });

    test('ERR_PLAN_NOT_FOUND → Empty, không lỗi', () async {
      await setUpWith((_) => const <MealPlanSlot>[]);
      planApi.onGetCurrentError = BusinessException('ERR_PLAN_NOT_FOUND', 'none');
      await store.loadCurrentWeek();
      expect(store.state, isA<EmptyState<NutritionWeekSummary>>());
    });

    test('lỗi khác → Error; retry tải lại', () async {
      await setUpWith((_) => const <MealPlanSlot>[], nutrition: <String, dynamic>{'a': kcal(500)});
      planApi.onGetCurrentError = NetworkException();
      await store.loadCurrentWeek();
      expect(store.state, isA<ErrorState<NutritionWeekSummary>>());

      planApi.onGetCurrentError = null;
      planApi.onGetCurrent = () async => planOf(week, <MealPlanSlot>[plannedSlot(week, 0, 'LUNCH', <String>['a'])]);
      await store.retry();
      await settle();
      expect(store.summary!.totalCalories, 500);
    });
  });
}
