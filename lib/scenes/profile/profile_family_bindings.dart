import 'package:get/get.dart';

import '../../data/db/read_cache_dao.dart';
import '../../stores/session_store.dart';
import 'api/avatar_image_processor.dart';
import 'api/family_api.dart';
import 'api/health_api.dart';
import 'api/profile_api.dart';
import 'stores/family_store.dart';
import 'stores/profile_store.dart';
import 'domain/health_profile.dart';
import '../../widgets/states/view_state.dart';
import '../mealplan/data/meal_plan_api.dart';
import '../nutrition/stores/nutrition_store.dart';
import '../recipe/data/recipe_catalog_api.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AvatarImageProcessor>()) {
      Get.lazyPut<AvatarImageProcessor>(
          () => const FlutterAvatarImageProcessor());
    }
    if (!Get.isRegistered<ProfileStore>()) {
      Get.lazyPut<ProfileStore>(
        () => ProfileStore(
          Get.find<HealthApi>(),
          Get.find<ProfileApi>(),
          Get.find<ReadCacheDao>(),
          Get.find<SessionStore>(),
          Get.find<AvatarImageProcessor>(),
        ),
      );
    }
    registerProfileNutrition();
  }
}

/// #64 — store dinh dưỡng cho thẻ trên Profile (nutrition-summary-widget.md
/// §8.2). Tách riêng để route con của Profile không phải dựng lại.
void registerProfileNutrition() {
  if (!Get.isRegistered<NutritionStore>(tag: NutritionStore.profileTag)) {
    Get.lazyPut<NutritionStore>(
      () => NutritionStore(
        recipeApi: Get.find<RecipeCatalogApi>(),
        healthApi: Get.find<HealthApi>(),
        mealPlanApi: Get.find<MealPlanApi>(),
      )..followTarget(profileTargetSource()),
      tag: NutritionStore.profileTag,
      fenix: true,
    );
  }
}

/// Nguồn target cho [NutritionStore.followTarget]: `ProfileStore.
/// healthProfileState` khi có — đổi mục tiêu ở màn hồ sơ sức khoẻ thì widget
/// dinh dưỡng cập nhật ngay (review v3.1 NEW-M2). Trả hàm `null` khi chưa có
/// giá trị thành công.
int? Function()? Function() profileTargetSource() {
  // `Get.isRegistered` không phải observable: nếu ProfileStore chưa đăng ký
  // lúc reaction chạy lần đầu (shell chạy WeeklyMealPlanBinding TRƯỚC
  // ProfileBinding), reaction không có dependency và không bao giờ chạy lại
  // (code review #64 HIGH-1). Đăng ký (lazyPut, idempotent) ngay tại đây.
  ProfileBinding().dependencies();
  return () {
    final state = Get.find<ProfileStore>().healthProfileState;
    return switch (state) {
      SuccessState<HealthProfile>(:final data) => () => data.targetDailyCalories,
      _ => null,
    };
  };
}

class FamilyBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FamilyStore>()) {
      Get.lazyPut<FamilyStore>(
        () => FamilyStore(
          Get.find<FamilyApi>(),
          Get.find<HealthApi>(),
          Get.find<ReadCacheDao>(),
          Get.find<SessionStore>(),
        ),
        // B1 (shopping-list-screen §9.6): sống qua điều hướng — /shopping dùng
        // chung instance, pop /family không được xoá mất store.
        fenix: true,
      );
    }
  }
}
