import 'package:get/get.dart';

import '../../../routing/app_routes.dart';
import '../../../routing/route_guards.dart';
import '../data/recipe_catalog_api.dart';
import '../stores/recipe_detail_store.dart';
import '../stores/recipe_store.dart';
import 'recipe_detail_scene.dart';
import 'recipe_list_scene.dart';

/// Đường dẫn chi tiết món. [viewOnly] → `?mode=view`: chỉ xem, không nấu.
/// Mở từ 1 món thực đơn: [mealPlanDishId]/[cookedAt] đi tiếp vào guard nấu
/// (gắn phiên với món, món đã nấu thì chỉ báo).
String recipeDetailPath(
  String recipeId, {
  bool viewOnly = false,
  String? mealPlanDishId,
  DateTime? cookedAt,
}) {
  final path = AppRoutes.recipeDetail.replaceFirst(':id', recipeId);
  final query = <String, String>{
    if (viewOnly) 'mode': 'view',
    if (mealPlanDishId != null) 'dishId': mealPlanDishId,
    if (cookedAt != null) 'cookedAt': cookedAt.toUtc().toIso8601String(),
  };
  return query.isEmpty ? path : Uri(path: path, queryParameters: query).toString();
}

class RecipeListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RecipeStore>()) {
      Get.put<RecipeStore>(RecipeStore(Get.find<RecipeCatalogApi>()));
    }
  }
}

class RecipeDetailBinding extends Bindings {
  @override
  void dependencies() {
    final recipeId = Get.parameters['id'];
    if (recipeId == null || recipeId.isEmpty) return;
    Get.lazyPut<RecipeDetailStore>(
      () => RecipeDetailStore(recipeId, Get.find<RecipeCatalogApi>()),
      tag: recipeId,
    );
  }
}

final List<GetPage<dynamic>> recipePages = <GetPage<dynamic>>[
  GetPage<void>(
    name: AppRoutes.recipes,
    page: () => const RecipeListScene(),
    binding: RecipeListBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: AppRoutes.recipeDetail,
    page: () => RecipeDetailScene(
      recipeId: Get.parameters['id']!,
      viewOnly: Get.parameters['mode'] == 'view',
      mealPlanDishId: Get.parameters['dishId'],
      cookedAt: DateTime.tryParse(Get.parameters['cookedAt'] ?? ''),
    ),
    binding: RecipeDetailBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
