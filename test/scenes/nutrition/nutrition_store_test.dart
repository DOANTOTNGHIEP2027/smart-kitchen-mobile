import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/compliance.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/nutrition_models.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import 'nutrition_fakes.dart';

void main() {
  late NutritionMealLogApi logApi;
  late NutritionHealthApi healthApi;
  late NutritionStore store;
  final monday = DateTime(2026, 11, 16);
  final wednesday = DateTime(2026, 11, 18, 9);

  void setUpWith(List<MealLogEntry> logs, {int? target = 2000, String? self = selfId}) {
    logApi = NutritionMealLogApi(logs);
    healthApi = NutritionHealthApi(target: target);
    store = NutritionStore(
      mealLogApi: logApi,
      healthApi: healthApi,
      selfId: () => self,
      now: () => wednesday,
    );
  }

  DateTime day(int i, {int hour = 12}) => monday.add(Duration(days: i, hours: hour));

  tearDown(() => store.onClose());

  test('gọi nhật ký của CHÍNH MÌNH, đúng Thứ Hai → Chủ Nhật, size 100', () async {
    setUpWith(<MealLogEntry>[]);
    await store.loadCurrentWeek();
    expect(logApi.lastMemberId, selfId);
    expect(logApi.lastFrom, monday);
    expect(logApi.lastTo, DateTime(2026, 11, 22));
    expect(logApi.lastSize, NutritionStore.weekPageSize);
  });

  test('Loading → Success: tổng, trung bình, điểm theo mục tiêu cá nhân', () async {
    setUpWith(<MealLogEntry>[
      logAt(day(0), kcal: 2000),
      logAt(day(1, hour: 7), kcal: 1000),
      logAt(day(1, hour: 19), kcal: 1300),
    ]);
    expect(store.state, isA<LoadingState<NutritionWeekSummary>>());
    final future = store.loadCurrentWeek();
    expect(store.state, isA<LoadingState<NutritionWeekSummary>>());
    await future;

    final summary = store.summary!;
    expect(summary.totalCalories, 4300);
    expect(store.avgDailyCalories, 2150);
    expect(store.complianceScore, 90, reason: 'ngày 2 = 2300 > 110%');
    expect(store.complianceLevel, ComplianceLevel.excellent);
  });

  test('log của người khác lọt vào vẫn không được cộng', () async {
    setUpWith(<MealLogEntry>[
      logAt(day(0), kcal: 600),
      logAt(day(0), kcal: 1500, memberId: 'mom'),
    ]);
    await store.loadCurrentWeek();
    expect(store.summary!.totalCalories, 600);
  });

  test('chưa ghi bữa nào tuần này → Empty', () async {
    setUpWith(<MealLogEntry>[]);
    await store.loadCurrentWeek();
    expect(store.state, isA<EmptyState<NutritionWeekSummary>>());
  });

  test('chưa có user → không gọi API', () async {
    setUpWith(<MealLogEntry>[], self: null);
    await store.loadCurrentWeek();
    expect(logApi.calls, 0);
  });

  test('lỗi mạng → Error; retry tải lại thành công', () async {
    setUpWith(<MealLogEntry>[logAt(day(0), kcal: 600)]);
    logApi.error = NetworkException();
    await store.loadCurrentWeek();
    expect(store.state, isA<ErrorState<NutritionWeekSummary>>());

    logApi.error = null;
    await store.retry();
    expect(store.summary!.totalCalories, 600);
  });

  test('target lỗi → Error; target null → Success với level unknown', () async {
    setUpWith(<MealLogEntry>[logAt(day(0), kcal: 600)], target: null);
    healthApi.error = StateError('boom');
    await store.loadCurrentWeek();
    expect(store.state, isA<ErrorState<NutritionWeekSummary>>());

    healthApi.error = null;
    await store.retry();
    expect(store.complianceLevel, ComplianceLevel.unknown);
    expect(store.complianceScore, isNull);
  });

  test('tải lại: giữ số cũ, không về Loading', () async {
    setUpWith(<MealLogEntry>[logAt(day(0), kcal: 600)]);
    await store.loadCurrentWeek();
    logApi.hold = Completer<void>();
    logApi.logs = <MealLogEntry>[logAt(day(0), kcal: 600), logAt(day(1), kcal: 400)];
    final future = store.loadCurrentWeek();
    expect(store.summary!.totalCalories, 600);
    logApi.hold!.complete();
    await future;
    expect(store.summary!.totalCalories, 1000);
  });

  test('followTarget: nguồn target đổi → điểm đổi ngay', () async {
    setUpWith(<MealLogEntry>[logAt(day(0), kcal: 2300)], target: null);
    final source = Observable<int?>(null);
    store.followTarget(() {
      final v = source.value;
      return v == null ? null : () => v;
    });
    await store.loadCurrentWeek();
    expect(store.complianceScore, isNull);
    runInAction(() => source.value = 2000);
    expect(store.complianceScore, 90);
  });

  test('refreshTarget sau khi đặt mục tiêu → có điểm', () async {
    setUpWith(<MealLogEntry>[logAt(day(0), kcal: 2000)], target: null);
    await store.loadCurrentWeek();
    expect(store.complianceScore, isNull);
    healthApi.target = 2000;
    await store.refreshTarget();
    expect(store.complianceScore, 100);
  });
}
