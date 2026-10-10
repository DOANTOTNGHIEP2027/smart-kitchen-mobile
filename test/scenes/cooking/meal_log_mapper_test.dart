import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/meal_log_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';

void main() {
  group('MealLogMapper.fromJson (CAMELCASE theo OAS/BE)', () {
    test('parse đủ field nested', () {
      final raw = <String, dynamic>{
        'id': 'log-1',
        'householdId': 'h1',
        'memberId': 'u1',
        'loggedBy': 'u2',
        'sessionId': 'sess-9',
        'description': '[Bữa trưa] Phở',
        'caloriesKcal': 480,
        'nutrition': <String, dynamic>{
          'proteinG': 28,
          'carbsG': 55,
          'fatG': 14,
          'fiberG': 6,
        },
        'foodItemsDetected': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Bánh phở',
            'estimatedQuantity': '200g',
            'estimatedCaloriesKcal': 220,
          },
        ],
        'requiresConfirmation': true,
        'confirmedByUser': false,
        'loggedAt': '2026-09-16T07:00:00Z',
        'confirmedAt': null,
      };

      final e = MealLogMapper.fromJson(raw, status: MealEntryStatus.saved);

      expect(e.id, 'log-1');
      expect(e.householdId, 'h1');
      expect(e.memberId, 'u1');
      expect(e.loggedBy, 'u2');
      expect(e.sessionId, 'sess-9');
      expect(e.caloriesKcal, closeTo(480, 0.001));
      expect(e.nutrition!.proteinG, closeTo(28, 0.001));
      expect(e.nutrition!.carbsG, closeTo(55, 0.001));
      expect(e.nutrition!.fatG, closeTo(14, 0.001));
      expect(e.nutrition!.fiberG, closeTo(6, 0.001));
      expect(e.foodItemsDetected!.single.name, 'Bánh phở');
      expect(e.foodItemsDetected!.single.estimatedCaloriesKcal,
          closeTo(220, 0.001));
      expect(e.requiresConfirmation, isTrue);
      expect(e.confirmedByUser, isFalse);
      expect(e.confirmedAt, isNull);
    });

    test('Guard #11 coerce num: caloriesKcal/nutrition value dạng int', () {
      final e = MealLogMapper.fromJson(<String, dynamic>{
        'id': 'log-2',
        'householdId': 'h1',
        'memberId': 'u1',
        'loggedBy': 'u1',
        'description': '[Bữa sáng] 3 trứng',
        'caloriesKcal': 320,
        'nutrition': <String, dynamic>{
          'proteinG': 20,
          'carbsG': 8,
          'fatG': 22,
          'fiberG': 0,
        },
        'foodItemsDetected': null,
        'requiresConfirmation': false,
        'confirmedByUser': false,
        'loggedAt': '2026-09-16T07:00:00Z',
        'confirmedAt': null,
      }, status: MealEntryStatus.saved);

      expect(e.caloriesKcal, closeTo(320, 0.001));
      expect(e.nutrition!.proteinG, closeTo(20, 0.001));
      expect(e.foodItemsDetected, isNull);
    });
  });
}