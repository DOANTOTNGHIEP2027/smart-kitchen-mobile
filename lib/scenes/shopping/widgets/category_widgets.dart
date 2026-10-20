import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../domain/shopping_category.dart';
import '../stores/category_store.dart';

/// `null` khi chưa đăng ký (vd. test dựng scene không qua binding) — chip
/// category vẫn có bộ mặc định.
CategoryStore? shoppingCategoryStore() =>
    Get.isRegistered<CategoryStore>() ? Get.find<CategoryStore>() : null;

String categoryErrorText(AppLocalizations l10n, CategoryError error) => switch (error) {
      CategoryError.empty => l10n.shoppingCategoryErrEmpty,
      CategoryError.tooLong => l10n.shoppingCategoryErrTooLong(CategoryStore.maxNameLength),
      CategoryError.duplicate => l10n.shoppingCategoryErrDuplicate,
      CategoryError.saveFailed => l10n.shoppingCategoryErrSaveFailed,
    };

/// 1 dòng category: chấm màu + tên + tay kéo (§13).
class CategoryListTile extends StatelessWidget {
  const CategoryListTile({super.key, required this.category, required this.index, required this.onTap});

  final ShoppingCategory category;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: AppDimens.xs),
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(radius: 8, backgroundColor: categoryColor(category.colorHex)),
          title: Text(category.name),
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle_rounded, color: AppColors.textSecondary),
          ),
        ),
      );
}

/// Mở dialog thêm/sửa — xoá lỗi validate cũ TRƯỚC khi dựng (Fix LOW-1).
Future<void> showCategoryEditDialog(BuildContext context, CategoryStore store, {ShoppingCategory? category}) {
  store.clearError();
  return showDialog<void>(
    context: context,
    builder: (_) => CategoryEditDialog(store: store, category: category),
  );
}

class CategoryEditDialog extends StatefulWidget {
  const CategoryEditDialog({super.key, required this.store, this.category});

  final CategoryStore store;
  final ShoppingCategory? category;

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.category?.name ?? '');
  late String _color = widget.category?.colorHex ?? categoryColorPalette.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final c = widget.category;
    final ok = c == null
        ? await widget.store.addCategory(name: _name.text, colorHex: _color)
        : await widget.store.updateCategory(c.id, name: _name.text, colorHex: _color);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.category == null ? l10n.shoppingCategoryAdd : l10n.shoppingCategoryEdit),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Observer(
            builder: (_) {
              final error = widget.store.error;
              return TextField(
                key: const ValueKey<String>('category-name-field'),
                controller: _name,
                autofocus: true,
                maxLength: CategoryStore.maxNameLength,
                decoration: InputDecoration(
                  labelText: l10n.shoppingCategoryNameLabel,
                  errorText: error == null ? null : categoryErrorText(l10n, error),
                  counterText: '',
                ),
                onSubmitted: (_) => _save(),
              );
            },
          ),
          const SizedBox(height: AppDimens.sm),
          Text(l10n.shoppingCategoryColorLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimens.xs),
          Wrap(
            spacing: AppDimens.xs,
            runSpacing: AppDimens.xs,
            children: <Widget>[
              for (final hex in categoryColorPalette)
                InkWell(
                  key: ValueKey<String>('category-color-$hex'),
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: categoryColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hex == _color ? AppColors.textPrimary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.shoppingCategoryCancel)),
        FilledButton(
          key: const ValueKey<String>('category-save'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.shoppingCategorySave),
        ),
      ],
    );
  }
}

/// Xác nhận xoá (§9) — trả `true` để `Dismissible.confirmDismiss` xoá thật.
Future<bool> showCategoryDeleteConfirmDialog(BuildContext context, ShoppingCategory category) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(l10n.shoppingCategoryDeleteConfirm(category.name)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.shoppingCategoryCancel),
        ),
        TextButton(
          key: const ValueKey<String>('category-delete-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.shoppingCategoryDelete, style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
