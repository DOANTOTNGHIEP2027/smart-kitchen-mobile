import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../data/network/api_exception.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/quantity_format.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/inputs/chip_choice_group.dart';
import '../../inventory/domain/unit_option.dart';
import '../domain/shopping_item.dart';
import '../stores/shopping_store.dart';

enum _ItemAction { edit, delete }

/// Nút `⋮` của 1 món đi chợ: sửa (chỉ món chưa mua) / xoá — cho trường hợp
/// thêm nhầm. Online-only, không optimistic (xem [ShoppingStore.edit]).
Future<void> openShoppingItemActions(
  BuildContext context,
  ShoppingStore store,
  ShoppingItem item,
) async {
  final canEdit = item.status == ShoppingItemStatus.pending;
  final action = await showModalBottomSheet<_ItemAction>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (canEdit)
            ListTile(
              key: const ValueKey<String>('shopping-item-action-edit'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(sheetCtx.l10n.shoppingEditItem),
              onTap: () => Navigator.of(sheetCtx).pop(_ItemAction.edit),
            ),
          ListTile(
            key: const ValueKey<String>('shopping-item-action-delete'),
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            title: Text(
              sheetCtx.l10n.shoppingDeleteItem,
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () => Navigator.of(sheetCtx).pop(_ItemAction.delete),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _ItemAction.edit:
      await _edit(context, store, item);
    case _ItemAction.delete:
      await _delete(context, store, item);
  }
}

Future<void> _delete(
  BuildContext context,
  ShoppingStore store,
  ShoppingItem item,
) async {
  final ok = await showConfirmDialog(
    context,
    title: context.l10n.shoppingDeleteConfirmTitle,
    message: context.l10n.shoppingDeleteConfirmMessage(item.name),
    confirmLabel: context.l10n.delete,
    isDestructive: true,
  );
  if (!ok || !context.mounted) return;
  final error = await store.remove(item);
  if (!context.mounted) return;
  _report(
    context,
    error,
    success: context.l10n.shoppingItemDeleted(item.name),
  );
}

Future<void> _edit(
  BuildContext context,
  ShoppingStore store,
  ShoppingItem item,
) async {
  final name = TextEditingController(text: item.name);
  final quantity = TextEditingController(text: formatQuantity(item.quantity));
  var unit = item.unit;
  final units = <ChipChoiceOption<String>>[
    for (final o in unitOptions) ChipChoiceOption<String>(o.value, o.label, o.value),
    // Đơn vị ngoài danh sách chuẩn (vd. từ hoá đơn) vẫn phải chọn lại được.
    if (!unitOptions.any((o) => o.value == item.unit))
      ChipChoiceOption<String>(item.unit, item.unit, item.unit),
  ];
  String? nameError;
  String? quantityError;
  var saving = false;

  final error = await showModalBottomSheet<ApiException?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setModalState) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.lg,
          AppDimens.lg,
          AppDimens.lg,
          MediaQuery.viewInsetsOf(ctx).bottom + AppDimens.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              ctx.l10n.shoppingEditSheetTitle,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppDimens.md),
            TextField(
              key: const ValueKey<String>('shopping-edit-name'),
              controller: name,
              decoration: InputDecoration(
                labelText: ctx.l10n.shoppingNameLabel,
                errorText: nameError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            TextField(
              key: const ValueKey<String>('shopping-edit-quantity'),
              controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: ctx.l10n.shoppingQuantityLabel,
                errorText: quantityError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            ChipChoiceGroup<String>(
              groupKey: 'edit-unit',
              title: ctx.l10n.shoppingUnitLabel,
              value: unit,
              allowDeselect: false,
              options: units,
              onChanged: (v) {
                if (v != null) setModalState(() => unit = v);
              },
            ),
            const SizedBox(height: AppDimens.lg),
            FilledButton(
              key: const ValueKey<String>('shopping-edit-save'),
              onPressed: saving
                  ? null
                  : () async {
                      final text = name.text.trim();
                      final qty =
                          double.tryParse(quantity.text.trim().replaceAll(',', '.'));
                      setModalState(() {
                        nameError =
                            text.isEmpty ? ctx.l10n.shoppingNameRequired : null;
                        quantityError = qty == null || qty <= 0
                            ? ctx.l10n.shoppingQuantityInvalid
                            : null;
                      });
                      if (nameError != null || quantityError != null) return;
                      setModalState(() => saving = true);
                      final result = await store.edit(item,
                          name: text, quantity: qty!, unit: unit);
                      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(result);
                    },
              child: Text(ctx.l10n.saveChanges),
            ),
          ],
        ),
      ),
    ),
  );
  name.dispose();
  quantity.dispose();
  // Đóng sheet bằng vuốt/back (không lưu) → không báo gì.
  if (!saving || !context.mounted) return;
  _report(context, error, success: context.l10n.shoppingItemUpdated);
}

void _report(BuildContext context, ApiException? error,
    {required String success}) {
  final l10n = context.l10n;
  final message = switch (error) {
    null => success,
    NetworkException() => l10n.shoppingItemActionOffline,
    _ when error.code == 'ERR_SHOP_ITEM_DELETE_FORBIDDEN' =>
      l10n.shoppingDeleteForbidden,
    _ when error.code == 'ERR_SHOP_ITEM_VERSION_CONFLICT' =>
      l10n.shoppingItemChangedElsewhere,
    _ => apiErrorMessage(l10n, error),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
