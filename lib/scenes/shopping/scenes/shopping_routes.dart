import 'package:get/get.dart';

import '../../../routing/app_routes.dart';
import 'category_manager_binding.dart';
import 'category_manager_scene.dart';
import 'shopping_checkout_binding.dart';
import 'shopping_checkout_scene.dart';
import 'shopping_list_binding.dart';
import 'shopping_list_scene.dart';

final List<GetPage<dynamic>> shoppingPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: AppRoutes.shopping,
    page: () => const ShoppingListScene(),
    binding: ShoppingListBinding(),
  ),
  // #69 — CHỈ push từ icon trên ShoppingListScene (Guard #11).
  GetPage<void>(
    name: AppRoutes.shoppingCategories,
    page: () => const CategoryManagerScene(),
    binding: CategoryManagerBinding(),
  ),
  // #239 — push từ ShoppingListScene hoặc sau khi xác nhận hoá đơn (#68).
  GetPage<void>(
    name: AppRoutes.shoppingCheckout,
    page: () => const ShoppingCheckoutScene(),
    binding: ShoppingCheckoutBinding(),
  ),
];
