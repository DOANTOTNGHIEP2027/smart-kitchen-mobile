import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../../../data/network/dio_client.dart';
import '../../../services/connectivity_service.dart';
import '../../../stores/session_store.dart';
import '../../inventory/data/inventory_api.dart';
import '../../inventory/data/inventory_dao.dart';
import '../../inventory/ocr/data/ocr_image_service.dart';
import '../../inventory/stores/inventory_form_store.dart';
import '../../shopping/scenes/shopping_list_binding.dart';
import '../../shopping/stores/shopping_store.dart';
import '../data/receipt_api.dart';
import '../stores/receipt_scan_store.dart';

class ReceiptScanBinding extends Bindings {
  @override
  void dependencies() {
    // ShoppingStore là Get.put(permanent) trong ShoppingListBinding (idempotent
    // nhờ isRegistered). Gọi lại ở đây — không phụ thuộc thứ tự mở màn (Guard 8).
    ShoppingListBinding().dependencies();
    if (!Get.isRegistered<ReceiptApi>()) {
      Get.lazyPut<ReceiptApi>(
        () => ReceiptApiImpl(Get.find<DioClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<OcrImagePicker>()) {
      Get.lazyPut<OcrImagePicker>(DeviceOcrImagePicker.new, fenix: true);
    }
    if (!Get.isRegistered<OcrImageCompressor>()) {
      Get.lazyPut<OcrImageCompressor>(
        FlutterOcrImageCompressor.new,
        fenix: true,
      );
    }
    if (!Get.isRegistered<ReceiptScanStore>()) {
      Get.lazyPut<ReceiptScanStore>(
        () => ReceiptScanStore(
          api: Get.find<ReceiptApi>(),
          imagePicker: Get.find<OcrImagePicker>(),
          imageCompressor: Get.find<OcrImageCompressor>(),
          shoppingStore: Get.find<ShoppingStore>(),
          // Chép từ ocr_binding.dart — InventoryApi/ConnectivityService/
          // SessionStore/AppDatabase đều permanent ở app/bootstrap.dart.
          formStoreFactory: () => InventoryFormStore(
            mode: InventoryFormMode.create,
            dao: Get.isRegistered<InventoryDao>()
                ? Get.find<InventoryDao>()
                : InventoryDao(Get.find<AppDatabase>()),
            api: Get.find<InventoryApi>(),
            connectivity: Get.find<ConnectivityService>(),
            sessionStore: Get.find<SessionStore>(),
          ),
        ),
        fenix: true, // sống qua scan ↔ result
      );
    }
  }
}
