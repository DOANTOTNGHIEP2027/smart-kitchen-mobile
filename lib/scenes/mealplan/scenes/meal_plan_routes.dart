import 'package:get/get.dart';

import '../../../routing/route_guards.dart';
import '../data/meal_plan_api.dart';
import '../data/meal_composition_api.dart';
import '../stores/meal_composition_store.dart';
import '../../../data/network/dio_client.dart';
import '../../../app/env_config.dart';
import '../data/meal_attendance_api.dart';
import '../data/meal_suggestion_api.dart';
import '../stores/meal_plan_store.dart';
import 'meal_suggestion_detail_scene.dart';

import 'weekly_meal_plan_scene.dart';

abstract class MealPlanRoutes {
  static const String weekly = '/meal-plan';
  static const String detail = '/meal-plan/slot/:slotId/dish/:dishId/detail';

  static String detailOf(String slotId, String dishId) =>
      '/meal-plan/slot/$slotId/dish/$dishId/detail';
}

class WeeklyMealPlanBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MealCompositionApi>()) {
      Get.lazyPut<MealCompositionApi>(
        () => MealCompositionApi(Get.find<DioClient>()),
      );
    }
    // D7 — MealPlanStore dùng `Get.put`, sống theo route `/meal-plan` còn
    // trong nav stack. VoteSessionBinding/MealSuggestionDetailBinding lấy cùng
    // instance này qua `Get.find<MealPlanStore>()`.
    if (!Get.isRegistered<MealPlanStore>()) {
      Get.put<MealPlanStore>(
        MealPlanStore(
          api: Get.find<MealPlanApi>(),
          suggestionApi: Get.find<MealSuggestionApi>(),
          attendanceApi: Get.find<MealAttendanceApi>(),
        ),
        permanent: false,
      );
      if (EnvConfig.automaticMealComposition) {
        Get.put<MealCompositionStore>(
          MealCompositionStore(
            Get.find<MealCompositionApi>(),
            Get.find<MealPlanStore>(),
          ),
        );
      }
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
];
