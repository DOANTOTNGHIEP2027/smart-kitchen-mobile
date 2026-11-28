import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../inventory/stores/inventory_store.dart';
import '../../recipe/data/recipe_catalog_api.dart';
import '../../recipe/domain/recipe.dart';
import '../../shopping/scenes/shopping_list_binding.dart';
import '../domain/inventory_shortfall.dart';
import '../domain/meal_suggestion.dart';
import '../domain/shopping_list_sink.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../utils/unit_label.dart';

/// Sau khi chọn món: còn thiếu nguyên liệu thì hỏi có đẩy sang Đi chợ không.
/// Không thiếu gì ⇒ không hiện popup.
Future<void> confirmAddMissingToShopping(
  BuildContext context, {
  required List<IngredientItem> missing,
  ShoppingListSink? sink,
}) async {
  if (missing.isEmpty) return;
  final l10n = context.l10n;
  final lines = missing
      .map((i) => '• ${i.name} — ${formatQuantityWithUnitLabel(l10n, i.quantity, i.unit)}')
      .join('\n');
  final ok = await showConfirmDialog(
    context,
    title: l10n.mealPlanMissingTitle,
    message: '${l10n.mealPlanMissingMessage}\n$lines',
    confirmLabel: l10n.mealplanAddShoppingList,
  );
  if (!ok) return;
  await addMissingToShopping(l10n, missing, sink: sink);
}

/// Lựa chọn khi món định chọn còn thiếu nguyên liệu (chọn món tay #201).
enum MissingIngredientsChoice { addWithShopping, addOnly, cancel }

/// Hỏi TRƯỚC khi gán món: "Thêm món + đi chợ" / "Chỉ thêm món" / "Huỷ".
/// Không thiếu gì ⇒ [MissingIngredientsChoice.addOnly] (không hiện popup).
/// Back/chạm ngoài = Huỷ.
Future<MissingIngredientsChoice> askMissingIngredientsChoice(
  BuildContext context, {
  required List<IngredientItem> missing,
}) async {
  if (missing.isEmpty) return MissingIngredientsChoice.addOnly;
  final l10n = context.l10n;
  final lines = missing
      .map((i) => '• ${i.name} — ${formatQuantityWithUnitLabel(l10n, i.quantity, i.unit)}')
      .join('\n');
  final choice = await showDialog<MissingIngredientsChoice>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      key: const ValueKey<String>('missing-choice-dialog'),
      title: Text(l10n.mealPlanMissingTitle),
      content: SingleChildScrollView(
        child: Text('${l10n.mealPlanMissingMessage}\n$lines'),
      ),
      actionsOverflowDirection: VerticalDirection.up,
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('missing-choice-cancel'),
          onPressed: () =>
              Navigator.of(dialogCtx).pop(MissingIngredientsChoice.cancel),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey<String>('missing-choice-add-only'),
          onPressed: () =>
              Navigator.of(dialogCtx).pop(MissingIngredientsChoice.addOnly),
          child: Text(l10n.mealPlanMissingAddOnly),
        ),
        FilledButton(
          key: const ValueKey<String>('missing-choice-add-shopping'),
          onPressed: () => Navigator.of(dialogCtx)
              .pop(MissingIngredientsChoice.addWithShopping),
          child: Text(l10n.mealPlanMissingAddWithShopping),
        ),
      ],
    ),
  );
  return choice ?? MissingIngredientsChoice.cancel;
}

/// Đẩy nguyên liệu thiếu sang Đi chợ + toast kết quả.
Future<void> addMissingToShopping(
  AppLocalizations l10n,
  List<IngredientItem> missing, {
  ShoppingListSink? sink,
}) async {
  if (missing.isEmpty) return;
  final count = await (sink ?? _shoppingSink()).addItems(missing);
  if (count > 0) {
    AppToast.show(l10n.mealPlanMissingAdded(count),
        type: AppToastType.success);
  } else {
    AppToast.show(l10n.mealplanShoppingListUnavailable,
        type: AppToastType.error);
  }
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
