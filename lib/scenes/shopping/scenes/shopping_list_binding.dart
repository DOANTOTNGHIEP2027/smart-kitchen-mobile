import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/read_cache_dao.dart';
import '../../../services/connectivity_service.dart';
import '../../../stores/session_store.dart';
import '../../../stores/realtime_store.dart';
import '../../mealplan/domain/shopping_list_sink.dart';
import '../../profile/api/family_api.dart';
import '../../profile/api/health_api.dart';
import '../../profile/stores/family_store.dart';
import '../data/shopping_category_dao.dart';
import '../domain/shopping_list_sink_impl.dart';
import '../data/shopping_api.dart';
import '../data/shopping_dao.dart';
import '../stores/category_store.dart';
import '../stores/shopping_store.dart';

class ShoppingListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ShoppingApi>()) Get.put<ShoppingApi>(ShoppingApiImpl(Get.find()), permanent: true);
    // #134 — roster cho tên người được giao. `fenix` để sống qua điều hướng;
    // bản của FamilyBinding cũng có `fenix` (B1, §9.6).
    Get.lazyPut<FamilyStore>(
      () => FamilyStore(Get.find<FamilyApi>(), Get.find<HealthApi>(), Get.find<ReadCacheDao>(), Get.find<SessionStore>()),
      fenix: true,
    );
    // #69 — category local-only: đăng ký DUY NHẤT ở đây (Guard #11, Fix
    // CRITICAL-1) vì sheet thêm món sống trên route này.
    Get.lazyPut<CategoryStore>(
      () => CategoryStore(ShoppingCategoryDao(Get.find<AppDatabase>()), Get.find<SessionStore>()),
      fenix: true,
    );
    if (!Get.isRegistered<ShoppingStore>()) {
      Get.put<ShoppingStore>(
        ShoppingStore(
          dao: ShoppingDao(Get.find<AppDatabase>()),
          api: Get.find<ShoppingApi>(),
          connectivity: Get.find<ConnectivityService>(),
          session: Get.find<SessionStore>(),
          onRosterStale: () {
            if (Get.isRegistered<FamilyStore>()) Get.find<FamilyStore>().loadRoster();
          },
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<ShoppingListSink>()) {
      Get.put<ShoppingListSink>(
        ShoppingListSinkImpl(Get.find<ShoppingStore>()),
        permanent: true,
      );
    }
    if (Get.isRegistered<RealtimeStore>() && !Get.isRegistered<_ShoppingWsWire>()) {
      Get.put<_ShoppingWsWire>(const _ShoppingWsWire(), permanent: true);
      Get.find<RealtimeStore>().events.listen((event) {
        if (event.eventType.toLowerCase().contains('shopping')) {
          Get.find<ShoppingStore>().sync();
        }
      });
    }
  }
}

class _ShoppingWsWire { const _ShoppingWsWire(); }
