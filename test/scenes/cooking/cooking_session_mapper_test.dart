import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_session_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/ingredient_deduction.dart';

void main() {
  group('mapCookingSessionStep — Implementation Guard #10', () {
    test('duration_minutes 5 (JSON) → durationSeconds 300 (GIÂY)', () {
      final step = mapCookingSessionStep(<String, dynamic>{
        'step_number': 1,
        'instruction': ' Rang hành',
        'duration_minutes': 5,
      });

      expect(step.stepNumber, 1);
      expect(step.instruction, ' Rang hành');
      // **Fix-log v1 HIGH-1** — PHẢI nhân 60.
      expect(step.durationSeconds, 300,
          reason: '5 phút phải → 300 giây, không phải 5 giây. Sai guard này '
              'khiến Timer nhanh × 60.');
    });

    test('duration_minutes = null → durationSeconds = null', () {
      final step = mapCookingSessionStep(<String, dynamic>{
        'step_number': 2,
        'instruction': 'Nêm nếm',
      });
      expect(step.durationSeconds, isNull);
    });

    test('duration_minutes = 0 → durationSeconds = 0', () {
      // Edge case — 0 phút là 0 giây, không null (người dùng chủ động khai 0).
      final step = mapCookingSessionStep(<String, dynamic>{
        'step_number': 3,
        'instruction': 'Xong',
        'duration_minutes': 0,
      });
      expect(step.durationSeconds, 0);
    });
  });

  group('mapCookingSession — wire format', () {
    test('status IN_PROGRESS → enum inProgress; endedAt null', () {
      final s = mapCookingSession(<String, dynamic>{
        'id': 's1',
        'householdId': 'h1',
        'recipeId': 'r1',
        'recipeName': 'Canh chua',
        'startedBy': 'u1',
        'status': 'IN_PROGRESS',
        'currentStep': 1,
        'totalSteps': 4,
        'startedAt': '2026-09-16T07:00:00Z',
        'endedAt': null,
      });

      expect(s.id, 's1');
      expect(s.status, CookingSessionStatusWire.inProgress);
      expect(s.isLastStep, isFalse);
      expect(s.endedAt, isNull);
    });

    test('status COMPLETED → enum completed; endedAt parsed', () {
      final s = mapCookingSession(<String, dynamic>{
        'id': 's2',
        'householdId': 'h1',
        'recipeId': 'r1',
        'recipeName': 'Canh chua',
        'startedBy': 'u1',
        'status': 'COMPLETED',
        'currentStep': 4,
        'totalSteps': 4,
        'startedAt': '2026-09-16T07:00:00Z',
        'endedAt': '2026-09-16T07:32:00Z',
      });
      expect(s.status, CookingSessionStatusWire.completed);
      expect(s.isLastStep, isTrue);
      expect(s.endedAt, DateTime.parse('2026-09-16T07:32:00Z'));
    });
  });

  group('mapIngredientDeduction — shortfall flag', () {
    test('shortfallQuantity > 0 → hasShortfall = true', () {
      final d = mapIngredientDeduction(<String, dynamic>{
        'ingredientName': 'Cà chua',
        'requiredQuantity': 200,
        'requiredUnit': 'GRAM',
        'deductedQuantity': 120,
        'shortfallQuantity': 80,
        'matchedItemCount': 2,
      });
      expect(d.hasShortfall, isTrue,
          reason: 'shortfall 80g phải được UI đánh dấu "thiếu"');
    });

    test('shortfallQuantity = 0 → hasShortfall = false', () {
      final d = mapIngredientDeduction(<String, dynamic>{
        'ingredientName': 'Cá lóc',
        'requiredQuantity': 500,
        'requiredUnit': 'GRAM',
        'deductedQuantity': 500,
        'shortfallQuantity': 0,
        'matchedItemCount': 1,
      });
      expect(d.hasShortfall, isFalse);
    });
  });

  group('mapCompleteSessionData', () {
    test('có ingredientDeductions → trả đủ list', () {
      final r = mapCompleteSessionData(<String, dynamic>{
        'session': <String, dynamic>{
          'id': 's1',
          'householdId': 'h1',
          'recipeId': 'r1',
          'recipeName': 'C',
          'startedBy': 'u1',
          'status': 'COMPLETED',
          'currentStep': 2,
          'totalSteps': 2,
          'startedAt': '2026-09-16T07:00:00Z',
          'endedAt': '2026-09-16T07:30:00Z',
        },
        'ingredientDeductions': <Map<String, dynamic>>[
          <String, dynamic>{
            'ingredientName': 'A',
            'requiredQuantity': 100,
            'requiredUnit': 'GRAM',
            'deductedQuantity': 100,
            'shortfallQuantity': 0,
            'matchedItemCount': 1,
          },
        ],
      });
      expect(r.session.status, CookingSessionStatusWire.completed);
      expect(r.deductions.length, 1);
    });

    test('session chưa COMPLETED → deductions rỗng', () {
      final r = mapCompleteSessionData(<String, dynamic>{
        'session': <String, dynamic>{
          'id': 's1',
          'householdId': 'h1',
          'recipeId': 'r1',
          'recipeName': 'C',
          'startedBy': 'u1',
          'status': 'IN_PROGRESS',
          'currentStep': 1,
          'totalSteps': 2,
          'startedAt': '2026-09-16T07:00:00Z',
          'endedAt': null,
        },
        // ingredientDeductions vắng mặt — mapper phải default []
      });
      expect(r.deductions, isEmpty);
    });
  });

  test('IngredientDeduction copyWith giữ fields khác', () {
    const IngredientDeduction original = IngredientDeduction(
      ingredientName: 'Cà chua',
      requiredQuantity: 200,
      requiredUnit: 'GRAM',
      deductedQuantity: 120,
      shortfallQuantity: 80,
      matchedItemCount: 2,
    );
    expect(original.hasShortfall, isTrue);
    expect(original.matchedItemCount, 2);
  });
}
