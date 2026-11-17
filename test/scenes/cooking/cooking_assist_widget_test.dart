import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_assist.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/ingredient_deduction.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_session_scene.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_assist_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';

import '../../helpers/pump_app.dart';
import 'cooking_session_store_test.dart' show MemoryProgressStore;
import 'fake_cooking_api.dart';

/// FE design §14.5/§14.8 — widget test FAB + sheet trợ lý.
void main() {
  late FakeCookingApi cookingApi;
  late FakeCookingAssistApi assistApi;
  late CookingSessionStore cooking;
  late CookingAssistStore assist;
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
    assistApi = FakeCookingAssistApi();
    cooking = CookingSessionStore(
      cookingApi: cookingApi,
      recipeApi: FakeRecipeApi(),
      progressStore: CookingProgressCoordinator(MemoryProgressStore()),
      userId: 'u1',
      entryMode: CookingEntryMode.start,
      recipeId: 'r1',
    );
    assist = CookingAssistStore(
      api: assistApi,
      sessionId: () => cooking.session?.id,
      viewedStepNumber: () => cooking.viewedStepDef?.stepNumber,
      isOnline: () => online,
    );
    Get.put<CookingSessionStore>(cooking);
    Get.put<CookingAssistStore>(assist);
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

  testWidgets(
      'gợi ý LLM → nhãn chưa kiểm chứng + cảnh báo khách + nhãn rút gọn',
      (tester) async {
    assistApi.onAsk = (_) async => assistData(
          intent: AssistIntent.substitute,
          answer: 'Thay bằng me chua',
          fallback: true,
          substitutes: const <SubstituteOption>[
            SubstituteOption(
              original: 'me',
              substitute: 'Me chua',
              ratio: '50 g',
              inStock: true,
              source: AssistSource.llm,
              allergenChecked: false,
            ),
          ],
          blocked: const <BlockedSubstitute>[
            BlockedSubstitute(substitute: 'me Thái', reason: 'sulphite'),
          ],
        );
    await pumpActive(tester);
    await openSheet(tester);
    expect(find.text('Mình có thể giúp gì cho bước này?'), findsOneWidget);

    await ask(tester, 'Hết me thì sao?');

    expect(find.text('Thay bằng me chua'), findsOneWidget);
    expect(find.text('Gợi ý chưa kiểm chứng dị ứng'), findsOneWidget);
    expect(find.text('Có trong kho'), findsOneWidget);
    expect(find.text('⚠ Chưa tính dị ứng của khách ăn cùng'), findsOneWidget);
    expect(find.text('Không gợi ý vì dị ứng'), findsOneWidget);
    expect(find.text('Trả lời rút gọn — trợ lý đang hạn chế'), findsOneWidget);
    expect(find.text('Hãy tự kiểm tra độ chín và an toàn thực phẩm.'),
        findsNothing);
    await unmount(tester);
  });

  testWidgets('STEP_QA → disclaimer; chip stepRef=4 nhảy tới vị trí 3',
      (tester) async {
    assistApi.onAsk = (_) async => assistData(answer: 'Nêm vừa', stepRef: 4);
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

  testWidgets('stepRef không có trong steps → ẩn chip', (tester) async {
    assistApi.onAsk = (_) async => assistData(answer: 'Ừ', stepRef: 3);
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Hỏi');

    expect(find.text('Bước 3'), findsNothing);
    await unmount(tester);
  });

  testWidgets('đang gửi → bubble chờ, sau 5 s thêm dòng chậm; vẫn nấu được',
      (tester) async {
    final pending = Completer<CookingAssistData>();
    assistApi.onAsk = (_) => pending.future;
    await pumpActive(tester);
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'Hỏi');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(find.text('đang trả lời…'), findsOneWidget);
    expect(find.text('Câu hỏi này cần thêm chút thời gian'), findsNothing);

    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Câu hỏi này cần thêm chút thời gian'), findsOneWidget);
    expect(cooking.phase, CookingScreenPhase.active);

    pending.complete(assistData(answer: 'Xong'));
    await tester.pumpAndSettle();
    expect(find.text('Xong'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('503 → banner bận + Thử lại gửi lại đúng câu', (tester) async {
    assistApi.onAsk =
        (_) async => throw ServerException('ERR_AI_SERVICE_DOWN', 'down');
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Hỏi lại được không?');

    expect(find.text('Trợ lý đang bận, thử lại sau'), findsOneWidget);
    assistApi.onAsk = (_) async => assistData(answer: 'Được');
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Được'), findsOneWidget);
    expect(find.text('Hỏi lại được không?'), findsOneWidget);
    expect(assistApi.calls.map((c) => c.message),
        <String>['Hỏi lại được không?', 'Hỏi lại được không?']);
    await unmount(tester);
  });

  testWidgets('422 → "Không trả lời được câu này." và KHÔNG có Thử lại',
      (tester) async {
    assistApi.onAsk =
        (_) async => throw BusinessException('ERR_AI_CONTENT_FILTERED', 'x');
    await pumpActive(tester);
    await openSheet(tester);

    await ask(tester, 'Hỏi');

    expect(find.text('Không trả lời được câu này.'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    await unmount(tester);
  });

  testWidgets('409 context unavailable → thông báo + FAB ẩn hết phiên',
      (tester) async {
    assistApi.onAsk = (_) async =>
        throw BusinessException('ERR_ASSIST_CONTEXT_UNAVAILABLE', 'x');
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

  testWidgets('409 ALREADY_ENDED → tự đóng sheet + ẩn FAB', (tester) async {
    assistApi.onAsk =
        (_) async => throw BusinessException('ERR_SESSION_ALREADY_ENDED', 'x');
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
    expect(assistApi.calls, isEmpty);
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
