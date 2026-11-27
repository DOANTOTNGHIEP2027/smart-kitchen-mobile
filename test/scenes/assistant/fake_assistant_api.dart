import 'package:smart_kitchen_mobile/scenes/assistant/data/assistant_api.dart';
import 'package:smart_kitchen_mobile/scenes/assistant/domain/assistant_models.dart';

/// Một lần gửi lượt đã ghi lại — test đối chiếu payload gửi lên.
class SendCall {
  SendCall(this.sessionId, this.text, this.clientTurnId, this.currentStep);

  final String sessionId;
  final String text;
  final String clientTurnId;
  final int? currentStep;
}

/// Stub programmable cho [AssistantApi] — bám pattern FakeCookingApi.
class FakeAssistantApi implements AssistantApi {
  final List<String> createdFor = <String>[];
  final List<SendCall> sends = <SendCall>[];
  int statusCalls = 0;
  int streamCalls = 0;

  Future<String> Function(AssistantContextType type, String? cookingSessionId)?
      onCreate;
  Future<AssistantTurnStatus> Function(SendCall call)? onSend;
  Future<AssistantTurnStatus> Function(String turnId)? onStatus;

  /// Mặc định stream lỗi ngay ⇒ store chuyển sang poll.
  Stream<AssistantTurnEvent> Function(String turnId)? onEvents;

  @override
  Future<String> createSession(
    AssistantContextType type, {
    String? cookingSessionId,
    String? mealPlanId,
    String? slotId,
  }) async {
    createdFor.add(cookingSessionId ?? type.wire);
    if (onCreate != null) return onCreate!(type, cookingSessionId);
    return 'as-${createdFor.length}';
  }

  @override
  Future<AssistantTurnStatus> sendMessage(
    String sessionId, {
    required String text,
    required String clientTurnId,
    int? currentStep,
  }) async {
    final call = SendCall(sessionId, text, clientTurnId, currentStep);
    sends.add(call);
    if (onSend != null) return onSend!(call);
    return pending('t-${sends.length}');
  }

  @override
  Future<AssistantTurnStatus> turnStatus(String sessionId, String turnId) {
    statusCalls++;
    if (onStatus != null) return onStatus!(turnId);
    throw UnimplementedError();
  }

  @override
  Stream<AssistantTurnEvent> turnEvents(String sessionId, String turnId) {
    streamCalls++;
    if (onEvents != null) return onEvents!(turnId);
    return Stream<AssistantTurnEvent>.error(StateError('no stream'));
  }
}

AssistantTurnStatus pending(String turnId) =>
    AssistantTurnStatus(turnId: turnId, status: TurnStatus.pending);

AssistantTurnStatus failed(String turnId, String code) => AssistantTurnStatus(
    turnId: turnId, status: TurnStatus.failed, errorCode: code);

AssistantTurnStatus answered(String turnId, {AssistantReply? reply}) =>
    AssistantTurnStatus(
      turnId: turnId,
      status: TurnStatus.answered,
      reply: reply ?? assistantReply(turnId: turnId),
    );

AssistantReply assistantReply({
  String turnId = 't-1',
  String answer = 'OK',
  String? allergenNote,
  CookingAnswer? cooking,
  List<SuspectedDish> suspected = const <SuspectedDish>[],
  AssistantQuestion? question,
  bool fallback = false,
}) =>
    AssistantReply(
      turnId: turnId,
      answer: answer,
      agent: 'cooking',
      allergenNote: allergenNote,
      cooking: cooking,
      suspectedDishes: suspected,
      question: question,
      needsInput: question != null,
      fallback: fallback,
    );
