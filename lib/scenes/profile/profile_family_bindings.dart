import 'package:get/get.dart';

import '../../data/db/read_cache_dao.dart';
import '../../stores/session_store.dart';
import 'api/avatar_image_processor.dart';
import 'api/dependent_api.dart';
import 'api/family_api.dart';
import 'api/health_api.dart';
import 'api/profile_api.dart';
import 'stores/dependent_store.dart';
import 'stores/family_store.dart';
import 'stores/profile_store.dart';
import 'domain/health_profile.dart';
import '../../widgets/states/view_state.dart';
import '../../data/network/dio_client.dart';
import '../cooking/data/meal_log_api.dart';
import '../nutrition/stores/nutrition_store.dart';

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
      () {
        // MealLogApi thường chỉ đăng ký khi vào route nấu ăn — Profile cần sớm hơn.
        if (!Get.isRegistered<MealLogApi>()) {
          Get.put<MealLogApi>(MealLogApiImpl(Get.find<DioClient>()),
              permanent: true);
        }
        final session = Get.find<SessionStore>();
        return NutritionStore(
          mealLogApi: Get.find<MealLogApi>(),
          healthApi: Get.find<HealthApi>(),
          selfId: () => session.currentUser?.id,
        )..followTarget(profileTargetSource());
      },
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

/// #125 — store hồ sơ phụ thuộc (dependent-profile-screens.md §16.4). Dùng
/// chung card trong `/family` + 4 route `/dependents/**`; tự đảm bảo
/// [FamilyStore] (idempotent nhờ `isRegistered`).
class DependentBinding extends Bindings {
  @override
  void dependencies() {
    FamilyBinding().dependencies();
    if (!Get.isRegistered<DependentStore>()) {
      Get.lazyPut<DependentStore>(
        () => DependentStore(
          Get.find<DependentApi>(),
          Get.find<HealthApi>(),
          Get.find<FamilyStore>(),
          Get.find<ReadCacheDao>(),
          Get.find<SessionStore>(),
        ),
        fenix: true,
      );
    }
  }
}
