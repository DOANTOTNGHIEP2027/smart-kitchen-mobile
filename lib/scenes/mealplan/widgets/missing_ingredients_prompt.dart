import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/l10n_x.dart';
import '../../../utils/quantity_format.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../inventory/stores/inventory_store.dart';
import '../../recipe/data/recipe_catalog_api.dart';
import '../../recipe/domain/recipe.dart';
import '../../shopping/scenes/shopping_list_binding.dart';
import '../domain/inventory_shortfall.dart';
import '../domain/meal_suggestion.dart';
import '../domain/shopping_list_sink.dart';

/// Sau khi chọn món: còn thiếu nguyên liệu thì hỏi có đẩy sang Đi chợ không.
/// Không thiếu gì ⇒ không hiện popup.
Future<void> confirmAddMissingToShopping(
  BuildContext context, {
  required List<IngredientItem> missing,
  ShoppingListSink? sink,
}) async {
  if (missing.isEmpty) return;
  final l10n = context.l10n;
  // Lấy trước khi await: màn gọi có thể đóng ngay sau popup.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final lines = missing
      .map((i) => '• ${i.name} — ${formatQuantityWithUnit(i.quantity, i.unit)}')
      .join('\n');
  final ok = await showConfirmDialog(
    context,
    title: l10n.mealPlanMissingTitle,
    message: '${l10n.mealPlanMissingMessage}\n$lines',
    confirmLabel: l10n.mealplanAddShoppingList,
  );
  if (!ok) return;
  final count = await (sink ?? _shoppingSink()).addItems(missing);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(count > 0
          ? l10n.mealPlanMissingAdded(count)
          : l10n.mealplanShoppingListUnavailable),
    ));
}

/// Nguyên liệu thiếu của công thức chọn thủ công. Ưu tiên [fromServer]
/// (`missingIngredients` BE trả khi gán tay, đã quy đổi đơn vị chuẩn); BE
/// không trả thì tự so với kho. Không kiểm được (chưa có store/API, lỗi mạng)
/// ⇒ rỗng: popup chỉ là nhắc, không được chặn việc chọn món.
Future<List<IngredientItem>> missingForRecipe(
  String recipeId, {
  List<IngredientItem>? fromServer,
}) async {
  if (fromServer != null) return fromServer;
  if (!Get.isRegistered<RecipeCatalogApi>() ||
      !Get.isRegistered<InventoryStore>()) {
    return const <IngredientItem>[];
  }
  try {
    final recipe = await Get.find<RecipeCatalogApi>().getById(recipeId);
    return inventoryShortfall(
      recipe.ingredients ?? const <RecipeIngredient>[],
      Get.find<InventoryStore>().items,
    );
  } catch (error) {
    developer.log('Không kiểm tra được nguyên liệu thiếu: $error',
        name: 'MealPlan');
    return const <IngredientItem>[];
  }
}

ShoppingListSink _shoppingSink() {
  ShoppingListBinding().dependencies();
  return Get.find<ShoppingListSink>();
}
