import 'package:get/get.dart';

import '../../../routing/route_guards.dart';
import '../../../stores/realtime_store.dart';
import '../../../stores/session_store.dart';
import '../data/meal_plan_api.dart';
import '../data/vote_api.dart';
import '../stores/meal_plan_store.dart';
import 'meal_suggestion_detail_scene.dart';
import 'vote_session_scene.dart';
import 'weekly_meal_plan_scene.dart';

abstract class MealPlanRoutes {
  static const String weekly = '/meal-plan';
  static const String detail =
      '/meal-plan/slot/:slotId/dish/:dishId/detail';
  static const String vote = '/meal-plan/slot/:slotId/dish/:dishId/vote';

  static String detailOf(String slotId, String dishId) =>
      '/meal-plan/slot/$slotId/dish/$dishId/detail';
  static String voteOf(String slotId, String dishId) =>
      '/meal-plan/slot/$slotId/dish/$dishId/vote';
}

class WeeklyMealPlanBinding extends Bindings {
  @override
  void dependencies() {
    // D7 — MealPlanStore dùng `Get.put`, sống theo route `/meal-plan` còn
    // trong nav stack. VoteSessionBinding/MealSuggestionDetailBinding lấy cùng
    // instance này qua `Get.find<MealPlanStore>()`.
    if (!Get.isRegistered<MealPlanStore>()) {
      Get.put<MealPlanStore>(
        MealPlanStore(
          api: Get.find<MealPlanApi>(),
          voteApi: Get.find<VoteApi>(),
          realtimeStore: Get.find<RealtimeStore>(),
          sessionStore: Get.find<SessionStore>(),
        ),
        permanent: false,
      );
    }
  }
}

class MealSuggestionDetailBinding extends Bindings {
  @override
  void dependencies() {
    // SuggestionStore tự tạo trong initState.
  }
}

final List<GetPage<dynamic>> mealPlanPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: MealPlanRoutes.weekly,
    page: () => const WeeklyMealPlanScene(),
    binding: WeeklyMealPlanBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: MealPlanRoutes.detail,
    page: () => const MealSuggestionDetailScene(),
    binding: MealSuggestionDetailBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: MealPlanRoutes.vote,
    page: () => const VoteSessionScene(),
    binding: VoteSessionBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
