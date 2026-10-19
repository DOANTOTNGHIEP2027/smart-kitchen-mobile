import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../routing/route_guards.dart';
import '../../mealplan/stores/meal_plan_store.dart';
import '../../profile/api/health_api.dart';
import '../data/candidate_api.dart';
import '../data/guest_diner_api.dart';
import '../data/meal_slot_api.dart';
import '../data/repetition_api.dart';
import '../stores/candidate_store.dart';
import '../stores/guest_diner_store.dart';
import '../stores/meal_slot_store.dart';
import '../stores/repetition_store.dart';
import 'candidate_insight_scene.dart';
import 'guest_diner_scene.dart';
import 'meal_slot_config_scene.dart';
import 'repetition_summary_scene.dart';

/// Route của module planning (#101, flexible-meal-planning-screens.md §10).
abstract class PlanningRoutes {
  static const String slotConfig = '/meal-plan/slot-config';
  static const String guestDiners = '/meal-plan/plan/:planId/guest-diners';

  static String guestDinersOf(String planId) =>
      '/meal-plan/plan/$planId/guest-diners';

  /// Ứng viên AI của kế hoạch tuần. Query tuỳ chọn: `sessionId` (lọc 1 phiên),
  /// `slotId` + `dishId` (cho phép sinh gợi ý cho đúng món đó), `noSession=1`
  /// (món chưa từng mở phiên) — OD-08.
  static const String candidates = '/meal-plan/plan/:planId/candidates';
  static const String repetitionSummary = '/meal-plan/repetition-summary';

  static String candidatesOf(
    String planId, {
    String? sessionId,
    String? slotId,
    String? dishId,
    bool dishHasNoSession = false,
  }) {
    final query = <String, String>{
      if (sessionId != null) 'sessionId': sessionId,
      if (slotId != null && dishId != null) ...<String, String>{
        'slotId': slotId,
        'dishId': dishId,
      },
      if (dishHasNoSession) 'noSession': '1',
    };
    return Uri(
      path: '/meal-plan/plan/$planId/candidates',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
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

class CandidateInsightBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CandidateApi>(() => CandidateApi(Get.find<DioClient>()),
        fenix: true);
    final slotId = Get.parameters['slotId'];
    final dishId = Get.parameters['dishId'];
    // Route chỉ push từ trong nav stack còn `/meal-plan` → MealPlanStore có sẵn.
    final canGenerate = slotId != null &&
        dishId != null &&
        Get.isRegistered<MealPlanStore>();
    Get.lazyPut<CandidateStore>(() => CandidateStore(
          Get.find<CandidateApi>(),
          Get.parameters['planId']!,
          sessionId: Get.parameters['sessionId'],
          dishHasNoSession: Get.parameters['noSession'] == '1',
          openSession: canGenerate
              ? () => Get.find<MealPlanStore>().openVoteSession(slotId, dishId)
              : null,
        ));
  }
}

class RepetitionSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RepetitionApi>(() => RepetitionApi(Get.find<DioClient>()),
        fenix: true);
    Get.lazyPut<RepetitionStore>(
        () => RepetitionStore(Get.find<RepetitionApi>()));
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
  GetPage<void>(
    name: PlanningRoutes.candidates,
    page: () => const CandidateInsightScene(),
    binding: CandidateInsightBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: PlanningRoutes.repetitionSummary,
    page: () => const RepetitionSummaryScene(),
    binding: RepetitionSummaryBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
