import 'package:get/get.dart';

import '../../../../data/db/app_database.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../stores/session_store.dart';
import '../../data/inventory_api.dart';
import '../../data/inventory_batch_api.dart';
import '../../data/inventory_dao.dart';
import '../../stores/inventory_form_store.dart';
import '../../stores/inventory_store.dart';
import '../data/ocr_api.dart';
import '../data/ocr_image_service.dart';
import '../stores/ocr_store.dart';

class OcrBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OcrApi>()) {
      Get.lazyPut<OcrApi>(
        () => OcrApiImpl(Get.find<DioClient>()),
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
    if (!Get.isRegistered<InventoryBatchApi>()) {
      Get.put<InventoryBatchApi>(
        InventoryBatchApiImpl(Get.find<DioClient>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<OcrStore>()) {
      Get.lazyPut<OcrStore>(
        () => OcrStore(
          api: Get.find<OcrApi>(),
          imagePicker: Get.find<OcrImagePicker>(),
          imageCompressor: Get.find<OcrImageCompressor>(),
          formStoreFactory: () => InventoryFormStore(
            mode: InventoryFormMode.create,
            dao: Get.isRegistered<InventoryDao>()
                ? Get.find<InventoryDao>()
                : InventoryDao(Get.find<AppDatabase>()),
            api: Get.find<InventoryApi>(),
            connectivity: Get.find<ConnectivityService>(),
            sessionStore: Get.find<SessionStore>(),
          ),
          // #239: "Xác nhận tất cả" ghi một lần batch.
          batchApi: Get.find<InventoryBatchApi>(),
          onBatchCommitted: () async {
            if (Get.isRegistered<InventoryStore>()) {
              await Get.find<InventoryStore>().syncFromServer();
            }
          },
        ),
        fenix: true,
      );
    }
  }
}
