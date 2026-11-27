import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../services/connectivity_service.dart';
import '../../inventory/data/inventory_batch_api.dart';
import '../../inventory/stores/inventory_store.dart';
import '../data/checkout_api.dart';
import '../stores/shopping_checkout_store.dart';
import '../stores/shopping_store.dart';
import 'shopping_list_binding.dart';

/// `/shopping/checkout` (#239). Store sống theo route — mỗi lần mở là một lần
/// xem trước mới, kèm idempotency key mới.
class ShoppingCheckoutBinding extends Bindings {
  @override
  void dependencies() {
    // Màn có thể mở từ hoá đơn (#68) khi tab đi chợ chưa từng mở.
    ShoppingListBinding().dependencies();
    if (!Get.isRegistered<CheckoutApi>()) {
      Get.put<CheckoutApi>(CheckoutApiImpl(Get.find<DioClient>()), permanent: true);
    }
    if (!Get.isRegistered<InventoryBatchApi>()) {
      Get.put<InventoryBatchApi>(InventoryBatchApiImpl(Get.find<DioClient>()), permanent: true);
    }
    Get.put<ShoppingCheckoutStore>(
      ShoppingCheckoutStore(
        api: Get.find<CheckoutApi>(),
        batchApi: Get.find<InventoryBatchApi>(),
        connectivity: Get.find<ConnectivityService>(),
        onCommitted: () async {
          await Get.find<ShoppingStore>().sync();
          if (Get.isRegistered<InventoryStore>()) {
            await Get.find<InventoryStore>().syncFromServer();
          }
        },
      ),
    );
  }
}
