import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_nutrition_macros.dart';
import 'package:smart_kitchen_mobile/scenes/insights/domain/nutrition_aggregator.dart';

MealLogEntry _log(
  int day, {
  double? calories,
  double? protein,
  double? carbs,
  double? fat,
  bool requiresConfirmation = false,
  bool confirmedByUser = true,
  int hour = 12,
}) {
  return MealLogEntry(
    id: 'log-$day-$hour',
    householdId: 'h1',
    memberId: 'self',
    loggedBy: 'self',
    caloriesKcal: calories,
    nutrition: protein == null && carbs == null && fat == null
        ? null
        : MealNutritionMacros(
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
          ),
    requiresConfirmation: requiresConfirmation,
    confirmedByUser: confirmedByUser,
    // UTC → cộng +7 tới VN. hour=17 UTC = 00:00 VN ngày kế tiếp.
    loggedAt: DateTime.utc(2026, 3, day, hour),
    status: MealEntryStatus.saved,
  );
}

void main() {
  group('NutritionAggregator.aggregateByDay', () {
    test('trả đúng N ngày inclusive, cả ngày không có log → point rỗng',
        () {
      final result = NutritionAggregator.aggregateByDay(
        logs: <MealLogEntry>[
          _log(5, calories: 500, protein: 20, carbs: 50, fat: 10),
        ],
        from: DateTime(2026, 3, 3),
        to: DateTime(2026, 3, 6),
      );

      expect(result.length, 4);
      expect(result[0].date, DateTime(2026, 3, 3));
      expect(result[0].hasData, isFalse);
      expect(result[1].date, DateTime(2026, 3, 4));
      expect(result[1].hasData, isFalse);
      expect(result[2].date, DateTime(2026, 3, 5));
      expect(result[2].hasData, isTrue);
      expect(result[3].hasData, isFalse);
    });

    test('ngày có N log → sum đúng calo/macro', () {
      final result = NutritionAggregator.aggregateByDay(
        logs: <MealLogEntry>[
          _log(5, calories: 300, protein: 10, carbs: 20, fat: 5),
          _log(5, calories: 200, protein: 12, carbs: 30, fat: 3, hour: 16),
        ],
        from: DateTime(2026, 3, 5),
        to: DateTime(2026, 3, 5),
      );

      final p = result.single;
      expect(p.caloriesKcal, 500);
      expect(p.proteinG, 22);
      expect(p.carbsG, 50);
      expect(p.fatG, 8);
    });

    test('log requires_confirmation chưa confirm → KHÔNG tính, ngày đó null',
        () {
      final result = NutritionAggregator.aggregateByDay(
        logs: <MealLogEntry>[
          _log(5,
              calories: 300,
              protein: 10,
              requiresConfirmation: true,
              confirmedByUser: false),
        ],
        from: DateTime(2026, 3, 5),
        to: DateTime(2026, 3, 5),
      );

      // Không phải 0 — phải null (đủ điều kiện mới cộng).
      expect(result.single.hasData, isFalse);
      expect(result.single.caloriesKcal, isNull);
    });

    test('timezone biên: logged_at UTC 17:00 = 00:00 VN ngày KẾ TIẾP', () {
      final result = NutritionAggregator.aggregateByDay(
        // 2026-03-05T17:00 UTC → VN 2026-03-06 00:00.
        logs: <MealLogEntry>[_log(5, calories: 400, hour: 17)],
        from: DateTime(2026, 3, 5),
        to: DateTime(2026, 3, 6),
      );

      expect(result[0].hasData, isFalse); // 2026-03-05 UTC-ngày
      expect(result[1].hasData, isTrue); // 2026-03-06 VN
    });

    test('ngày có log confirmed lẫn unconfirmed → chỉ cộng confirmed', () {
      final result = NutritionAggregator.aggregateByDay(
        logs: <MealLogEntry>[
          _log(5, calories: 100, protein: 5),
          _log(5,
              calories: 400,
              protein: 20,
              requiresConfirmation: true,
              confirmedByUser: false,
              hour: 19),
        ],
        from: DateTime(2026, 3, 5),
        to: DateTime(2026, 3, 5),
      );

      expect(result.single.caloriesKcal, 100);
      expect(result.single.proteinG, 5);
    });

    test('thứ tự kết quả tăng dần ngay cả khi logs nhập bát nháo', () {
      final result = NutritionAggregator.aggregateByDay(
        logs: <MealLogEntry>[
          _log(3, calories: 100),
          _log(1, calories: 200),
          _log(2, calories: 300),
        ],
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 3),
      );

      expect(result.map((p) => p.caloriesKcal).toList(), <double?>[200, 300, 100]);
    });
  });
}