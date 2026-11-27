import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/domain/assistant_models.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/scenes/assistant_routes.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/scenes/assistant_scene.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/stores/assistant_store.dart';

import '../../helpers/pump_app.dart';
import 'fake_assistant_api.dart';

/// Màn trợ lý toàn màn (#204 KA-FE-1/2): S1 lời chào + chip, S2 chip ngữ cảnh,
/// S4 thẻ món + thực đơn nhiều ngày, S10 hỏi quá nhanh.
void main() {
  late FakeAssistantApi api;

  setUp(() => api = FakeAssistantApi());
  tearDown(Get.reset);

  AssistantStore store(AssistantContextType type) => AssistantStore(
        api: api,
        contextType: type,
        contextKey: () => 'k',
        planning: () => (mealPlanId: 'p', slotId: 's', horizonDays: 2),
        isOnline: () => true,
      );

  Future<void> pump(WidgetTester tester, AssistantEntry entry,
      AssistantStore s) async {
    await tester.pumpAppWidget(AssistantScene(entry: entry, store: s),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
  }

  testWidgets('GLOBAL: lời chào + 4 chip; chạm chip gửi đúng câu, hiện thẻ món',
      (tester) async {
    final s = store(AssistantContextType.global);
    api.onSend = (call) async => answered('t-1',
        reply: assistantReply(
          turnId: 't-1',
          answer: 'Gợi ý cho bạn',
          recipeCards: const <RecipeCard>[
            RecipeCard(
                kbRecipeId: 'kb-1',
                name: 'Canh chua cá lóc',
                reason: 'Dùng cà chua sắp hết hạn',
                missingIngredients: <String>['me chua']),
          ],
        ));
    await pump(tester, const AssistantEntry.global(), s);

    expect(find.text('Trợ lý bếp'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(4));
    await tester.tap(find.text('Tối nay nấu gì?'));
    await tester.pumpAndSettle();

    expect(api.sends.single.text, 'Tối nay nấu gì?');
    expect(find.text('Canh chua cá lóc'), findsOneWidget);
    expect(find.text('Còn thiếu: me chua'), findsOneWidget);
    s.dispose();
  });

  testWidgets('PLANNING: chip ngữ cảnh có số ngày; thực đơn nhiều ngày hiện theo ngày',
      (tester) async {
    final s = store(AssistantContextType.planning);
    api.onSend = (call) async => answered('t-1',
        reply: assistantReply(
          turnId: 't-1',
          answer: 'Thực đơn 2 ngày',
          mealPlan: const <PlanSlot>[
            PlanSlot(day: 1, mealType: 'DINNER', dishes: <RecipeCard>[
              RecipeCard(kbRecipeId: 'kb-1', name: 'Canh chua'),
            ]),
            PlanSlot(day: 2, mealType: 'DINNER', dishes: <RecipeCard>[
              RecipeCard(kbRecipeId: 'kb-2', name: 'Rau xào'),
            ]),
          ],
        ));
    await pump(
        tester,
        const AssistantEntry.planning(
            mealPlanId: 'p',
            slotId: 's',
            slotLabel: '27/11 · Bữa tối',
            horizonDays: 2),
        s);

    expect(find.text('27/11 · Bữa tối · 2 ngày'), findsOneWidget);
    await tester.tap(find.text('Gợi ý món cho bữa này'));
    await tester.pumpAndSettle();

    expect(find.text('Ngày 1 · DINNER: Canh chua'), findsOneWidget);
    expect(find.text('Ngày 2 · DINNER: Rau xào'), findsOneWidget);
    expect(api.lastPlanning!.horizonDays, 2);
    s.dispose();
  });

  testWidgets('S10: ERR_ASSISTANT_RATE_LIMIT ⇒ thông báo, nút gửi khoá',
      (tester) async {
    final s = store(AssistantContextType.global);
    api.onSend = (_) async =>
        throw BusinessException('ERR_ASSISTANT_RATE_LIMIT', 'x');
    await pump(tester, const AssistantEntry.global(), s);

    await tester.tap(find.text('Tối nay nấu gì?'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn hỏi hơi nhanh, thử lại sau ít phút nhé.'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hỏi nữa');
    await tester.pump();
    final send =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(send.onPressed, isNull);
    s.dispose();
  });
}
