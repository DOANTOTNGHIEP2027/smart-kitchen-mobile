import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_session_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/recipe_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';

/// Stub programmable cho cooking API — bám pattern FakeInventoryApi.
class FakeCookingApi implements CookingSessionApi {
  Future<CookingSession> Function(String recipeId)? onStart;
  Future<CookingSession> Function(String id, int step)? onAdvanceStep;
  Future<CookingSessionResult> Function(String id)? onComplete;
  Future<CookingSession> Function(String id)? onAbandon;
  Future<CookingSessionResult> Function(String id)? onGetById;

  Object? onStartError;
  Object? onAdvanceStepError;
  Object? onCompleteError;
  Object? onAbandonError;
  Object? onGetByIdError;

  @override
  Future<CookingSession> start(String recipeId) async {
    if (onStartError != null) throw onStartError!;
    if (onStart != null) return onStart!(recipeId);
    throw UnimplementedError();
  }

  @override
  Future<CookingSession> advanceStep(String sessionId, int step) async {
    if (onAdvanceStepError != null) throw onAdvanceStepError!;
    if (onAdvanceStep != null) return onAdvanceStep!(sessionId, step);
    throw UnimplementedError();
  }

  @override
  Future<CookingSessionResult> complete(String sessionId) async {
    if (onCompleteError != null) throw onCompleteError!;
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

  @override
  Future<List<CookingSessionStep>> getSteps(String recipeId) async {
    if (onGetStepsError != null) throw onGetStepsError!;
    if (onGetSteps != null) return onGetSteps!(recipeId);
    throw UnimplementedError();
  }
}
