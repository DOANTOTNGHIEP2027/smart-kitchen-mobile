import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../../../services/connectivity_service.dart';
import '../../../stores/session_store.dart';
import '../../../stores/realtime_store.dart';
import '../data/shopping_api.dart';
import '../data/shopping_dao.dart';
import '../stores/shopping_store.dart';

class ShoppingListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ShoppingApi>()) Get.put<ShoppingApi>(ShoppingApiImpl(Get.find()), permanent: true);
    if (!Get.isRegistered<ShoppingStore>()) Get.put<ShoppingStore>(ShoppingStore(dao: ShoppingDao(Get.find<AppDatabase>()), api: Get.find<ShoppingApi>(), connectivity: Get.find<ConnectivityService>(), session: Get.find<SessionStore>()), permanent: true);
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
