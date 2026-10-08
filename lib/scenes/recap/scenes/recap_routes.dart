import 'package:get/get.dart';

import '../../../routing/route_guards.dart';
import 'recap_binding.dart';
import 'weekly_recap_scene.dart';

/// Route name của module Weekly Recap (#86).
abstract class RecapRoutes {
  static const String root = '/insights/weekly-recap';
}

/// List route + binding, ghép vào AppPages theo quy ước aggregation D2.
final List<GetPage<dynamic>> recapPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: RecapRoutes.root,
    page: () => const WeeklyRecapScene(),
    binding: RecapBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];