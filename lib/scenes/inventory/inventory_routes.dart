import 'package:get/get.dart';

import '../../routing/route_guards.dart';
import 'scenes/inventory_form_scene.dart';
import 'scenes/inventory_list_binding.dart';
import 'scenes/inventory_list_scene.dart';

/// Hằng số route name cho inventory (FE-5 §13).
abstract class InventoryRoutes {
  static const String list = '/inventory';
  static const String add = '/inventory/add';
  static const String edit = '/inventory/:id/edit';
}

/// [GetPage] của inventory module, để AppPages nối vào. Bám pattern
/// `profileFamilyRoutes.dart` (quy ước aggregation D2 của fe-app-shell).
final List<GetPage<dynamic>> inventoryPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: InventoryRoutes.list,
    page: () => const InventoryListScene(),
    binding: InventoryListBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    // Static path phải khai trước pattern để GetX ưu tiên match chính xác.
    name: InventoryRoutes.add,
    page: () => const InventoryFormScene(),
    binding: InventoryFormBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: InventoryRoutes.edit,
    page: () => const InventoryFormScene(),
    binding: InventoryFormBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
