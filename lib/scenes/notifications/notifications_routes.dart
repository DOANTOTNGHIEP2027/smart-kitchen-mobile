import 'package:get/get.dart';

import '../../data/notification/notification_routing.dart';
import '../../routing/app_routes.dart';
import '../../routing/route_guards.dart';
import '../inventory/inventory_routes.dart';
import '../mealplan/scenes/meal_plan_routes.dart';
import 'notifications_scene.dart';

/// Route màn thông báo trong phiên (fcm-notification-flow.md §8).
abstract class NotificationsRoutes {
  static const String list = '/notifications';

  /// Allow-list compile-time: target → route hằng số (Guard 2). KHÔNG bao giờ
  /// dùng chuỗi lấy từ payload FCM.
  static String routeFor(NotificationTarget target) => switch (target) {
        NotificationTarget.inventory => InventoryRoutes.list,
        NotificationTarget.mealPlan => MealPlanRoutes.weekly,
        NotificationTarget.shopping => AppRoutes.shopping,
        NotificationTarget.notifications => list,
      };
}

final List<GetPage<dynamic>> notificationsPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: NotificationsRoutes.list,
    page: () => const NotificationsScene(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
