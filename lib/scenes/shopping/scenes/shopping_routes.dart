import 'package:get/get.dart';

import '../../../routing/app_routes.dart';
import 'shopping_list_binding.dart';
import 'shopping_list_scene.dart';

final List<GetPage<dynamic>> shoppingPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: AppRoutes.shopping,
    page: () => const ShoppingListScene(),
    binding: ShoppingListBinding(),
  ),
];
