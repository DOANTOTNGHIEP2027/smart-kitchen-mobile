import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/l10n_x.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../inventory/stores/inventory_store.dart';
import '../../recipe/data/recipe_catalog_api.dart';
import '../../recipe/domain/recipe.dart';
import '../../shopping/scenes/shopping_list_binding.dart';
import '../domain/inventory_shortfall.dart';
import '../domain/meal_plan_slot.dart';
import '../domain/meal_shopping_sync.dart';
import '../domain/meal_suggestion.dart';
import '../domain/slot_shopping_plan.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../utils/unit_label.dart';

/// "Hoàn thành thêm món" của 1 buổi: rà lại Đi chợ theo các món ĐANG có —
/// xoá dòng chưa mua của món đã bỏ / đổi công thức, đẩy đồ thiếu của món chưa
/// có dòng nào; hỏi xác nhận 1 lần. Trả `true` khi đi chợ đã khớp (caller đóng
/// màn), `false` khi huỷ hoặc không tải được danh sách (ở lại màn).
Future<bool> finishSlotShopping(
  BuildContext context, {
  required DateTime slotDate,
  required String mealTime,
  required List<MealPlanDish> dishes,
  MealShoppingSync? sync,
  Future<List<IngredientItem>> Function(String recipeId)? missingOf,
}) async {
  final l10n = context.l10n;
  // Toast nằm trên overlay — màn gọi đóng ngay sau đó vẫn hiện.
  void say(String text, {AppToastType type = AppToastType.success}) =>
      AppToast.show(text, type: type);

  final target = sync ?? _mealShoppingSync();
  final lines = await target.linesOfSlot(slotDate, mealTime);
  if (lines == null) {
    say(l10n.mealPlanFinishLoadFailed, type: AppToastType.error);
    return false;
  }
  final diff = diffSlotShopping(dishes, lines);
  final toAdd = <String, List<IngredientItem>>{};
  for (final dish in diff.uncoveredDishes) {
    final missing = await (missingOf ?? missingForRecipe)(dish.recipe!.recipeId);
    if (missing.isNotEmpty) toAdd[dish.id] = missing;
  }
  if (toAdd.isEmpty && diff.staleLines.isEmpty) {
    say(l10n.mealPlanFinishInSync);
    return true;
  }
  if (!context.mounted) return false;
  String line(String name, double qty, String unit) =>
      '• $name — ${formatQuantityWithUnitLabel(l10n, qty, unit)}';
  final message = <String>[
    if (toAdd.isNotEmpty) ...<String>[
      l10n.mealPlanFinishAddHeader,
      for (final items in toAdd.values)
        for (final i in items) line(i.name, i.quantity, i.unit),
    ],
    if (diff.staleLines.isNotEmpty) ...<String>[
      if (toAdd.isNotEmpty) '',
      l10n.mealPlanFinishRemoveHeader,
      for (final l in diff.staleLines) line(l.name, l.quantity, l.unit),
    ],
  ].join('\n');
  final ok = await showConfirmDialog(
    context,
    title: l10n.mealPlanFinishTitle,
    message: message,
    confirmLabel: l10n.mealPlanFinishConfirm,
  );
  if (!ok) return false;
  final removed = diff.staleLines.isEmpty
      ? 0
      : await target.remove(<String>[for (final l in diff.staleLines) l.id]);
  var added = 0;
  for (final entry in toAdd.entries) {
    added += await target.addForDish(entry.key, entry.value);
  }
  say(l10n.mealPlanFinishDone(added, removed));
  return true;
}

/// Nguyên liệu thiếu của công thức chọn thủ công. Ưu tiên [fromServer]
/// (`missingIngredients` BE trả khi gán tay, đã quy đổi đơn vị chuẩn); BE
/// không trả thì tự so với kho. Không kiểm được (chưa có store/API, lỗi mạng)
/// ⇒ rỗng: chỉ là nhắc đi chợ, không được chặn việc chọn món.
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

MealShoppingSync _mealShoppingSync() {
  ShoppingListBinding().dependencies();
  return Get.find<MealShoppingSync>();
}
