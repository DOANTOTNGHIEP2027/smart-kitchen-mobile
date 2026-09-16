import 'package:get/get.dart';

import '../../data/db/read_cache_dao.dart';
import '../../stores/session_store.dart';
import 'api/family_api.dart';
import 'api/health_api.dart';
import 'api/profile_api.dart';
import 'stores/family_store.dart';
import 'stores/profile_store.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileStore>()) {
      Get.lazyPut<ProfileStore>(
        () => ProfileStore(
          Get.find<HealthApi>(),
          Get.find<ProfileApi>(),
          Get.find<ReadCacheDao>(),
          Get.find<SessionStore>(),
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
      );
    }
  }
}
