import 'package:get/get.dart';

import '../../../routing/route_guards.dart';
import '../../recap/scenes/monthly_recap_scene.dart';
import 'insights_binding.dart';

/// Route name của module insights (#87). Giữ nguyên tên route cũ để 4 lối vào
/// (nhật ký bữa ăn, widget calo, hồ sơ, Tổng kết tuần) không phải đổi — nay mở
/// màn Tổng kết tháng.
abstract class InsightsRoutes {
  static const String history = '/insights/history';
}

/// List route + binding, ghép vào AppPages theo quy ước aggregation D2.
final List<GetPage<dynamic>> insightsPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: InsightsRoutes.history,
    page: () => const MonthlyRecapScene(),
    binding: InsightsBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];