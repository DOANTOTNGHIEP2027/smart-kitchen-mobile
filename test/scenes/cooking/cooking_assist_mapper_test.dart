import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_assist_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_session_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_assist.dart';

/// Key camelCase theo OAS — sai key là field lặng lẽ về null (AGENTS.md).
void main() {
  Map<String, dynamic> sessionJson({Object? snapshot}) => <String, dynamic>{
        'id': 's1',
        'householdId': 'h1',
        'recipeId': 'r1',
        'recipeName': 'Canh chua',
        'startedBy': 'u1',
        'status': 'IN_PROGRESS',
        'totalSteps': 2,
        'startedAt': '2026-11-17T07:00:00Z',
        'endedAt': null,
        if (snapshot != null) 'stepsSnapshot': snapshot,
      };

  group('mapCookingSession — stepsSnapshot', () {
    test('camelCase + quy đổi phút → giây', () {
      final s = mapCookingSession(sessionJson(snapshot: <Object>[
        <String, dynamic>{
          'stepNumber': 1,
          'instruction': 'Sơ chế',
          'durationMinutes': 5,
        },
        <String, dynamic>{
          'stepNumber': 4,
          'instruction': 'Nêm',
          'durationMinutes': null,
        },
      ]));

      expect(s.stepsSnapshot!.map((e) => e.stepNumber), <int>[1, 4]);
      expect(s.stepsSnapshot!.first.durationSeconds, 300);
      expect(s.stepsSnapshot!.last.durationSeconds, isNull);
    });

    test('thiếu/null → null (session cũ)', () {
      expect(mapCookingSession(sessionJson()).stepsSnapshot, isNull);
    });
  });

  group('mapCookingAssistData', () {
    test('parse đủ field theo OAS', () {
      final d = mapCookingAssistData(<String, dynamic>{
        'requestId': 'req-1',
        'intent': 'SUBSTITUTE',
        'answer': 'Dùng sấu',
        'stepRef': 2,
        'substitutes': <Object>[
          <String, dynamic>{
            'original': 'me',
            'substitute': 'sấu',
            'ratio': '1:1',
            'inStock': true,
            'contextNote': 'chua dịu',
            'source': 'KB',
            'allergenChecked': true,
          },
          <String, dynamic>{
            'original': 'me',
            'substitute': 'me chua',
            'ratio': '50 g',
            'inStock': false,
            'contextNote': null,
            'source': 'LLM',
            'allergenChecked': false,
          },
        ],
        'blockedSubstitutes': <Object>[
          <String, dynamic>{'substitute': 'me Thái', 'reason': 'sulphite'},
        ],
        'scaledIngredients': <Object>[
          <String, dynamic>{
            'name': 'cá lóc',
            'originalQuantity': 500,
            'scaledQuantity': 750.5,
            'unit': 'g',
            'note': null,
          },
        ],
        'fallback': true,
        'contextSource': 'LIVE_RECIPE',
        'allergenScope': <String, dynamic>{
          'householdMembers': true,
          'dependents': true,
          'guestsUnknown': true,
        },
      });

      expect(d.intent, AssistIntent.substitute);
      expect(d.stepRef, 2);
      expect(d.substitutes.first.source, AssistSource.kb);
      expect(d.substitutes.first.isAllergenUnverified, isFalse);
      expect(d.substitutes.first.inStock, isTrue);
      expect(d.substitutes.last.isAllergenUnverified, isTrue);
      expect(d.blockedSubstitutes.single.reason, 'sulphite');
      expect(d.scaledIngredients.single.originalQuantity, 500.0);
      expect(d.scaledIngredients.single.scaledQuantity, 750.5);
      expect(d.fallback, isTrue);
      expect(d.contextSource, AssistContextSource.liveRecipe);
      expect(d.allergenScope.dependents, isTrue);
      expect(d.showGuestsWarning, isTrue);
    });

    test('STEP_QA tối giản, stepRef vắng → null, không cảnh báo khách', () {
      final d = mapCookingAssistData(<String, dynamic>{
        'requestId': 'req-2',
        'intent': 'STEP_QA',
        'answer': 'Đun lửa nhỏ',
        'substitutes': <Object>[],
        'blockedSubstitutes': <Object>[],
        'scaledIngredients': <Object>[],
        'fallback': false,
        'contextSource': 'SNAPSHOT',
        'allergenScope': <String, dynamic>{
          'householdMembers': true,
          'dependents': false,
          'guestsUnknown': true,
        },
      });

      expect(d.intent, AssistIntent.stepQa);
      expect(d.stepRef, isNull);
      expect(d.showGuestsWarning, isFalse);
    });

    test('KB nhưng allergenChecked=false → vẫn là chưa kiểm chứng', () {
      const option = SubstituteOption(
        original: 'me',
        substitute: 'sấu',
        ratio: '1:1',
        inStock: false,
        source: AssistSource.kb,
        allergenChecked: false,
      );
      expect(option.isAllergenUnverified, isTrue);
    });

    test('ChatTurn.toJson dùng role USER/ASSISTANT', () {
      expect(
        const ChatTurn(role: AssistRole.assistant, text: 'x').toJson(),
        <String, dynamic>{'role': 'ASSISTANT', 'text': 'x'},
      );
    });
  });
}
