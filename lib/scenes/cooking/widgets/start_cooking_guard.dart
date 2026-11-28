import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../data/network/dio_client.dart';
import '../../../routing/app_routes.dart';
import '../../../stores/session_store.dart';
import '../../../utils/l10n_x.dart';
import '../../recipe/data/recipe_catalog_api.dart';
import '../../recipe/domain/recipe.dart';
import '../../shopping/data/shopping_api.dart';
import '../../shopping/domain/shopping_item.dart';
import '../domain/pending_ingredient_matcher.dart';
import '../scenes/cooking_routes.dart';
import 'dish_cooked_dialog.dart';

/// Trước khi vào màn nấu: nếu nguyên liệu của món còn nằm trong danh sách đi
/// chợ chưa mua, hiện popup cho chọn "Vẫn nấu" hoặc sang Đi chợ để phân công.
///
/// Không kiểm tra được (offline, lỗi mạng, chưa có nhà) thì vào nấu luôn —
/// popup chỉ là nhắc nhở, không được chặn người dùng nấu.
///
/// Dùng `Get.dialog` (không cần `BuildContext`) vì chỗ gọi thường vừa đóng
/// bottom sheet của chính nó.
///
/// Nấu từ 1 món thực đơn: truyền [mealPlanDishId] để server gắn phiên với món;
/// món đã nấu xong ([cookedAt] khác null) ⇒ chỉ báo "Món đã nấu xong", không
/// mở màn nấu.
Future<void> startCookingWithShoppingCheck(
  String recipeId, {
  String? mealPlanDishId,
  DateTime? cookedAt,
}) async {
  if (cookedAt != null) {
    await showDishCookedDialog(cookedAt: cookedAt);
    return;
  }
  final pending = await _findPendingItems(recipeId);
  if (pending.isEmpty) {
    _goCooking(recipeId, mealPlanDishId);
    return;
  }
  final choice = await Get.dialog<_PendingChoice>(
    PendingShoppingDialog(items: pending),
  );
  switch (choice) {
    case _PendingChoice.cookAnyway:
      _goCooking(recipeId, mealPlanDishId);
    case _PendingChoice.goShopping:
      Get.toNamed<void>(AppRoutes.shopping);
    case null:
      break;
  }
}

void _goCooking(String recipeId, String? mealPlanDishId) {
  Get.toNamed<void>(
    CookingRoutes.session,
    arguments: CookingArgs.start(recipeId, mealPlanDishId: mealPlanDishId),
  );
}

Future<List<ShoppingItem>> _findPendingItems(String recipeId) async {
  try {
    final householdId = Get.find<SessionStore>().householdId;
    if (householdId == null || !Get.isRegistered<RecipeCatalogApi>()) {
      return const <ShoppingItem>[];
    }
    if (!Get.isRegistered<ShoppingApi>()) {
      Get.put<ShoppingApi>(
        ShoppingApiImpl(Get.find<DioClient>()),
        permanent: true,
      );
    }
    final (recipe, items) = await (
      Get.find<RecipeCatalogApi>().getById(recipeId),
      Get.find<ShoppingApi>().list(householdId),
    ).wait;
    return pendingItemsForIngredients(
      (recipe.ingredients ?? const <RecipeIngredient>[]).map((i) => i.name),
      items,
    );
  } catch (error) {
    developer.log('Không kiểm tra được đồ chưa mua: $error', name: 'Cooking');
    return const <ShoppingItem>[];
  }
}

enum _PendingChoice { cookAnyway, goShopping }

class PendingShoppingDialog extends StatelessWidget {
  const PendingShoppingDialog({super.key, required this.items});

  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.cookingPendingShoppingTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.cookingPendingShoppingMessage(items.length)),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    const Text('• '),
                    Expanded(child: Text(item.name)),
                    if (item.assignedTo == null)
                      Text(
                        l10n.cookingPendingShoppingUnassigned,
                        style: const TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(_PendingChoice.cookAnyway),
          child: Text(l10n.cookingPendingShoppingCookAnyway),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_PendingChoice.goShopping),
          child: Text(l10n.cookingPendingShoppingGoShopping),
        ),
      ],
    );
  }
}
