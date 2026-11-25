import 'package:get/get.dart';

import '../../data/db/read_cache_dao.dart';
import '../../stores/session_store.dart';
import 'api/avatar_image_processor.dart';
import 'api/family_api.dart';
import 'api/health_api.dart';
import 'api/profile_api.dart';
import 'stores/family_store.dart';
import 'stores/profile_store.dart';

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
  }
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
