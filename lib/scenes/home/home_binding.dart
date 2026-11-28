import 'package:get/get.dart';

import '../mealplan/data/meal_plan_api.dart';
import 'stores/home_store.dart';

/// Đăng ký [HomeStore] cho tab Trang chủ — idempotent, shell gọi trực tiếp
/// (D7: tab trong IndexedStack không đi qua GetPage binding).
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<HomeStore>()) return;
    Get.put<HomeStore>(HomeStore(mealPlanApi: Get.find<MealPlanApi>()));
  }
}
