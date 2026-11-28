import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../stores/session_store.dart';
import '../../recap/data/monthly_recap_api.dart';
import '../../recap/stores/monthly_recap_store.dart';

/// DI cho màn Tổng kết tháng (route `InsightsRoutes.history`).
class InsightsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MonthlyRecapApi>(
      () => MonthlyRecapApi(Get.find<DioClient>()),
      fenix: true,
    );
    Get.lazyPut<MonthlyRecapStore>(
      () => MonthlyRecapStore(
        Get.find<MonthlyRecapApi>(),
        Get.find<SessionStore>(),
      ),
      fenix: true,
    );
  }
}