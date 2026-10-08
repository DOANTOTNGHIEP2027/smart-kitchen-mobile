import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../stores/session_store.dart';
import '../../profile/api/health_api.dart';
import '../data/adherence_api.dart';
import '../data/history_api.dart';
import '../stores/history_store.dart';

/// DI cho module insights (#87) — `HistoryStore` dùng HealthApi trực tiếp
/// (Decision D3, tái áp dụng từ meal-log-screen).
class InsightsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HealthApi>()) {
      Get.put<HealthApi>(HealthApiImpl(Get.find<DioClient>()), permanent: true);
    }
    Get.lazyPut<HistoryApi>(() => HistoryApi(Get.find<DioClient>()), fenix: true);
    Get.lazyPut<AdherenceApi>(
      () => AdherenceApi(Get.find<DioClient>()),
      fenix: true,
    );
    Get.lazyPut<HistoryStore>(
      () => HistoryStore(
        Get.find<HistoryApi>(),
        Get.find<AdherenceApi>(),
        Get.find<HealthApi>(),
        Get.find<SessionStore>(),
      ),
      fenix: true,
    );
  }
}