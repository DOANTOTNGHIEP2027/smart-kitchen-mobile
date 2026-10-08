import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_type.dart';

import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/food_item_detected.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_nutrition_macros.dart';

void main() {
  group('MealType.composeDescription / parseMealTypeFromDescription', () {
    test('round-trip đúng cho cả 4 loại, text giữ nguyên', () {
      for (final type in MealType.values) {
        final desc = type.composeDescription('  2 chén cơm  ');
        expect(desc, '[${labelOf(type)}] 2 chén cơm');
        expect(parseMealTypeFromDescription(desc), type);
      }
    });

    test('description rỗng vẫn có tiền tố (non-empty — Guard #9)', () {
      expect(MealType.lunch.composeDescription(null), '[Bữa trưa]');
      expect(MealType.lunch.composeDescription('   '), '[Bữa trưa]');
      expect(MealType.lunch.composeDescription('').isEmpty, isFalse);
    });

    test('description không khớp tiền tố → null, không throw (Guard #2)', () {
      expect(parseMealTypeFromDescription('1 tô phở'), isNull);
      expect(parseMealTypeFromDescription(null), isNull);
      expect(parseMealTypeFromDescription('[Không biết] abc'), isNull);
    });

    test('khớp đúng tiền tố đầu dù nội dung có ký tự giống', () {
      expect(parseMealTypeFromDescription('[Bữa sáng] [Bữa trưa]'), MealType.breakfast);
    });
  });

  group('MealNutritionMacros.fromJson + FoodItemDetected.fromJson', () {
    test('parse double lẫn int qua num coercion (Guard #11)', () {
      final macros = MealNutritionMacros.fromJson(<String, dynamic>{
        'proteinG': 28, // int
        'carbsG': 55.5,
        'fatG': 14,
        'fiberG': null,
      });
      expect(macros.proteinG, 28.0);
      expect(macros.carbsG, 55.5);
      expect(macros.fatG, 14.0);
      expect(macros.fiberG, isNull);

      final item = FoodItemDetected.fromJson(<String, dynamic>{
        'name': 'Phở',
        'estimatedQuantity': '200g',
        'estimatedCaloriesKcal': 220,
      });
      expect(item.name, 'Phở');
      expect(item.estimatedQuantity, '200g');
      expect(item.estimatedCaloriesKcal, 220.0);
    });
  });

  group('MealLogEntry.confidenceBadge / countsTowardDailyTotal', () {
    MealLogEntry entry({
      double? caloriesKcal,
      bool requiresConfirmation = false,
      bool confirmedByUser = false,
    }) {
      return MealLogEntry(
        id: 'id1',
        householdId: 'h1',
        memberId: 'u1',
        loggedBy: 'u1',
        description: '[Bữa trưa] Phở',
        caloriesKcal: caloriesKcal,
        requiresConfirmation: requiresConfirmation,
        confirmedByUser: confirmedByUser,
        loggedAt: DateTime.parse('2026-09-16T07:00:00Z'),
        status: MealEntryStatus.saved,
      );
    }

    test('caloriesKcal null → noEstimate; non-null → confident/needsReview',
        () {
      expect(entry().confidenceBadge, MealConfidenceBadge.noEstimate);
      expect(entry(caloriesKcal: 480).confidenceBadge,
          MealConfidenceBadge.confident);
      expect(
          entry(caloriesKcal: 480, requiresConfirmation: true).confidenceBadge,
          MealConfidenceBadge.needsReview);
    });

    test('meetings predicate Guard #4 của BE', () {
      // calories null → không tính
      expect(entry().countsTowardDailyTotal, isFalse);
      // có calo, không cần confirm → tính
      expect(entry(caloriesKcal: 480).countsTowardDailyTotal, isTrue);
      // có calo, cần confirm, chưa confirm → KHÔNG tính
      expect(
          entry(caloriesKcal: 480, requiresConfirmation: true)
              .countsTowardDailyTotal,
          isFalse);
      // có calo, cần confirm, đã confirm → tính
      expect(
          entry(caloriesKcal: 480,
                  requiresConfirmation: true, confirmedByUser: true)
              .countsTowardDailyTotal,
          isTrue);
    });

    test('mealType parse từ description', () {
      expect(entry().mealType, MealType.lunch);
    });
  });
}

String labelOf(MealType t) => switch (t) {
      MealType.breakfast => 'Bữa sáng',
      MealType.lunch => 'Bữa trưa',
      MealType.dinner => 'Bữa tối',
      MealType.snack => 'Ăn vặt',
    };