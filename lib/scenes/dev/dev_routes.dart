import 'package:get/get.dart';

import 'widget_showcase_scene.dart';

/// Route chỉ dành cho build dev (design-system.md §8). `AppPages.pages` chỉ
/// nối [devPages] khi `EnvConfig.isDev`.
abstract class DevRoutes {
  static const String widgetShowcase = '/dev/widgets';
}

final List<GetPage<dynamic>> devPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: DevRoutes.widgetShowcase,
    page: () => const WidgetShowcaseScene(),
  ),
];
