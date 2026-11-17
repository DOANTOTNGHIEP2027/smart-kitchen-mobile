import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_assist.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/ingredient_deduction.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_assist_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';

import 'cooking_session_store_test.dart' show MemoryProgressStore;
import 'fake_cooking_api.dart';

/// FE design §14.8 — store test trợ lý nấu ăn + đọc bước từ snapshot.
void main() {
  late FakeCookingApi cookingApi;
  late FakeRecipeApi recipeApi;
  late FakeCookingAssistApi assistApi;

  setUp(() {
    cookingApi = FakeCookingApi();
    recipeApi = FakeRecipeApi();
    assistApi = FakeCookingAssistApi();
  });

  List<CookingSessionStep> stepsOf(List<int> numbers) => numbers
      .map((n) => CookingSessionStep(stepNumber: n, instruction: 'Bước số $n'))
      .toList(growable: false);

  CookingSession session({
    String id = 's1',
    List<CookingSessionStep>? snapshot,
    int totalSteps = 3,
    CookingSessionStatusWire status = CookingSessionStatusWire.inProgress,
  }) =>
      CookingSession(
        id: id,
        householdId: 'h1',
        recipeId: 'r1',
        recipeName: 'Canh chua',
        startedBy: 'u1',
        status: status,
        totalSteps: snapshot?.length ?? totalSteps,
        startedAt: DateTime.parse('2026-11-17T07:00:00Z'),
        stepsSnapshot: snapshot,
      );

  Future<CookingSessionStore> startCooking(List<int> stepNumbers) async {
    cookingApi.onStart = (_) async => session(snapshot: stepsOf(stepNumbers));
    final store = CookingSessionStore(
      cookingApi: cookingApi,
      recipeApi: recipeApi,
      progressStore: CookingProgressCoordinator(MemoryProgressStore()),
      userId: 'u1',
      entryMode: CookingEntryMode.start,
      recipeId: 'r1',
    );
    await store.init();
    return store;
  }

  CookingAssistStore assistFor(
    CookingSessionStore cooking, {
    bool Function()? isOnline,
    String? Function()? sessionId,
    String? Function()? accountScope,
  }) =>
      CookingAssistStore(
        api: assistApi,
        sessionId: sessionId ?? () => cooking.session?.id,
        viewedStepNumber: () => cooking.viewedStepDef?.stepNumber,
        isOnline: isOnline ?? () => true,
        accountScope: accountScope,
        slowAfter: const Duration(milliseconds: 20),
      );

  group('stepsSnapshot', () {
    test('session có snapshot → dựng steps từ snapshot, KHÔNG gọi GET recipe',
        () async {
      final store = await startCooking(<int>[1, 2, 4]);

      expect(store.phase, CookingScreenPhase.active);
      expect(recipeApi.getStepsCalls, 0);
      expect(store.steps.map((s) => s.stepNumber), <int>[1, 2, 4]);
    });

    test('session cũ (snapshot null) → vẫn đọc recipe live', () async {
      cookingApi.onStart = (_) async => session();
      recipeApi.onGetSteps = (_) async => stepsOf(<int>[1, 2, 3]);
      final store = CookingSessionStore(
        cookingApi: cookingApi,
        recipeApi: recipeApi,
        progressStore: CookingProgressCoordinator(MemoryProgressStore()),
        userId: 'u1',
        entryMode: CookingEntryMode.start,
        recipeId: 'r1',
      );
      await store.init();

      expect(recipeApi.getStepsCalls, 1);
      expect(store.steps.length, 3);
    });
  });

  group('send — 3 intent', () {
    for (final intent in AssistIntent.values) {
      test('thành công $intent → thêm bubble ASSISTANT, state=idle', () async {
        final cooking = await startCooking(<int>[1, 2, 3]);
        final assist = assistFor(cooking);
        assistApi.onAsk = (_) async => assistData(intent: intent, answer: 'A');

        await assist.send('  Hỏi gì đó  ');

        expect(assistApi.calls.single.message, 'Hỏi gì đó');
        expect(assistApi.calls.single.sessionId, 's1');
        expect(assist.messages.map((m) => m.role),
            <AssistRole>[AssistRole.user, AssistRole.assistant]);
        expect(assist.messages.last.data!.intent, intent);
        expect(assist.state, AssistRequestState.idle);
      });
    }

    test('fallback=true được giữ nguyên trên data để UI hiện nhãn rút gọn',
        () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      assistApi.onAsk = (_) async => assistData(fallback: true);

      await assist.send('Hỏi');

      expect(assist.messages.last.data!.fallback, isTrue);
    });

    test('quá 500 ký tự hoặc rỗng → không gửi', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);

      expect(assist.canSend('a' * 501), isFalse);
      expect(assist.canSend('a' * 500), isTrue);
      await assist.send('a' * 501);
      await assist.send('   ');

      expect(assistApi.calls, isEmpty);
    });
  });

  group('lỗi + Thử lại', () {
    for (final error in <ApiException>[
      ServerException('ERR_AI_TIMEOUT', 'timeout'),
      ServerException('ERR_AI_SERVICE_DOWN', 'down'),
      BusinessException('ERR_AI_RATE_LIMIT', 'slow down'),
      NetworkException(),
    ]) {
      test('${error.code} → busy + retry gửi lại đúng text, không nhân đôi tin',
          () async {
        final cooking = await startCooking(<int>[1, 2, 3]);
        final assist = assistFor(cooking);
        assistApi.onAsk = (_) async => throw error;

        await assist.send('Hết me thì sao?');

        expect(assist.state, AssistRequestState.error);
        expect(assist.errorKind, AssistErrorKind.busy);
        expect(assist.canRetry, isTrue);

        assistApi.onAsk = (_) async => assistData(answer: 'Dùng sấu');
        await assist.retry();

        expect(assistApi.calls.length, 2);
        expect(assistApi.calls.last.message, 'Hết me thì sao?');
        // Tin lỗi không lọt vào history của lần thử lại.
        expect(assistApi.calls.last.chatHistory, isEmpty);
        expect(assist.messages.map((m) => m.text),
            <String>['Hết me thì sao?', 'Dùng sấu']);
        expect(assist.state, AssistRequestState.idle);
      });
    }

    test('Thử lại giữ viewedStep lúc gửi + history trước tin lỗi', () async {
      final cooking = await startCooking(<int>[10, 20, 30]);
      final assist = assistFor(cooking);
      assistApi.onAsk = (_) async => assistData(answer: 'đáp 1');
      await assist.send('hỏi 1');
      assistApi.onAsk =
          (_) async => throw ServerException('ERR_AI_TIMEOUT', 'x');
      await assist.send('hỏi 2');

      await cooking.advanceOrComplete(); // đang xem bước 20 khi retry
      assistApi.onAsk = (_) async => assistData(answer: 'đáp 2');
      await assist.retry();

      final call = assistApi.calls.last;
      expect(call.message, 'hỏi 2');
      expect(call.viewedStep, 10);
      expect(call.chatHistory.map((t) => t.text), <String>['hỏi 1', 'đáp 1']);
      expect(assist.messages.map((m) => m.text),
          <String>['hỏi 1', 'đáp 1', 'hỏi 2', 'đáp 2']);
    });

    test('4xx không envelope (ERR_UNKNOWN, vd. 429 gateway) → busy', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      assistApi.onAsk =
          (_) async => throw BusinessException('ERR_UNKNOWN', 'x');

      await assist.send('Hỏi');

      expect(assist.errorKind, AssistErrorKind.busy);
      expect(assist.canRetry, isTrue);
    });

    test('422 filtered → không có Thử lại', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      assistApi.onAsk =
          (_) async => throw BusinessException('ERR_AI_CONTENT_FILTERED', 'x');

      await assist.send('Hỏi');

      expect(assist.errorKind, AssistErrorKind.filtered);
      expect(assist.canRetry, isFalse);
      expect(assist.isDisabled, isFalse);
    });

    test('409 ERR_ASSIST_CONTEXT_UNAVAILABLE → tắt trợ lý cho hết phiên',
        () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      assistApi.onAsk = (_) async =>
          throw BusinessException('ERR_ASSIST_CONTEXT_UNAVAILABLE', 'x');

      await assist.send('Hỏi');

      expect(assist.errorKind, AssistErrorKind.unavailable);
      expect(assist.isDisabled, isTrue);
      expect(assist.canSend('Hỏi tiếp'), isFalse);
    });

    for (final code in <String>[
      'ERR_SESSION_ALREADY_ENDED',
      'ERR_SESSION_NOT_FOUND',
    ]) {
      test('$code → ended, tắt trợ lý; phase màn nấu KHÔNG đổi', () async {
        final cooking = await startCooking(<int>[1, 2, 3]);
        final assist = assistFor(cooking);
        assistApi.onAsk = (_) async => throw BusinessException(code, 'x');

        await assist.send('Hỏi');

        expect(assist.errorKind, AssistErrorKind.ended);
        expect(assist.isDisabled, isTrue);
        expect(cooking.phase, CookingScreenPhase.active);
      });
    }

    test('offline → không gửi', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking, isOnline: () => false);

      expect(assist.isOffline, isTrue);
      expect(assist.canSend('Hỏi'), isFalse);
      await assist.send('Hỏi');

      expect(assistApi.calls, isEmpty);
      expect(assist.messages, isEmpty);
    });
  });

  group('chatHistory', () {
    test(
        'chỉ gồm cặp thành công, tối đa 4 tin gần nhất, không gồm câu đang gửi',
        () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      var n = 0;
      assistApi.onAsk = (call) async {
        n++;
        if (call.message == 'lỗi') throw ServerException('ERR_AI_TIMEOUT', 'x');
        return assistData(answer: 'đáp $n');
      };

      await assist.send('hỏi 1');
      await assist.send('hỏi 2');
      await assist.send('lỗi');
      await assist.send('hỏi 3');
      await assist.send('hỏi 4');

      final history = assistApi.calls.last.chatHistory;
      expect(history.map((t) => '${t.role.wire}:${t.text}'), <String>[
        'USER:hỏi 2',
        'ASSISTANT:đáp 2',
        'USER:hỏi 3',
        'ASSISTANT:đáp 4',
      ]);
      expect(history.any((t) => t.text == 'hỏi 4'), isFalse);
      expect(history.any((t) => t.text == 'lỗi'), isFalse);
    });

    test('mỗi text trong history bị cắt còn 1000 ký tự', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      assistApi.onAsk = (_) async => assistData(answer: 'x' * 1500);

      await assist.send('hỏi 1');
      await assist.send('hỏi 2');

      expect(assistApi.calls.last.chatHistory.last.text.length, 1000);
    });

    test('đổi tài khoản/household → xoá history', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final scope = Observable<String>('u1|h1');
      final assist = assistFor(cooking, accountScope: () => scope.value);
      assistApi.onAsk = (_) async => assistData();

      await assist.send('hỏi 1');
      expect(assist.messages, isNotEmpty);

      runInAction(() => scope.value = 'u1|h2');

      expect(assist.messages, isEmpty);
      assist.dispose();
    });
  });

  group('response muộn', () {
    test('đổi session trong lúc chờ → bỏ response, không lẫn history',
        () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      var sid = 's1';
      final assist = assistFor(cooking, sessionId: () => sid);
      final pending = Completer<CookingAssistData>();
      assistApi.onAsk = (_) => pending.future;

      final sending = assist.send('Hỏi phiên A');
      sid = 's2';
      pending.complete(assistData(answer: 'Đáp phiên A'));
      await sending;

      expect(assist.messages.any((m) => m.text == 'Đáp phiên A'), isFalse);

      assistApi.onAsk = (_) async => assistData(answer: 'Đáp phiên B');
      await assist.send('Hỏi phiên B');

      expect(assistApi.calls.last.sessionId, 's2');
      expect(assistApi.calls.last.chatHistory, isEmpty);
      expect(assist.messages.map((m) => m.text),
          <String>['Hỏi phiên B', 'Đáp phiên B']);
    });

    test('đổi session khi đang chờ → nút gửi không kẹt ở sending', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      var sid = 's1';
      final assist = assistFor(cooking, sessionId: () => sid);
      final pending = Completer<CookingAssistData>();
      assistApi.onAsk = (_) => pending.future;

      unawaited(assist.send('Hỏi phiên A'));
      expect(assist.canSend('Hỏi B'), isFalse);
      sid = 's2';

      expect(assist.isSending, isFalse);
      expect(assist.canSend('Hỏi B'), isTrue);
      pending.complete(assistData());
    });

    test('dispose trong lúc chờ → bỏ response', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      final pending = Completer<CookingAssistData>();
      assistApi.onAsk = (_) => pending.future;

      final sending = assist.send('Hỏi');
      assist.dispose();
      pending.complete(assistData(answer: 'Muộn'));
      await sending;

      expect(assist.messages, isEmpty);
    });

    test('sau 5 s vẫn chờ → isSlow; xong thì tắt', () async {
      final cooking = await startCooking(<int>[1, 2, 3]);
      final assist = assistFor(cooking);
      final pending = Completer<CookingAssistData>();
      assistApi.onAsk = (_) => pending.future;

      final sending = assist.send('Hỏi');
      expect(assist.isSending, isTrue);
      expect(assist.isSlow, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(assist.isSlow, isTrue);
      expect(assist.canSend('Hỏi tiếp'), isFalse);

      pending.complete(assistData());
      await sending;
      expect(assist.isSlow, isFalse);
    });
  });

  group('viewedStep + stepRef', () {
    test('đang lùi xem bước 2 khi tiến độ ở bước 4 → gửi stepNumber của bước 2',
        () async {
      final cooking = await startCooking(<int>[10, 20, 30, 40, 50]);
      await cooking.advanceOrComplete();
      await cooking.advanceOrComplete();
      await cooking.advanceOrComplete();
      cooking.viewPreviousStep();
      cooking.viewPreviousStep();
      expect(cooking.currentStep, 4);
      expect(cooking.viewedStep, 2);

      final assist = assistFor(cooking);
      assistApi.onAsk = (_) async => assistData();
      await assist.send('Bước này làm sao?');

      expect(assistApi.calls.single.viewedStep, 20);
    });

    test('bước không liên tiếp (1,2,4): gửi đúng 4, chip stepRef=4 → vị trí 3',
        () async {
      final cooking = await startCooking(<int>[1, 2, 4]);
      await cooking.advanceOrComplete();
      await cooking.advanceOrComplete();
      expect(cooking.viewedStep, 3);

      final assist = assistFor(cooking);
      assistApi.onAsk = (_) async => assistData(stepRef: 4);
      await assist.send('Hỏi');
      expect(assistApi.calls.single.viewedStep, 4);

      cooking.viewPreviousStep();
      cooking.viewPreviousStep();
      expect(cooking.viewedStep, 1);
      expect(cooking.indexOfStepNumber(4), 2);
      cooking.viewStepNumber(4);
      expect(cooking.viewedStep, 3);
      expect(cooking.isViewingCurrentStep, isTrue);
    });

    test('stepRef không có trong steps → index -1, viewStepNumber không đổi gì',
        () async {
      final cooking = await startCooking(<int>[1, 2, 4]);

      expect(cooking.indexOfStepNumber(3), -1);
      cooking.viewStepNumber(3);
      expect(cooking.viewedStep, 1);
    });

    test('stepNumber trùng → lấy phần tử đầu tiên', () async {
      final cooking = await startCooking(<int>[1, 2, 2]);

      expect(cooking.indexOfStepNumber(2), 1);
    });
  });

  test('complete() thành công trong lúc trợ lý đang sending', () async {
    final cooking = await startCooking(<int>[1, 2, 3]);
    final assist = assistFor(cooking);
    final pending = Completer<CookingAssistData>();
    assistApi.onAsk = (_) => pending.future;
    cookingApi.onComplete = (_) async => CookingSessionResult(
          session: session(
              snapshot: stepsOf(<int>[1, 2, 3]),
              status: CookingSessionStatusWire.completed),
          deductions: const <IngredientDeduction>[],
        );

    final sending = assist.send('Hỏi');
    expect(assist.isSending, isTrue);
    await cooking.complete();

    expect(cooking.phase, CookingScreenPhase.completed);
    pending.complete(assistData());
    await sending;
  });
}
