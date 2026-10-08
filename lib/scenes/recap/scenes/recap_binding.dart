import 'package:get/get.dart';

import '../../../data/network/dio_client.dart';
import '../../../stores/session_store.dart';
import '../data/recap_api.dart';
import '../stores/weekly_recap_store.dart';

/// DI cho module Weekly Recap (#86) — GetX routing/DI (quyết định D1).
class RecapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecapApi>(() => RecapApi(Get.find<DioClient>()), fenix: true);
    Get.lazyPut<WeeklyRecapStore>(
      () => WeeklyRecapStore(
        Get.find<RecapApi>(),
        Get.find<SessionStore>(),
      ),
      fenix: true,
    );
  }
}