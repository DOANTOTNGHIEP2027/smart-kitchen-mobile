import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/data/assistant_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/domain/assistant_models.dart';

/// `AssistantTurnStatusResponse` của BE (`kitchen-assistant.md` v2 §2).
void main() {
  test('ANSWERED cooking: thay thế, bước, dị ứng, món tạm loại', () {
    final status = mapTurnStatus(<String, dynamic>{
      'turnId': 't1',
      'status': 'ANSWERED',
      'errorCode': null,
      'result': <String, dynamic>{
        'turnId': 't1',
        'answer': 'Thay bằng muối',
        'agent': 'cooking',
        'allergenNote': 'Đã loại món có cá.',
        'cooking': <String, dynamic>{
          'substitutes': <Object>[
            <String, dynamic>{
              'original': 'nước mắm',
              'substitute': 'muối',
              'ratio': '15 ml ≈ 5 g',
              'inStock': true,
              'contextNote': null,
              'source': 'SOMETHING_NEW',
              'allergenChecked': true,
            },
          ],
          'blockedSubstitutes': <Object>[
            <String, dynamic>{'substitute': 'mắm tôm', 'reason': 'dị ứng'},
          ],
          'scaledIngredients': <Object>[
            <String, dynamic>{'name': 'gạo', 'originalQuantity': 1, 'scaledQuantity': 2.5},
          ],
          'stepRef': 4,
        },
        'suspectedDishes': <Object>[
          <String, dynamic>{
            'name': 'Gỏi cuốn',
            'allergen': 'Peanuts',
            'ingredient': 'tương',
            'reason': 'nghi có đậu phộng',
          },
        ],
        'question': null,
        'needsInput': false,
        'fallback': true,
      },
    });

    expect(status.status, TurnStatus.answered);
    final reply = status.reply!;
    expect(reply.answer, 'Thay bằng muối');
    expect(reply.allergenNote, 'Đã loại món có cá.');
    expect(reply.fallback, isTrue);
    expect(reply.cooking!.stepRef, 4);
    // Nguồn lạ coi như LLM ⇒ luôn hiện nhãn chưa kiểm chứng.
    expect(reply.cooking!.substitutes.single.isAllergenUnverified, isTrue);
    expect(reply.cooking!.blockedSubstitutes.single.substitute, 'mắm tôm');
    expect(reply.cooking!.scaledIngredients.single.scaledQuantity, 2.5);
    expect(reply.cooking!.isStepAnswer, isFalse);
    expect(reply.suspectedDishes.single.allergen, 'Peanuts');
  });

  test('NEEDS_INPUT: question + options', () {
    final reply = mapAssistantReply(<String, dynamic>{
      'turnId': 't2',
      'answer': 'Bạn hỏi giúp mình nhé',
      'agent': 'meal',
      'question': <String, dynamic>{
        'text': 'Dị ứng hay không thích?',
        'options': <Object>['Dị ứng', 'Không thích'],
      },
      'needsInput': true,
    });

    expect(reply.needsInput, isTrue);
    expect(reply.question!.options, <String>['Dị ứng', 'Không thích']);
    expect(reply.cooking, isNull);
    expect(reply.suspectedDishes, isEmpty);
  });

  test('PENDING / FAILED và sự kiện turn.failed', () {
    expect(
      mapTurnStatus(<String, dynamic>{'turnId': 't3', 'status': 'PENDING'})
          .status,
      TurnStatus.pending,
    );
    final failed = mapFailedEvent(
        <String, dynamic>{'turnId': 't4', 'errorCode': 'ERR_AI_TIMEOUT'});
    expect(failed.status, TurnStatus.failed);
    expect(failed.errorCode, 'ERR_AI_TIMEOUT');
    expect(failed.reply, isNull);
  });
}
