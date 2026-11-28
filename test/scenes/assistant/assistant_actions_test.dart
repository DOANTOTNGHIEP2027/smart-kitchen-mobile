import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/data/assistant_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/domain/assistant_models.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/scenes/assistant_routes.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/scenes/assistant_scene.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/stores/assistant_store.dart';

import '../../helpers/pump_app.dart';
import 'fake_assistant_api.dart';

/// Thẻ hành động S6/S7 + mở công thức từ thẻ món (#204, KA-BE-3/4 phía FE).
void main() {
  late FakeAssistantApi api;
  late AssistantStore store;

  AssistantAction action({
    ActionStatus status = ActionStatus.pending,
    DateTime? expiresAt,
  }) =>
      AssistantAction(
        actionId: 'a-1',
        type: 'MEALPLAN_ADD_DISH',
        summary: 'Canh chua cá lóc · 2026-08-12 · DINNER',
        status: status,
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 30)),
      );

  setUp(() {
    api = FakeAssistantApi();
    store = AssistantStore(
      api: api,
      contextType: AssistantContextType.global,
      contextKey: () => 'k',
      isOnline: () => true,
    );
  });
  tearDown(() {
    store.dispose();
    Get.reset();
  });

  test('mapper: actions + kết quả confirm', () {
    final reply = mapAssistantReply(<String, dynamic>{
      'turnId': 't',
      'answer': 'x',
      'actions': <Object>[
        <String, dynamic>{
          'actionId': 'a-1',
          'type': 'MEALPLAN_ADD_DISH',
          'summary': 'Canh chua',
          'status': 'DONE',
          'expiresAt': '2026-11-28T10:00:00Z',
        },
      ],
    });
    final failed = mapActionResult(<String, dynamic>{
      'actionId': 'a-1',
      'status': 'FAILED',
      'result': <String, dynamic>{'code': 'ERR_PLAN_003'},
    });

    expect(reply.actions.single.status, ActionStatus.done);
    expect(failed.status, ActionStatus.failed);
    expect(failed.code, 'ERR_PLAN_003');
  });

  test('store: PENDING quá hạn theo giờ máy ⇒ expired; confirm ⇒ kết quả BE', () async {
    expect(
        store.actionStatus(action(
            expiresAt: DateTime.now().subtract(const Duration(minutes: 1)))),
        ActionStatus.expired);

    api.onConfirm = (_) async =>
        const ActionResult(status: ActionStatus.failed, code: 'ERR_PLAN_003');
    await store.confirmAction('a-1');

    expect(store.actionStatus(action()), ActionStatus.failed);
    expect(store.actionCode('a-1'), 'ERR_PLAN_003');
  });

  test('store: ERR_ASSISTANT_ACTION_EXPIRED ⇒ expired', () async {
    api.onConfirm = (_) async =>
        throw BusinessException('ERR_ASSISTANT_ACTION_EXPIRED', 'x');
    await store.confirmAction('a-1');
    expect(store.actionStatus(action()), ActionStatus.expired);
  });

  test('store: resolveRecipe trả recipeId; lỗi ⇒ null', () async {
    expect(await store.resolveRecipe('kb-1'), 'recipe-kb-1');
    api.onResolveRecipe = (_) async => throw NetworkException();
    expect(await store.resolveRecipe('kb-1'), isNull);
  });

  testWidgets('S6 → S7: bấm "Thêm vào thực đơn" gửi confirm, thẻ chuyển sang đã thêm',
      (tester) async {
    api.onSend = (call) async => answered('t-1',
        reply: assistantReply(
            turnId: 't-1', answer: 'Thêm canh chua nhé', actions: <AssistantAction>[action()]));
    await tester.pumpAppWidget(
        AssistantScene(entry: const AssistantEntry.global(), store: store),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối nay nấu gì?'));
    await tester.pumpAndSettle();

    expect(find.text('Canh chua cá lóc · 2026-08-12 · DINNER'), findsOneWidget);
    await tester.tap(find.text('Thêm vào thực đơn'));
    await tester.pumpAndSettle();

    expect(api.confirmed, <String>['a-1']);
    expect(find.text('Đã thêm vào thực đơn'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsNothing);
  });

  testWidgets('Đề xuất đã hết hạn ⇒ không có nút xác nhận', (tester) async {
    api.onSend = (call) async => answered('t-1',
        reply: assistantReply(turnId: 't-1', answer: 'x', actions: <AssistantAction>[
          action(expiresAt: DateTime.now().subtract(const Duration(minutes: 1))),
        ]));
    await tester.pumpAppWidget(
        AssistantScene(entry: const AssistantEntry.global(), store: store),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối nay nấu gì?'));
    await tester.pumpAndSettle();

    expect(find.text('Đề xuất đã hết hạn'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Thêm vào thực đơn'), findsNothing);
  });
}
