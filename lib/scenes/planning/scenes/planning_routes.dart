import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../routing/route_guards.dart';
import '../../profile/api/health_api.dart';
import '../data/guest_diner_api.dart';
import '../data/meal_slot_api.dart';
import '../stores/guest_diner_store.dart';
import '../stores/meal_slot_store.dart';
import 'guest_diner_scene.dart';
import 'meal_slot_config_scene.dart';

/// Route của module planning (#101, flexible-meal-planning-screens.md §10).
abstract class PlanningRoutes {
  static const String slotConfig = '/meal-plan/slot-config';
  static const String guestDiners = '/meal-plan/plan/:planId/guest-diners';

  static String guestDinersOf(String planId) =>
      '/meal-plan/plan/$planId/guest-diners';
}

class MealSlotConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MealSlotApi>(() => MealSlotApi(Get.find<DioClient>()),
        fenix: true);
    Get.lazyPut<MealSlotStore>(() => MealSlotStore(Get.find<MealSlotApi>()));
  }
}

class GuestDinerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuestDinerApi>(() => GuestDinerApi(Get.find<DioClient>()),
        fenix: true);
    // HealthApi đăng ký permanent ở bootstrap.dart.
    Get.lazyPut<GuestDinerStore>(() => GuestDinerStore(
          Get.find<GuestDinerApi>(),
          Get.find<HealthApi>(),
          Get.parameters['planId']!,
        ));
  }
}

/// Ghép vào `AppPages.pages` theo quy ước aggregation D2.
final List<GetPage<dynamic>> planningPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: PlanningRoutes.slotConfig,
    page: () => const MealSlotConfigScene(),
    binding: MealSlotConfigBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: PlanningRoutes.guestDiners,
    page: () => const GuestDinerScene(),
    binding: GuestDinerBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
