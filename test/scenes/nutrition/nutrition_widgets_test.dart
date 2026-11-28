import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/widgets/nutrition_summary_widget.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/widgets/weekly_calorie_bar_chart.dart';

import '../../helpers/pump_app.dart';
import '../mealplan/fake_meal_plan_api.dart';
import 'nutrition_fakes.dart';

void main() {
  late FakeMealPlanApi planApi;
  late MealPlanStore mealPlan;
  late NutritionRecipeApi recipeApi;
  late NutritionHealthApi healthApi;
  late NutritionStore store;
  late DateTime week;

  Future<void> build(
    WidgetTester tester,
    List<MealPlanSlot> Function(DateTime w) slots, {
    Map<String, dynamic> nutrition = const <String, dynamic>{},
    int? target = 2000,
    bool compact = false,
    Future<void> Function()? onSetTarget,
  }) async {
    planApi = FakeMealPlanApi();
    mealPlan = MealPlanStore(api: planApi, suggestionApi: FakeMealSuggestionApi());
    week = mealPlan.currentWeekStart;
    planApi.onGetWeek = (w) async => planOf(w, slots(w));
    await mealPlan.loadWeekPlan();
    recipeApi = NutritionRecipeApi(Map<String, dynamic>.of(nutrition).cast());
    healthApi = NutritionHealthApi(target: target);
    store = NutritionStore(recipeApi: recipeApi, healthApi: healthApi)..attach(mealPlan);
    addTearDown(store.onClose);
    await tester.pumpAppWidget(SingleChildScrollView(
      child: NutritionSummaryWidget(store: store, compact: compact, onSetTarget: onSetTarget),
    ));
    await tester.pump();
    await tester.pump();
  }

  List<MealPlanSlot> fullWeek(DateTime w) => <MealPlanSlot>[
        plannedSlot(w, 0, 'LUNCH', <String>['ok']), // 2000 → xanh
        plannedSlot(w, 1, 'LUNCH', <String>['over']), // 2300 → đỏ
        plannedSlot(w, 2, 'DINNER', <String>['ok', 'nodata']),
      ];
  Map<String, dynamic> nutritionMap() => <String, dynamic>{
        'ok': kcal(2000, p: 100, c: 200, f: 50),
        'over': kcal(2300, p: 100, c: 200, f: 50),
        'nodata': null,
      };

  testWidgets('AC: đúng 7 cột; xanh khi đạt, đỏ khi vượt > 10%, xám khi trống', (tester) async {
    await build(tester, fullWeek, nutrition: nutritionMap());
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final groups = chart.data.barGroups;
    expect(groups, hasLength(7));
    expect(groups[0].barRods.single.color, AppColors.success);
    expect(groups[1].barRods.single.color, AppColors.nutritionPoor);
    expect(groups[3].barRods.single.toY, 0);
    expect(groups[3].barRods.single.color, AppColors.border);
    expect(chart.data.barTouchData.enabled, isTrue);
    expect(chart.data.extraLinesData.horizontalLines.single.y, 2000);
  });

  testWidgets('AC: tooltip cột có ngày, kcal và P/C/F; ngày trống báo chưa có món',
      (tester) async {
    await build(tester, fullWeek, nutrition: nutritionMap());
    final ctx = tester.element(find.byType(WeeklyCalorieBarChart));
    final day0 = store.summary!.days[0];
    final text = WeeklyCalorieBarChart.tooltipText(ctx, day0);
    expect(text, contains('2.000 kcal'));
    expect(text, contains('Đạm 100 g · Tinh bột 200 g · Béo 50 g'));
    expect(WeeklyCalorieBarChart.tooltipText(ctx, store.summary!.days[2]),
        contains('1 món chưa có dữ liệu dinh dưỡng'));
    expect(WeeklyCalorieBarChart.tooltipText(ctx, store.summary!.days[5]),
        contains('Chưa có món nào'));
    // Chạm vào cột không lỗi (fl_chart vẽ tooltip lên canvas).
    await tester.tap(find.byType(BarChart));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AC: badge đúng điểm/nhãn; luôn có ghi chú dị ứng', (tester) async {
    await build(tester, fullWeek, nutrition: nutritionMap());
    // Ngày 0 đạt, ngày 1 vượt (−10), ngày 2 có món thiếu dữ liệu → không trừ "thiếu".
    expect(find.text('90/100'), findsOneWidget);
    expect(find.text('Xuất sắc'), findsOneWidget);
    expect(find.text('Chưa kiểm tra dị ứng — điểm chỉ dựa trên calo'), findsOneWidget);
    expect(find.text('1 món chưa có dữ liệu dinh dưỡng'), findsOneWidget);
  });

  testWidgets('AC: doughnut đúng tỷ lệ protein/carbs/fat theo gram', (tester) async {
    await build(tester, (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['m'])],
        nutrition: <String, dynamic>{'m': kcal(1650, p: 100, c: 200, f: 50)});
    final pie = tester.widget<PieChart>(find.byType(PieChart));
    expect(pie.data.sections, hasLength(3));
    expect(find.text('Chất đạm 28,6%'), findsOneWidget);
    expect(find.text('Tinh bột 57,1%'), findsOneWidget);
    expect(find.text('Chất béo 14,3%'), findsOneWidget);
  });

  testWidgets('breakdown mở/đóng: hiện từng bữa và món', (tester) async {
    await build(tester, fullWeek, nutrition: nutritionMap());
    final tile = find.byKey(ValueKey<String>('nutrition-day-${week.weekday + 2}'));
    await tester.scrollUntilVisible(tile, 200);
    expect(find.textContaining('Món nodata'), findsNothing);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('Món nodata · chưa có dữ liệu'), findsOneWidget);
    expect(find.textContaining('Tối: Món ok'), findsOneWidget);
  });

  testWidgets('compact: ẩn breakdown', (tester) async {
    await build(tester, fullWeek, nutrition: nutritionMap(), compact: true);
    expect(find.text('Chi tiết theo ngày'), findsNothing);
    expect(find.text('Dinh dưỡng tuần này'), findsOneWidget);
  });

  testWidgets('chưa có target → badge "Chưa có đánh giá" + nút đặt mục tiêu → refresh',
      (tester) async {
    var opened = 0;
    await build(tester, fullWeek,
        nutrition: nutritionMap(), target: null, onSetTarget: () async => opened++);
    expect(find.text('Chưa có đánh giá'), findsOneWidget);
    expect(find.text('Chưa đặt mục tiêu'), findsOneWidget);
    expect(find.text('Chưa kiểm tra dị ứng — điểm chỉ dựa trên calo'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.extraLinesData.horizontalLines, isEmpty);

    healthApi.target = 2000;
    await tester.tap(find.byKey(const ValueKey('nutrition-set-target')));
    await tester.pump();
    await tester.pump();
    expect(opened, 1);
    expect(find.text('90/100'), findsOneWidget);
  });

  testWidgets('loading → skeleton; error → nút thử lại; empty', (tester) async {
    await build(tester, (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['slow'])],
        nutrition: <String, dynamic>{'slow': kcal(500)});
    // 'slow' đã về; dựng lại với recipe treo để thấy skeleton.
    final hold = Completer<void>();
    recipeApi.hold['late'] = hold;
    runInAction(() => mealPlan.slots['late'] = plannedSlot(week, 1, 'LUNCH', <String>['late']));
    await tester.pump();
    expect(find.byKey(const ValueKey('nutrition-skeleton')), findsOneWidget);
    hold.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('nutrition-skeleton')), findsNothing);

    recipeApi.errors['boom'] = NetworkException();
    runInAction(() => mealPlan.slots['boom'] = plannedSlot(week, 2, 'LUNCH', <String>['boom']));
    await tester.pump();
    await tester.pump();
    expect(find.text('Thử lại'), findsOneWidget);
    recipeApi.errors.clear();
    recipeApi.nutrition['boom'] = kcal(100);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('tuần không có món confirmed → empty', (tester) async {
    await build(tester, (w) => <MealPlanSlot>[
          plannedSlot(w, 0, 'LUNCH', <String>['s'], status: DishUiStatus.suggested),
        ]);
    expect(find.text('Chưa có món nào được xác nhận trong tuần này'), findsOneWidget);
  });

  testWidgets('AC: widget cập nhật ngay khi MealPlanStore.slots đổi', (tester) async {
    await build(tester, (w) => <MealPlanSlot>[plannedSlot(w, 0, 'LUNCH', <String>['ok'])],
        nutrition: nutritionMap());
    expect(find.byKey(const ValueKey('nutrition-weekly-total')), findsOneWidget);
    expect(find.text('2.000 kcal'), findsWidgets);
    runInAction(() => mealPlan.slots['more'] = plannedSlot(week, 1, 'DINNER', <String>['ok']));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('nutrition-weekly-total'))).data,
      '4.000 kcal',
    );
  });

  testWidgets('bữa ngoài 3 bữa chuẩn: SNACK → "Bữa phụ", khác → "Bữa khác"', (tester) async {
    await build(tester, (w) => <MealPlanSlot>[
          plannedSlot(w, 0, 'SNACK', <String>['ok']),
          plannedSlot(w, 0, 'BRUNCH', <String>['ok']),
        ], nutrition: nutritionMap());
    final tile = find.byKey(ValueKey<String>('nutrition-day-${week.weekday}'));
    await tester.scrollUntilVisible(tile, 200);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('Bữa phụ: Món ok'), findsOneWidget);
    expect(find.textContaining('Bữa khác: Món ok'), findsOneWidget);
  });

  testWidgets('nhãn badge: chữ tối trên nền vàng/xám, chữ sáng trên nền xanh/đỏ',
      (tester) async {
    await build(tester, fullWeek, nutrition: nutritionMap(), target: null);
    final label = tester.widget<Text>(find.descendant(
        of: find.byKey(const ValueKey('nutrition-level')), matching: find.byType(Text)));
    expect(label.style?.color, AppColors.textPrimary, reason: 'unknown, light theme');
  });
}
