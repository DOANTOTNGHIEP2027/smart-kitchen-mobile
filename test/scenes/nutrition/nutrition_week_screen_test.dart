import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/nutrition_week_screen.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';

import '../../helpers/pump_app.dart';
import 'nutrition_fakes.dart';

void main() {
  late NutritionMealLogApi logApi;
  late NutritionStore store;

  setUp(() {
    logApi = NutritionMealLogApi(
        <MealLogEntry>[logAt(DateTime(2026, 11, 16, 12), kcal: 1800)]);
    store = NutritionStore(
      mealLogApi: logApi,
      healthApi: NutritionHealthApi(target: 2000),
      selfId: () => selfId,
      now: () => DateTime(2026, 11, 18),
    );
    Get.put<NutritionStore>(store, tag: NutritionStore.profileTag);
  });

  tearDown(() {
    store.onClose();
    Get.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpAppWidget(const NutritionWeekScreen(), wrapInScaffold: false);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('vào màn thì tải tuần; hiện tiêu đề AppBar, nội dung và link nhật ký',
      (tester) async {
    await pumpScreen(tester);
    expect(logApi.calls, 1);
    expect(find.text('Bạn đã ăn tuần này'), findsOneWidget, reason: 'chỉ trên AppBar');
    expect(find.byKey(const ValueKey('nutrition-weekly-total')), findsOneWidget);
    expect(find.byKey(const ValueKey('nutrition-open-meal-log')), findsOneWidget);
  });

  testWidgets('lỗi → nút thử lại', (tester) async {
    logApi.error = NetworkException();
    await pumpScreen(tester);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('tuần chưa ghi bữa → empty', (tester) async {
    logApi.logs = <MealLogEntry>[];
    await pumpScreen(tester);
    expect(find.text('Tuần này bạn chưa ghi bữa ăn nào'), findsOneWidget);
  });
}
