import 'package:get/get.dart';

import '../../../routing/route_guards.dart';
import 'insights_binding.dart';
import 'monthly_history_scene.dart';

/// Route name của module insights (#87).
abstract class InsightsRoutes {
  static const String history = '/insights/history';
}

/// List route + binding, ghép vào AppPages theo quy ước aggregation D2.
final List<GetPage<dynamic>> insightsPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: InsightsRoutes.history,
    page: () => const MonthlyHistoryScene(),
    binding: InsightsBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];