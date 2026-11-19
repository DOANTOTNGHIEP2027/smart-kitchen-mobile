import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_assist_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_session_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/recipe_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_assist.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';

/// Stub programmable cho cooking API — bám pattern FakeInventoryApi.
class FakeCookingApi implements CookingSessionApi {
  Future<CookingSession> Function(String recipeId)? onStart;
  Future<CookingSessionResult> Function(String id)? onComplete;
  Future<CookingSession> Function(String id)? onAbandon;
  Future<CookingSessionResult> Function(String id)? onGetById;

  Object? onStartError;
  Object? onCompleteError;
  Object? onAbandonError;
  Object? onGetByIdError;

  @override
  Future<CookingSession> start(String recipeId) async {
    if (onStartError != null) throw onStartError!;
    if (onStart != null) return onStart!(recipeId);
    throw UnimplementedError();
  }

  /// Ưu tiên hơn [onComplete] khi test cần phân biệt `allowShortfall`.
  Future<CookingSessionResult> Function(String id, bool allowShortfall)?
      onCompleteWith;

  /// Giá trị `allowShortfall` của từng lần gọi `complete` — theo thứ tự.
  final List<bool> completeCalls = <bool>[];

  @override
  Future<CookingSessionResult> complete(String sessionId,
      {bool allowShortfall = false}) async {
    completeCalls.add(allowShortfall);
    if (onCompleteError != null) throw onCompleteError!;
    if (onCompleteWith != null) {
      return onCompleteWith!(sessionId, allowShortfall);
    }
    if (onComplete != null) return onComplete!(sessionId);
    throw UnimplementedError();
  }

  @override
  Future<CookingSession> abandon(String sessionId) async {
    if (onAbandonError != null) throw onAbandonError!;
    if (onAbandon != null) return onAbandon!(sessionId);
    throw UnimplementedError();
  }

  @override
  Future<CookingSessionResult> getById(String sessionId) async {
    if (onGetByIdError != null) throw onGetByIdError!;
    if (onGetById != null) return onGetById!(sessionId);
    throw UnimplementedError();
  }
}

class FakeRecipeApi implements RecipeApi {
  Future<List<CookingSessionStep>> Function(String recipeId)? onGetSteps;
  Object? onGetStepsError;
  int getStepsCalls = 0;

  @override
  Future<List<CookingSessionStep>> getSteps(String recipeId) async {
    getStepsCalls++;
    if (onGetStepsError != null) throw onGetStepsError!;
    if (onGetSteps != null) return onGetSteps!(recipeId);
    throw UnimplementedError();
  }
}

/// Một lần gọi `ask` đã ghi lại — test đối chiếu payload gửi lên.
class AssistCall {
  AssistCall(this.sessionId, this.message, this.viewedStep, this.chatHistory);

  final String sessionId;
  final String message;
  final int viewedStep;
  final List<ChatTurn> chatHistory;
}

class FakeCookingAssistApi implements CookingAssistApi {
  final List<AssistCall> calls = <AssistCall>[];
  Future<CookingAssistData> Function(AssistCall call)? onAsk;

  @override
  Future<CookingAssistData> ask(
    String sessionId, {
    required String message,
    required int viewedStep,
    required List<ChatTurn> chatHistory,
  }) async {
    final call = AssistCall(sessionId, message, viewedStep, chatHistory);
    calls.add(call);
    if (onAsk != null) return onAsk!(call);
    throw UnimplementedError();
  }
}

CookingAssistData assistData({
  String answer = 'OK',
  AssistIntent intent = AssistIntent.stepQa,
  int? stepRef,
  bool fallback = false,
  List<SubstituteOption> substitutes = const <SubstituteOption>[],
  List<BlockedSubstitute> blocked = const <BlockedSubstitute>[],
  List<ScaledIngredient> scaled = const <ScaledIngredient>[],
  bool guestsUnknown = true,
}) =>
    CookingAssistData(
      requestId: 'req-1',
      intent: intent,
      answer: answer,
      stepRef: stepRef,
      substitutes: substitutes,
      blockedSubstitutes: blocked,
      scaledIngredients: scaled,
      fallback: fallback,
      contextSource: AssistContextSource.snapshot,
      allergenScope: AllergenScope(
        householdMembers: true,
        dependents: false,
        guestsUnknown: guestsUnknown,
      ),
    );
