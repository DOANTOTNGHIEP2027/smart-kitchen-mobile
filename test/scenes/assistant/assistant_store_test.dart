import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/domain/assistant_models.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/stores/assistant_store.dart';

import 'fake_assistant_api.dart';

/// AssistantStore ngữ cảnh COOKING (#204): 202 → SSE/poll, retry cùng
/// clientTurnId, tắt khi ngữ cảnh hỏng.
void main() {
  late FakeAssistantApi api;
  late AssistantStore store;
  String? cookingSessionId;
  int? step;
  var online = true;
  var turnSeq = 0;

  AssistantStore build() => AssistantStore(
        api: api,
        contextType: AssistantContextType.cooking,
        contextKey: () => cookingSessionId,
        currentStep: () => step,
        isOnline: () => online,
        clientTurnIdGenerator: () => 'ct-${++turnSeq}',
        pollInterval: const Duration(milliseconds: 1),
        streamSilence: const Duration(milliseconds: 200),
        inFlightRetryDelay: const Duration(milliseconds: 1),
      );

  setUp(() {
    api = FakeAssistantApi();
    cookingSessionId = 'cook-1';
    step = 2;
    online = true;
    turnSeq = 0;
    store = build();
  });
  tearDown(() => store.dispose());

  test('câu đầu tạo phiên COOKING với đúng buổi nấu, gửi kèm currentStep', () async {
    api.onStatus = (turnId) async => answered(turnId);

    await store.send('  Hết nước mắm?  ');

    expect(api.createdFor, <String>['cook-1']);
    final call = api.sends.single;
    expect(call.sessionId, 'as-1');
    expect(call.text, 'Hết nước mắm?');
    expect(call.clientTurnId, 'ct-1');
    expect(call.currentStep, 2);
    expect(store.messages.map((m) => m.role),
        <AssistRole>[AssistRole.user, AssistRole.assistant]);
    expect(store.state, AssistRequestState.idle);

    await store.send('Câu hai');
    // Phiên tạo một lần cho cả buổi nấu.
    expect(api.createdFor, hasLength(1));
  });

  test('SSE: progress cập nhật progressTool, finished cho câu trả lời — không poll',
      () async {
    final events = StreamController<AssistantTurnEvent>();
    api.onEvents = (_) => events.stream;

    final sending = store.send('Hỏi');
    await pumpEventQueue();
    expect(store.isSending, isTrue);
    events.add(const TurnProgress('assess_allergen_risk'));
    await pumpEventQueue();
    expect(store.progressTool, 'assess_allergen_risk');
    events.add(TurnFinished(answered('t-1',
        reply: assistantReply(turnId: 't-1', answer: 'Dùng muối'))));
    await sending;
    await events.close();

    expect(store.messages.last.text, 'Dùng muối');
    expect(store.progressTool, isNull);
    expect(api.statusCalls, 0);
  });

  test('stream lỗi ⇒ poll tới khi hết PENDING', () async {
    var polls = 0;
    api.onStatus = (turnId) async =>
        ++polls < 3 ? pending(turnId) : answered(turnId);

    await store.send('Hỏi');

    expect(api.streamCalls, 1);
    expect(polls, 3);
    expect(store.messages.last.role, AssistRole.assistant);
  });

  test('stream im lặng quá streamSilence ⇒ poll', () async {
    final silent = StreamController<AssistantTurnEvent>();
    api.onEvents = (_) => silent.stream;
    api.onStatus = (turnId) async => answered(turnId);

    await store.send('Hỏi');
    await silent.close();

    expect(api.statusCalls, 1);
    expect(store.state, AssistRequestState.idle);
  });

  test('clientTurnId đã trả lời ⇒ POST trả ANSWERED, không chờ stream', () async {
    api.onSend = (call) async => answered('t-9');

    await store.send('Hỏi');

    expect(api.streamCalls, 0);
    expect(store.messages.last.reply!.turnId, 't-9');
  });

  test('lượt FAILED (AI lỗi) ⇒ busy; Thử lại dùng CÙNG clientTurnId và bước cũ',
      () async {
    var firstPoll = true;
    api.onStatus = (turnId) async {
      if (firstPoll) {
        firstPoll = false;
        return failed(turnId, 'ERR_AI_TIMEOUT');
      }
      return answered(turnId);
    };

    await store.send('Hỏi');
    expect(store.state, AssistRequestState.error);
    expect(store.errorKind, AssistErrorKind.busy);
    expect(store.errorCode, 'ERR_AI_TIMEOUT');
    expect(store.canRetry, isTrue);

    step = 3; // người dùng đã sang bước khác
    await store.retry();

    expect(api.sends, hasLength(2));
    expect(api.sends[1].clientTurnId, api.sends[0].clientTurnId);
    expect(api.sends[1].currentStep, 2);
    // Không thêm tin USER trùng.
    expect(store.messages.where((m) => m.role == AssistRole.user), hasLength(1));
    expect(store.messages.last.role, AssistRole.assistant);
  });

  test('ERR_AI_CONTENT_FILTERED ⇒ filtered, không có Thử lại', () async {
    api.onStatus = (turnId) async => failed(turnId, 'ERR_AI_CONTENT_FILTERED');

    await store.send('Hỏi');

    expect(store.errorKind, AssistErrorKind.filtered);
    expect(store.canRetry, isFalse);
  });

  test('ERR_ASSISTANT_CONTEXT_INVALID khi gửi ⇒ tắt trợ lý cho buổi nấu này', () async {
    api.onSend = (_) async => throw BusinessException(
        'ERR_ASSISTANT_CONTEXT_INVALID', 'Buổi nấu đã kết thúc');

    await store.send('Hỏi');

    expect(store.errorKind, AssistErrorKind.unavailable);
    expect(store.isDisabled, isTrue);
    expect(store.canSend('Hỏi tiếp'), isFalse);

    // Buổi nấu mới ⇒ không bị chặn bởi trạng thái cũ, phiên mới.
    cookingSessionId = 'cook-2';
    expect(store.isDisabled, isFalse);
    api.onSend = null;
    api.onStatus = (turnId) async => answered(turnId);
    await store.send('Hỏi');
    expect(api.createdFor, <String>['cook-1', 'cook-2']);
  });

  test('ERR_ASSISTANT_TURN_IN_FLIGHT ⇒ đợi rồi gửi lại cùng clientTurnId, không báo lỗi',
      () async {
    var n = 0;
    api.onSend = (call) async {
      if (++n == 1) {
        throw BusinessException('ERR_ASSISTANT_TURN_IN_FLIGHT', 'đang chạy');
      }
      return answered('t-1');
    };

    await store.send('Hỏi');

    expect(api.sends, hasLength(2));
    expect(api.sends[1].clientTurnId, api.sends[0].clientTurnId);
    expect(store.state, AssistRequestState.idle);
  });

  test('mất mạng / chưa có bước ⇒ không gửi được', () {
    online = false;
    expect(store.canSend('Hỏi'), isFalse);
    online = true;
    step = null;
    expect(store.canSend('Hỏi'), isFalse);
    step = 1;
    expect(store.canSend(''), isFalse);
    expect(store.canSend('a' * (AssistantStore.maxMessageLength + 1)), isFalse);
    expect(store.canSend('Hỏi'), isTrue);
  });

  test('đổi buổi nấu giữa lúc chờ ⇒ bỏ kết quả cũ', () async {
    final reply = Completer<AssistantTurnStatus>();
    api.onSend = (_) => reply.future;

    final sending = store.send('Hỏi');
    await pumpEventQueue();
    cookingSessionId = 'cook-2';
    reply.complete(answered('t-1'));
    await sending;

    expect(store.messages.where((m) => m.role == AssistRole.assistant), isEmpty);
  });
}
