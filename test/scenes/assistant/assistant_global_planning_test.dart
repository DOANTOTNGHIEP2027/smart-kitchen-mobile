import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/data/assistant_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/domain/assistant_models.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/stores/assistant_store.dart';

import 'fake_assistant_api.dart';

/// KA-FE-1/2 (#204): store GLOBAL mở lại phiên gần nhất, PLANNING gửi đủ ngữ
/// cảnh, rate limit khoá ô nhập; mapper thẻ món / thực đơn / lịch sử.
void main() {
  late FakeAssistantApi api;

  AssistantStore global({Duration cooldown = const Duration(minutes: 1)}) =>
      AssistantStore(
        api: api,
        contextType: AssistantContextType.global,
        contextKey: () => 'global',
        isOnline: () => true,
        clientTurnIdGenerator: () => 'ct',
        rateLimitCooldown: cooldown,
      );

  setUp(() => api = FakeAssistantApi());

  group('GLOBAL', () {
    test('phiên GLOBAL cập nhật < 2 giờ ⇒ dùng lại + nạp lịch sử, không tạo mới',
        () async {
      api.sessions = <AssistantSessionSummary>[
        AssistantSessionSummary(
            id: 'p-1', contextType: 'PLANNING', updatedAt: DateTime.now()),
        AssistantSessionSummary(
            id: 'g-1',
            contextType: 'GLOBAL',
            updatedAt: DateTime.now().subtract(const Duration(minutes: 30))),
      ];
      api.history['g-1'] = <AssistMessage>[
        AssistMessage(role: AssistRole.user, text: 'Hôm qua hỏi'),
        AssistMessage(role: AssistRole.assistant, text: 'Đã trả lời'),
      ];
      final store = global();
      api.onSend = (call) async => answered('t-1');

      await store.open();
      await store.send('Hỏi tiếp');

      expect(store.messages.first.text, 'Hôm qua hỏi');
      expect(api.createdFor, isEmpty);
      expect(api.sends.single.sessionId, 'g-1');
      store.dispose();
    });

    test('phiên GLOBAL cũ hơn 2 giờ ⇒ không dùng lại, câu đầu tạo phiên mới',
        () async {
      api.sessions = <AssistantSessionSummary>[
        AssistantSessionSummary(
            id: 'g-old',
            contextType: 'GLOBAL',
            updatedAt: DateTime.now().subtract(const Duration(hours: 3))),
      ];
      final store = global();
      api.onSend = (call) async => answered('t-1');

      await store.open();
      expect(store.messages, isEmpty);
      await store.send('Tối nay nấu gì?');

      expect(api.createdFor, <String>['GLOBAL']);
      expect(api.sends.single.sessionId, 'as-1');
      store.dispose();
    });

    test('open() hai lần chỉ hỏi danh sách phiên một lần', () async {
      final store = global();
      await store.open();
      await store.open();
      expect(api.listSessionsCalls, 1);
      store.dispose();
    });

    test('ERR_ASSISTANT_RATE_LIMIT ⇒ rateLimited, khoá ô nhập rồi tự mở lại',
        () async {
      final store = global(cooldown: const Duration(milliseconds: 20));
      api.onSend = (_) async =>
          throw BusinessException('ERR_ASSISTANT_RATE_LIMIT', 'quá nhanh');

      await store.send('Hỏi');

      expect(store.errorKind, AssistErrorKind.rateLimited);
      expect(store.canSend('Hỏi nữa'), isFalse);
      expect(store.canRetry, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(store.canSend('Hỏi nữa'), isTrue);
      store.dispose();
    });
  });

  test('PLANNING: tạo phiên kèm mealPlanId/slotId/horizonDays, không mở lại phiên cũ',
      () async {
    final store = AssistantStore(
      api: api,
      contextType: AssistantContextType.planning,
      contextKey: () => 'plan-1|slot-1',
      planning: () => (mealPlanId: 'plan-1', slotId: 'slot-1', horizonDays: 2),
      isOnline: () => true,
    );
    api.onSend = (call) async => answered('t-1');

    await store.open();
    await store.send('Gợi ý món cho bữa này');

    expect(api.listSessionsCalls, 0);
    expect(api.lastPlanning,
        (mealPlanId: 'plan-1', slotId: 'slot-1', horizonDays: 2));
    store.dispose();
  });

  group('mapper', () {
    test('recipeCards + mealPlan', () {
      final reply = mapAssistantReply(<String, dynamic>{
        'turnId': 't',
        'answer': 'Gợi ý',
        'agent': 'meal',
        'recipeCards': <Object>[
          <String, dynamic>{
            'kbRecipeId': 'kb-1',
            'name': 'Canh chua',
            'reason': 'Dùng cà chua',
            'missingIngredients': <Object>['me'],
            'allergenTags': <Object>['fish'],
          },
        ],
        'mealPlan': <Object>[
          <String, dynamic>{
            'day': 2,
            'mealType': 'DINNER',
            'dishes': <Object>[
              <String, dynamic>{'kbRecipeId': 'kb-2', 'name': 'Rau xào'},
            ],
          },
        ],
      });

      expect(reply.recipeCards.single.kbRecipeId, 'kb-1');
      expect(reply.recipeCards.single.missingIngredients, <String>['me']);
      expect(reply.mealPlan.single.day, 2);
      expect(reply.mealPlan.single.dishes.single.name, 'Rau xào');
    });

    test('lịch sử: message AI mang turn, message USER không', () {
      final ai = mapHistoryMessage(<String, dynamic>{
        'role': 'AI',
        'text': 'Trả lời',
        'turn': <String, dynamic>{'turnId': 't', 'answer': 'Trả lời'},
      });
      final user = mapHistoryMessage(
          <String, dynamic>{'role': 'USER', 'text': 'Hỏi', 'turn': null});

      expect(ai.role, AssistRole.assistant);
      expect(ai.reply!.turnId, 't');
      expect(user.role, AssistRole.user);
      expect(user.reply, isNull);
    });

    test('tóm tắt phiên', () {
      final s = mapSessionSummary(<String, dynamic>{
        'id': 's',
        'contextType': 'GLOBAL',
        'updatedAt': '2026-11-27T10:00:00Z',
      });
      expect(s.updatedAt.isUtc, isTrue);
      expect(s.contextType, 'GLOBAL');
    });
  });
}
