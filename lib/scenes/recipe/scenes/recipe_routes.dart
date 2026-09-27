import 'package:get/get.dart';

import '../../../routing/app_routes.dart';
import '../../../routing/route_guards.dart';
import '../data/recipe_catalog_api.dart';
import '../stores/recipe_detail_store.dart';
import '../stores/recipe_store.dart';
import 'recipe_detail_scene.dart';
import 'recipe_list_scene.dart';

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
    page: () => RecipeDetailScene(recipeId: Get.parameters['id']!),
    binding: RecipeDetailBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
