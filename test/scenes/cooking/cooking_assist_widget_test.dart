import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/domain/assistant_models.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/stores/assistant_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/ingredient_deduction.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_session_scene.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';

import '../../helpers/pump_app.dart';
import 'cooking_session_store_test.dart' show MemoryProgressStore;
import '../assistant/fake_assistant_api.dart';
import 'fake_cooking_api.dart';

/// Widget test FAB + sheet trợ lý màn nấu, nguồn [AssistantStore] COOKING
/// (#204, thay #157).
void main() {
  late FakeCookingApi cookingApi;
  late FakeAssistantApi assistApi;
  late CookingSessionStore cooking;
  late AssistantStore assist;
  var online = true;

  CookingSession session({
    CookingSessionStatusWire status = CookingSessionStatusWire.inProgress,
  }) =>
      CookingSession(
        id: 's1',
        householdId: 'h1',
        recipeId: 'r1',
        recipeName: 'Canh chua',
        startedBy: 'u1',
        status: status,
        totalSteps: 3,
        startedAt: DateTime.parse('2026-11-17T07:00:00Z'),
        stepsSnapshot: const <CookingSessionStep>[
          CookingSessionStep(stepNumber: 1, instruction: 'Sơ chế cá'),
          CookingSessionStep(stepNumber: 2, instruction: 'Nấu nước dùng'),
          CookingSessionStep(stepNumber: 4, instruction: 'Nêm nếm'),
        ],
      );

  setUp(() {
    for (final api in <String>['toggle', 'isEnabled']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$api',
        (_) async => const StandardMessageCodec()
            .encodeMessage(<Object?>[api == 'isEnabled' ? false : null]),
      );
    }
    online = true;
    cookingApi = FakeCookingApi()..onStart = (_) async => session();
    assistApi = FakeAssistantApi();
    cooking = CookingSessionStore(
      cookingApi: cookingApi,
      recipeApi: FakeRecipeApi(),
      progressStore: CookingProgressCoordinator(MemoryProgressStore()),
      userId: 'u1',
      entryMode: CookingEntryMode.start,
      recipeId: 'r1',
    );
    assist = AssistantStore(
      api: assistApi,
      contextType: AssistantContextType.cooking,
      contextKey: () => cooking.session?.id,
      currentStep: () => cooking.viewedStepDef?.stepNumber,
      isOnline: () => online,
    );
    Get.put<CookingSessionStore>(cooking);
    Get.put<AssistantStore>(assist);
  });
  tearDown(Get.reset);

  Future<void> pumpActive(WidgetTester tester) async {
    await tester.pumpAppWidget(const CookingSessionScene(),
        wrapInScaffold: false);
    await tester.pump();
    await tester.pump();
    expect(cooking.phase, CookingScreenPhase.active);
  }

  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> ask(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
  }

  testWidgets('FAB chỉ có ở phase active', (tester) async {
    await pumpActive(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    cookingApi.onComplete = (_) async => CookingSessionResult(
          session: session(status: CookingSessionStatusWire.completed),
          deductions: const <IngredientDeduction>[],
        );
    await cooking.complete();
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    await unmount(tester);
  });

  /// Lượt trả lời ngay (clientTurnId đã ANSWERED) — không cần timer poll.
  void replyWith(AssistantReply reply) =>
      assistApi.onSend = (call) async => answered(reply.turnId, reply: reply);

  testWidgets('gợi ý LLM → nhãn chưa kiểm chứng + câu dị ứng + nhãn rút gọn',
      (tester) async {
    replyWith(assistantReply(
      answer: 'Thay bằng me chua',
      fallback: true,
      allergenNote: 'Đã loại gợi ý có cá.',
      suspected: const <SuspectedDish>[
        SuspectedDish(
            name: 'Canh me Thái',
            allergen: 'Fish',
            ingredient: 'nước mắm',
            reason: 'nghi có cá'),
      ],
      cooking: const CookingAnswer(
        substitutes: <SubstituteOption>[
          SubstituteOption(
            original: 'me',
            substitute: 'Me chua',
            ratio: '50 g',
            inStock: true,
            source: AssistSource.llm,
            allergenChecked: false,
          ),
        ],
        blockedSubstitutes: <BlockedSubstitute>[
          BlockedSubstitute(substitute: 'me Thái', reason: 'sulphite'),
        ],
        scaledIngredients: <ScaledIngredient>[],
      ),
    ));
    await pumpActive(tester);
    await openSheet(tester);
    expect(find.text('Mình có thể giúp gì cho bước này?'), findsOneWidget);

    await ask(tester, 'Hết me thì sao?');

    expect(find.text('Thay bằng me chua'), findsOneWidget);
    expect(find.text('Gợi ý chưa kiểm chứng dị ứng'), findsOneWidget);
    expect(find.text('Có trong kho'), findsOneWidget);
    expect(find.text('⚠ Đã loại gợi ý có cá.'), findsOneWidget);
    expect(
        find.text('Đã tạm loại Canh me Thái vì nghi có Fish'), findsOneWidget);
    expect(find.text('Không gợi ý vì dị ứng'), findsOneWidget);
    expect(find.text('Trả lời rút gọn — trợ lý đang hạn chế'), findsOneWidget);
    expect(find.text('Hãy tự kiểm tra độ chín và an toàn thực phẩm.'),
        findsNothing);
    expect(assistApi.createdFor, <String>['s1']);
    expect(assistApi.sends.single.currentStep, 1);
    await unmount(tester);
  });

  testWidgets('câu hỏi bước → lưu ý an toàn; chip stepRef=4 nhảy tới vị trí 3',
      (tester) async {
    replyWith(assistantReply(
      answer: 'Nêm vừa',
      cooking: const CookingAnswer(
        substitutes: <SubstituteOption>[],
        blockedSubstitutes: <BlockedSubstitute>[],
        scaledIngredients: <ScaledIngredient>[],
        stepRef: 4,
      ),
    ));
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Nêm thế nào?');

    expect(find.text('Hãy tự kiểm tra độ chín và an toàn thực phẩm.'),
        findsOneWidget);
    await tester.tap(find.text('Bước 4'));
    await tester.pumpAndSettle();

    expect(cooking.viewedStep, 3);
    expect(cooking.currentStep, 1);
    await unmount(tester);
  });

  testWidgets('NEEDS_INPUT → nút trả lời nhanh gửi đúng chữ của lựa chọn',
      (tester) async {
    replyWith(assistantReply(
      turnId: 't-q',
      answer: 'Mình cần hỏi thêm',
      question: const AssistantQuestion(
          text: 'Dị ứng hay không thích?',
          options: <String>['Dị ứng', 'Không thích']),
    ));
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Không ăn được tôm');
    expect(find.text('Dị ứng hay không thích?'), findsOneWidget);

    replyWith(assistantReply(turnId: 't-a', answer: 'Đã ghi nhận'));
    await tester.tap(find.text('Dị ứng'));
    await tester.pumpAndSettle();

    expect(assistApi.sends.last.text, 'Dị ứng');
    expect(find.text('Đã ghi nhận'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('đang chờ → nhãn tiến trình theo tool, sau 5 s thêm dòng chậm',
      (tester) async {
    final events = StreamController<AssistantTurnEvent>();
    assistApi.onEvents = (_) => events.stream;
    await pumpActive(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'Hỏi');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(find.text('đang trả lời…'), findsOneWidget);

    events.add(const TurnProgress('assess_allergen_risk'));
    await tester.pump();
    expect(find.text('đang kiểm dị ứng…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Câu hỏi này cần thêm chút thời gian'), findsOneWidget);
    expect(cooking.phase, CookingScreenPhase.active);

    events.add(TurnFinished(
        answered('t-1', reply: assistantReply(turnId: 't-1', answer: 'Xong'))));
    await tester.pumpAndSettle();
    expect(find.text('Xong'), findsOneWidget);
    // Store đã huỷ subscription; đợi close() trong fake-async sẽ treo test.
    unawaited(events.close());
    await unmount(tester);
  });

  testWidgets('lượt FAILED → banner bận + Thử lại gửi lại cùng clientTurnId',
      (tester) async {
    assistApi.onSend = (call) async => failed('t-1', 'ERR_AI_SERVICE_DOWN');
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Hỏi lại được không?');

    expect(find.text('Trợ lý đang bận, thử lại sau'), findsOneWidget);
    replyWith(assistantReply(turnId: 't-1', answer: 'Được'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Được'), findsOneWidget);
    expect(find.text('Hỏi lại được không?'), findsOneWidget);
    expect(assistApi.sends.map((c) => c.clientTurnId).toSet(), hasLength(1));
    await unmount(tester);
  });

  testWidgets('ERR_AI_CONTENT_FILTERED → thông báo, không có Thử lại',
      (tester) async {
    assistApi.onSend = (call) async => failed('t-1', 'ERR_AI_CONTENT_FILTERED');
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Hỏi');

    expect(find.text('Không trả lời được câu này.'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    await unmount(tester);
  });

  testWidgets('ERR_ASSISTANT_CONTEXT_INVALID → thông báo + FAB ẩn hết phiên',
      (tester) async {
    assistApi.onSend = (_) async =>
        throw BusinessException('ERR_ASSISTANT_CONTEXT_INVALID', 'x');
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Hỏi');

    expect(
        find.text('Trợ lý không dùng được cho buổi nấu này. '
            'Bạn vẫn nấu tiếp bình thường.'),
        findsOneWidget);
    Navigator.of(tester.element(find.byType(TextField))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    await unmount(tester);
  });

  testWidgets('phiên trợ lý mất (404) → tự đóng sheet + ẩn FAB', (tester) async {
    assistApi.onSend = (_) async =>
        throw BusinessException('ERR_ASSISTANT_SESSION_NOT_FOUND', 'x');
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Hỏi');

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await unmount(tester);
  });

  testWidgets('offline → banner offline, nút gửi khoá', (tester) async {
    online = false;
    await pumpActive(tester);
    await openSheet(tester);

    expect(find.text('Bạn đang offline — trợ lý cần mạng'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hỏi');
    await tester.pump();
    final send =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(send.onPressed, isNull);
    expect(assistApi.sends, isEmpty);
    await unmount(tester);
  });

  testWidgets('quá 500 ký tự → nút gửi khoá, chữ KHÔNG bị cắt', (tester) async {
    await pumpActive(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'a' * 501);
    await tester.pump();

    final send =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(send.onPressed, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        hasLength(501));
    await unmount(tester);
  });
}
