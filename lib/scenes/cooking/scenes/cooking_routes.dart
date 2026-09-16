import 'package:get/get.dart';

import '../../../routing/route_guards.dart';
import '../data/cooking_session_api.dart';
import '../data/recipe_api.dart';
import '../stores/cooking_session_store.dart';
import 'cooking_session_scene.dart';

/// Hằng số route name cho cooking (FE-6 §10).
abstract class CookingRoutes {
  static const String session = '/cooking/session';
}

/// Tham số truyền vào `/cooking/session` qua `Get.toNamed(arguments: ...)`.
/// `start` tạo session mới; `resume` lấy session đã có.
sealed class CookingArgs {
  const CookingArgs();
  const factory CookingArgs.start(String recipeId) = _CookingStartArgs;
  const factory CookingArgs.resume(String sessionId) = _CookingResumeArgs;
}

class _CookingStartArgs implements CookingArgs {
  const _CookingStartArgs(this.recipeId);
  final String recipeId;
}

class _CookingResumeArgs implements CookingArgs {
  const _CookingResumeArgs(this.sessionId);
  final String sessionId;
}

class CookingSessionBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as CookingArgs;
    Get.lazyPut<CookingSessionStore>(
      () {
        final cookingApi = Get.find<CookingSessionApi>();
        final recipeApi = Get.find<RecipeApi>();
        return switch (args) {
          _CookingStartArgs(:final recipeId) => CookingSessionStore(
              cookingApi: cookingApi,
              recipeApi: recipeApi,
              entryMode: CookingEntryMode.start,
              recipeId: recipeId,
            ),
          _CookingResumeArgs(:final sessionId) => CookingSessionStore(
              cookingApi: cookingApi,
              recipeApi: recipeApi,
              entryMode: CookingEntryMode.resume,
              sessionId: sessionId,
            ),
        };
      },
    );
  }
}

/// List route + binding, ghép vào AppPages theo quy ước aggregation D2.
final List<GetPage<dynamic>> cookingPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: CookingRoutes.session,
    page: () => const CookingSessionScene(),
    binding: CookingSessionBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
