import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../routing/route_guards.dart';
import '../../../stores/session_store.dart';
import '../../profile/api/health_api.dart';
import '../data/cooking_session_api.dart';
import '../data/meal_log_api.dart';
import '../data/recipe_api.dart';
import '../stores/cooking_session_store.dart';
import '../stores/meal_log_store.dart';
import 'cooking_session_scene.dart';
import 'meal_log_scene.dart';

/// Hằng số route name cho cooking (FE-6 §10, meal-log §11.2).
abstract class CookingRoutes {
  static const String session = '/cooking/session';
  static const String mealLog = '/cooking/meal-log';
}

class MealLogBinding extends Bindings {
  @override
  void dependencies() {
    // HealthApi đã được đăng ký permanent ở bootstrap.dart — Only lazyPut nếu
    // chưa có (Decision D3: MealLogStore dùng HealthApi trực tiếp, không qua
    // ProfileStore).
    if (!Get.isRegistered<HealthApi>()) {
      Get.put<HealthApi>(HealthApiImpl(Get.find<DioClient>()), permanent: true);
    }
    if (!Get.isRegistered<MealLogApi>()) {
      Get.put<MealLogApi>(MealLogApiImpl(Get.find<DioClient>()), permanent: true);
    }
    Get.lazyPut<MealLogStore>(
      () => MealLogStore(
        Get.find<MealLogApi>(),
        Get.find<HealthApi>(),
        Get.find<SessionStore>(),
      ),
      fenix: true,
    );
  }
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
  GetPage<void>(
    name: CookingRoutes.mealLog,
    page: () => const MealLogScene(),
    binding: MealLogBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
