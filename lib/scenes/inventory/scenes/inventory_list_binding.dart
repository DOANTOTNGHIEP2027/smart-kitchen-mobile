import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/realtime_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../data/inventory_api.dart';
import '../data/inventory_dao.dart';
import '../stores/inventory_form_store.dart';
import '../stores/inventory_store.dart';

/// Binding cho `InventoryListScene` (FE-5 §13).
///
/// `InventoryStore` đăng ký permanent (singleton) vì phải sống sót qua các
/// lần push/pop màn hình danh sách — mất store = mất subscription Drift + WS.
class InventoryListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InventoryStore>()) {
      Get.put<InventoryStore>(
        InventoryStore(
          dao: InventoryDao(Get.find<AppDatabase>()),
          api: Get.find<InventoryApi>(),
          connectivity: Get.find<ConnectivityService>(),
          sessionStore: Get.find<SessionStore>(),
        ),
        permanent: true,
      );
    }
    // Wire WS event → InventoryStore.handleWsEvent. RealtimeStore bắn 1
    // stream broadcast nên listen ở đây không leak — chỉ seed store mất khi
    // app tắt. Nếu RealtimeStore chưa sẵn sàng (auth chưa xong), bỏ qua —
    // catch tại đây để không ném exception khi binding chạy sớm.
    if (Get.isRegistered<InventoryStore>() &&
        Get.isRegistered<RealtimeStore>() &&
        !Get.isRegistered<_WsWire>()) {
      Get.put<_WsWire>(const _WsWire(), permanent: true);
      try {
        final realtime = Get.find<RealtimeStore>();
        final store = Get.find<InventoryStore>();
        realtime.events.listen(store.handleWsEvent);
      } catch (_) {
        // Degrade graceful — store vẫn đọc từ Drift, chỉ không realtime.
      }
    }
  }
}

class _WsWire {
  const _WsWire();
}

/// Binding cho `InventoryFormScene` — một class cho cả add & edit, mode
/// được suy từ `Get.parameters['id']` (FE-5 §13).
class InventoryFormBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.parameters['id'];
    final mode =
        id == null ? InventoryFormMode.create : InventoryFormMode.edit;
    Get.lazyPut<InventoryFormStore>(
      () => InventoryFormStore(
        mode: mode,
        itemId: id,
        dao: InventoryDao(Get.find<AppDatabase>()),
        api: Get.find<InventoryApi>(),
        connectivity: Get.find<ConnectivityService>(),
        sessionStore: Get.find<SessionStore>(),
      ),
    );
  }
}
