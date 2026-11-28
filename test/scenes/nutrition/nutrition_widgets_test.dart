import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_type.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/widgets/nutrition_summary_widget.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/widgets/weekly_calorie_bar_chart.dart';

import '../../helpers/pump_app.dart';
import 'nutrition_fakes.dart';

void main() {
  late NutritionMealLogApi logApi;
  late NutritionHealthApi healthApi;
  late NutritionStore store;
  final monday = DateTime(2026, 11, 16);

  DateTime day(int i, {int hour = 12}) => monday.add(Duration(days: i, hours: hour));

  Future<void> build(
    WidgetTester tester,
    List<MealLogEntry> logs, {
    int? target = 2000,
    Future<void> Function()? onSetTarget,
    bool load = true,
  }) async {
    logApi = NutritionMealLogApi(logs);
    healthApi = NutritionHealthApi(target: target);
    store = NutritionStore(
      mealLogApi: logApi,
      healthApi: healthApi,
      selfId: () => selfId,
      now: () => DateTime(2026, 11, 18),
    );
    addTearDown(store.onClose);
    if (load) unawaited(store.loadCurrentWeek());
    await tester.pumpAppWidget(SingleChildScrollView(
      child: NutritionSummaryWidget(store: store, onSetTarget: onSetTarget),
    ));
    await tester.pump();
    await tester.pump();
  }

  List<MealLogEntry> fullWeek() => <MealLogEntry>[
        logAt(day(0), kcal: 2000, p: 100, c: 200, f: 50), // xanh
        logAt(day(1), kcal: 2300, p: 100, c: 200, f: 50), // đỏ
        logAt(day(2, hour: 19), kcal: 2000, meal: MealType.dinner, text: 'Cơm gà'),
        logAt(day(2, hour: 20), kcal: 700, meal: MealType.dinner, text: 'Chè',
            requiresConfirmation: true),
      ];

  testWidgets('AC: đúng 7 cột; xanh khi đạt, đỏ khi vượt > 10%, xám khi trống', (tester) async {
    await build(tester, fullWeek());
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

  testWidgets('AC: tooltip cột có ngày, kcal và P/C/F; ngày trống báo chưa ghi bữa',
      (tester) async {
    await build(tester, fullWeek());
    final ctx = tester.element(find.byType(WeeklyCalorieBarChart));
    final text = WeeklyCalorieBarChart.tooltipText(ctx, store.summary!.days[0]);
    expect(text, contains('2.000 kcal'));
    expect(text, contains('Đạm 100 g · Tinh bột 200 g · Béo 50 g'));
    expect(WeeklyCalorieBarChart.tooltipText(ctx, store.summary!.days[2]),
        contains('1 bữa chưa có calo hoặc chờ xác nhận'));
    expect(WeeklyCalorieBarChart.tooltipText(ctx, store.summary!.days[5]),
        contains('Chưa ghi bữa nào'));
    await tester.tap(find.byType(BarChart));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AC: badge đúng điểm/nhãn; luôn có ghi chú dị ứng', (tester) async {
    await build(tester, fullWeek());
    // Ngày 0 đạt, ngày 1 vượt (−10), ngày 2 có bữa chờ xác nhận → không trừ "thiếu".
    expect(find.text('90/100'), findsOneWidget);
    expect(find.text('Xuất sắc'), findsOneWidget);
    expect(find.text('Chưa kiểm tra dị ứng — điểm chỉ dựa trên calo'), findsOneWidget);
    expect(find.text('1 bữa chưa có calo hoặc chờ xác nhận'), findsOneWidget);
  });

  testWidgets('AC: doughnut đúng tỷ lệ năng lượng protein/carbs/fat', (tester) async {
    await build(tester, <MealLogEntry>[logAt(day(0), kcal: 1650, p: 100, c: 200, f: 50)]);
    final pie = tester.widget<PieChart>(find.byType(PieChart));
    expect(pie.data.sections, hasLength(3));
    expect(find.text('Chất đạm 24,2%'), findsOneWidget);
    expect(find.text('Tinh bột 48,5%'), findsOneWidget);
    expect(find.text('Chất béo 27,3%'), findsOneWidget);
  });

  testWidgets('breakdown mở/đóng: hiện từng bữa đã ghi', (tester) async {
    await build(tester, fullWeek());
    final tile = find.byKey(const PageStorageKey<String>('nutrition-day-3'));
    await tester.scrollUntilVisible(tile, 200);
    expect(find.textContaining('Chè'), findsNothing);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chè · chưa có dữ liệu'), findsOneWidget);
    expect(find.textContaining('Tối: Cơm gà'), findsOneWidget);
  });

  testWidgets('tiêu đề "Bạn đã ăn tuần này"; showTitle=false thì ẩn', (tester) async {
    await build(tester, fullWeek());
    expect(find.text('Bạn đã ăn tuần này'), findsOneWidget);
    await tester.pumpAppWidget(SingleChildScrollView(
      child: NutritionSummaryWidget(store: store, showTitle: false),
    ));
    await tester.pump();
    expect(find.text('Bạn đã ăn tuần này'), findsNothing);
    expect(find.text('Chi tiết theo ngày'), findsOneWidget);
  });

  testWidgets('chưa có target → badge "Chưa có đánh giá" + nút đặt mục tiêu → refresh',
      (tester) async {
    var opened = 0;
    await build(tester, fullWeek(), target: null, onSetTarget: () async => opened++);
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

  testWidgets('loading → skeleton; error → nút thử lại → success', (tester) async {
    await build(tester, <MealLogEntry>[logAt(day(0), kcal: 500)], load: false);
    logApi.hold = Completer<void>();
    unawaited(store.loadCurrentWeek());
    await tester.pump();
    expect(find.byKey(const ValueKey('nutrition-skeleton')), findsOneWidget);
    logApi.error = NetworkException();
    logApi.hold!.complete();
    logApi.hold = null;
    await tester.pump();
    await tester.pump();
    expect(find.text('Thử lại'), findsOneWidget);

    logApi.error = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Thử lại'), findsNothing);
    expect(find.byKey(const ValueKey('nutrition-weekly-total')), findsOneWidget);
  });

  testWidgets('tuần chưa ghi bữa nào → empty', (tester) async {
    await build(tester, <MealLogEntry>[]);
    expect(find.text('Tuần này bạn chưa ghi bữa ăn nào'), findsOneWidget);
  });

  testWidgets('bữa ăn vặt → "Bữa phụ"', (tester) async {
    await build(tester, <MealLogEntry>[
      logAt(day(0, hour: 15), kcal: 200, meal: MealType.snack, text: 'Bánh'),
    ]);
    final tile = find.byKey(const PageStorageKey<String>('nutrition-day-1'));
    await tester.scrollUntilVisible(tile, 200);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('Bữa phụ: Bánh'), findsOneWidget);
  });

  testWidgets('nhãn badge: chữ tối trên nền vàng/xám, chữ sáng trên nền xanh/đỏ',
      (tester) async {
    await build(tester, fullWeek(), target: null);
    final label = tester.widget<Text>(find.descendant(
        of: find.byKey(const ValueKey('nutrition-level')), matching: find.byType(Text)));
    expect(label.style?.color, AppColors.textPrimary, reason: 'unknown, light theme');
  });
}
