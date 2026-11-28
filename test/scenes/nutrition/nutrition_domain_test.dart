import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_type.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/compliance.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/domain/weekly_nutrition_calculator.dart';

import 'nutrition_fakes.dart';

final DateTime monday = DateTime(2026, 11, 16);

DateTime at(int day, {int hour = 12, int minute = 0}) =>
    monday.add(Duration(days: day, hours: hour, minutes: minute));

List<({bool hasData, double calories, bool hasMissingData})> days(List<double?> kcal,
        {bool missing = false}) =>
    <({bool hasData, double calories, bool hasMissingData})>[
      for (final k in kcal) (hasData: k != null, calories: k ?? 0, hasMissingData: missing),
    ];

void main() {
  group('computeComplianceScore (AC issue #64)', () {
    test('7 ngày đều đạt target → 100', () {
      expect(
        computeComplianceScore(days: days(List.filled(7, 2000)), targetDailyCalories: 2000),
        100,
      );
    });

    test('1 ngày vượt 15% → 90', () {
      expect(
        computeComplianceScore(
            days: days(<double>[2300, 2000, 2000, 2000, 2000, 2000, 2000]),
            targetDailyCalories: 2000),
        90,
      );
    });

    test('biên 110% / 80% không trừ; vượt chặt thì trừ', () {
      expect(computeComplianceScore(days: days(<double?>[2200, 1600]), targetDailyCalories: 2000), 100);
      expect(computeComplianceScore(days: days(<double?>[2201]), targetDailyCalories: 2000), 90);
      expect(computeComplianceScore(days: days(<double?>[1599]), targetDailyCalories: 2000), 95);
    });

    test('ngày không có dữ liệu không bị trừ; kẹp tại 0', () {
      expect(computeComplianceScore(days: days(<double?>[null, null, 1000]), targetDailyCalories: 2000), 95);
      expect(
        computeComplianceScore(
            days: days(List<double>.filled(11, 5000)), targetDailyCalories: 2000),
        0,
      );
    });

    test('ngày có món thiếu dữ liệu: không trừ "thiếu", vẫn trừ "vượt"', () {
      expect(computeComplianceScore(days: days(<double?>[1000], missing: true), targetDailyCalories: 2000), 100);
      expect(computeComplianceScore(days: days(<double?>[2500], missing: true), targetDailyCalories: 2000), 90);
    });

    test('không có target / target ≤ 0 / không ngày nào có dữ liệu → null', () {
      expect(computeComplianceScore(days: days(<double>[2000]), targetDailyCalories: null), isNull);
      expect(computeComplianceScore(days: days(<double>[2000]), targetDailyCalories: 0), isNull);
      expect(computeComplianceScore(days: days(<double?>[null, null]), targetDailyCalories: 2000), isNull);
    });
  });

  test('levelForScore ở các ngưỡng', () {
    expect(levelForScore(100), ComplianceLevel.excellent);
    expect(levelForScore(90), ComplianceLevel.excellent);
    expect(levelForScore(89), ComplianceLevel.good);
    expect(levelForScore(70), ComplianceLevel.good);
    expect(levelForScore(69), ComplianceLevel.needsImprovement);
    expect(levelForScore(50), ComplianceLevel.needsImprovement);
    expect(levelForScore(49), ComplianceLevel.poor);
    expect(levelForScore(0), ComplianceLevel.poor);
    expect(levelForScore(null), ComplianceLevel.unknown);
  });

  group('computeWeeklyNutritionFromLogs', () {
    test('luôn 7 ngày; cộng mọi log đã tính của mình trong ngày', () {
      final summary = computeWeeklyNutritionFromLogs(
        weekStart: monday,
        logs: <MealLogEntry>[
          logAt(at(0, hour: 7), kcal: 400, meal: MealType.breakfast),
          logAt(at(0, hour: 12), kcal: 600),
          logAt(at(0, hour: 15), kcal: 200, meal: MealType.snack),
        ],
        memberId: selfId,
        targetDailyCalories: 2000,
      );
      expect(summary.days, hasLength(7));
      expect(summary.days.first.calories, 1200);
      expect(summary.days.first.plannedDishCount, 3);
      expect(summary.days.first.lines.map((l) => l.mealTime),
          <String>['BREAKFAST', 'LUNCH', 'SNACK']);
      expect(summary.days.first.lines.first.recipeName, 'Phở',
          reason: 'bỏ tiền tố [Bữa sáng]');
      expect(summary.days[1].hasPlannedMeals, isFalse);
      expect(summary.totalProtein, 60);
    });

    test('KHÔNG cộng log của thành viên khác (nguồn trả cả hộ)', () {
      final summary = computeWeeklyNutritionFromLogs(
        weekStart: monday,
        logs: <MealLogEntry>[
          logAt(at(0), kcal: 500),
          logAt(at(0), kcal: 900, memberId: 'other'),
        ],
        memberId: selfId,
        targetDailyCalories: 2000,
      );
      expect(summary.totalCalories, 500);
      expect(summary.plannedDishCount, 1);
    });

    test('log chờ xác nhận / chưa có calo: không cộng, đếm là thiếu dữ liệu', () {
      final summary = computeWeeklyNutritionFromLogs(
        weekStart: monday,
        logs: <MealLogEntry>[
          logAt(at(0), kcal: 300),
          logAt(at(0), kcal: 800, requiresConfirmation: true),
          logAt(at(1), kcal: null),
          logAt(at(2), kcal: 700, requiresConfirmation: true, confirmedByUser: true),
        ],
        memberId: selfId,
        targetDailyCalories: 2000,
      );
      expect(summary.days[0].calories, 300);
      expect(summary.days[0].missingNutritionCount, 1);
      expect(summary.days[1].hasNutritionData, isFalse);
      expect(summary.days[2].calories, 700, reason: 'đã xác nhận thì tính');
      expect(summary.missingNutritionCount, 2);
      expect(summary.daysWithData, 2);
      expect(summary.avgDailyCalories, 500);
    });

    test('log đang gửi/lỗi bị bỏ; log ngoài tuần bị bỏ; biên Thứ Hai 00:00 / CN 23:59', () {
      final summary = computeWeeklyNutritionFromLogs(
        weekStart: monday,
        logs: <MealLogEntry>[
          logAt(at(0, hour: 0), kcal: 100),
          logAt(at(6, hour: 23, minute: 59), kcal: 200),
          logAt(at(-1, hour: 23, minute: 59), kcal: 999),
          logAt(at(7, hour: 0), kcal: 999),
          logAt(at(3), kcal: 999, status: MealEntryStatus.pending),
          logAt(at(3), kcal: 999, status: MealEntryStatus.failed),
        ],
        memberId: selfId,
        targetDailyCalories: 2000,
      );
      expect(summary.days[0].calories, 100);
      expect(summary.days[6].calories, 200);
      expect(summary.totalCalories, 300);
    });

    test('loggedAt dạng UTC được đổi về giờ máy trước khi xếp ngày', () {
      final local = at(2, hour: 12);
      final summary = computeWeeklyNutritionFromLogs(
        weekStart: monday,
        logs: <MealLogEntry>[logAt(local.toUtc(), kcal: 400)],
        memberId: selfId,
        targetDailyCalories: 2000,
      );
      expect(summary.days[2].calories, 400);
      expect(summary.targetForDaysWithData, 2000);
    });

    test('macroRatios theo năng lượng — 100/200/50 g → 400/800/450 kcal → 24.2% / 48.5% / 27.3%', () {
      final summary = computeWeeklyNutritionFromLogs(
        weekStart: monday,
        logs: <MealLogEntry>[logAt(at(0), kcal: 1650, p: 100, c: 200, f: 50)],
        memberId: selfId,
        targetDailyCalories: 2000,
      );
      final ratios = summary.macroRatios!;
      expect(ratios.protein, closeTo(24.2, 0.05));
      expect(ratios.carbs, closeTo(48.5, 0.05));
      expect(ratios.fat, closeTo(27.3, 0.05));
    });

    test('tuần trống → score null, level unknown', () {
      final empty = computeWeeklyNutritionFromLogs(
        weekStart: monday,
        logs: const <MealLogEntry>[],
        memberId: selfId,
        targetDailyCalories: 2000,
      );
      expect(empty.complianceScore, isNull);
      expect(empty.level, ComplianceLevel.unknown);
      expect(empty.avgDailyCalories, isNull);
      expect(empty.targetForDaysWithData, isNull);
      expect(empty.macroRatios, isNull);
    });
  });

  test('mondayOf: mọi ngày trong tuần về Thứ Hai 00:00', () {
    expect(mondayOf(DateTime(2026, 11, 16, 8)), monday);
    expect(mondayOf(DateTime(2026, 11, 22, 23, 59)), monday);
    expect(mondayOf(DateTime(2026, 11, 23)), DateTime(2026, 11, 23));
  });

  test('dayTargetStatus', () {
    expect(dayTargetStatus(hasData: false, calories: 0, targetDailyCalories: 2000), DayTargetStatus.noData);
    expect(dayTargetStatus(hasData: true, calories: 2300, targetDailyCalories: 2000), DayTargetStatus.over);
    expect(dayTargetStatus(hasData: true, calories: 1500, targetDailyCalories: 2000), DayTargetStatus.under);
    expect(dayTargetStatus(hasData: true, calories: 2000, targetDailyCalories: null), DayTargetStatus.onTarget);
  });
}
