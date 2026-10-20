import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../stores/category_store.dart';
import '../widgets/category_widgets.dart';

/// Quản lý category đi chợ local-only (#69 §9). Chỉ mở được từ icon trên
/// `ShoppingListScene` — `CategoryStore` do `ShoppingListBinding` đăng ký (Guard #11).
class CategoryManagerScene extends StatelessWidget {
  const CategoryManagerScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<CategoryStore>();
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.shoppingCategoriesTitle,
      floatingActionButton: FloatingActionButton(
        heroTag: 'category-fab',
        tooltip: l10n.shoppingCategoryAdd,
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        onPressed: () => showCategoryEditDialog(context, store),
        child: const Icon(Icons.add),
      ),
      body: Observer(
        builder: (_) {
          if (store.isLoading) return const AppLoadingView();
          if (store.loadFailed) {
            return AppErrorView(
              message: l10n.shoppingCategoriesLoadFailed,
              onRetry: () => store.loadCategories(force: true),
            );
          }
          final categories = store.categories;
          if (categories.isEmpty) {
            return AppEmptyView(message: l10n.shoppingCategoriesEmpty, icon: Icons.label_outline_rounded);
          }
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDimens.md, AppDimens.md, AppDimens.md, 0),
                child: Text(l10n.shoppingCategoriesLocalNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ),
              Expanded(
                child: ReorderableListView(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.all(AppDimens.md),
                  // `onReorderItem` đã trừ sẵn vị trí của phần tử bị nhấc ra
                  // (thay `onReorder` + bước -1 của Guard #6 từ Flutter 3.41).
                  onReorderItem: (oldIndex, newIndex) => _reportFailure(
                      context,
                      store.reorderCategories(
                          reorderedIds(categories.map((c) => c.id).toList(), oldIndex, newIndex))),
                  children: <Widget>[
                    for (final (i, category) in categories.indexed)
                      Dismissible(
                        key: ValueKey<String>(category.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => showCategoryDeleteConfirmDialog(context, category),
                        onDismissed: (_) => _reportFailure(context, store.deleteCategory(category.id)),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: AppDimens.xs),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppDimens.lg),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        child: CategoryListTile(
                          category: category,
                          index: i,
                          onTap: () => showCategoryEditDialog(context, store, category: category),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Xoá/kéo thả không có dialog để hiện `store.error` — lỗi ghi phải báo bằng
  /// SnackBar, không im lặng (store đã trả list về snapshot cũ).
  static Future<void> _reportFailure(BuildContext context, Future<bool> write) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.shoppingCategoryErrSaveFailed;
    if (!await write) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Thứ tự id mới khi chuyển phần tử [oldIndex] tới [newIndex] (chỉ số SAU khi
/// đã nhấc phần tử ra — đúng quy ước của `onReorderItem`).
List<String> reorderedIds(List<String> ids, int oldIndex, int newIndex) {
  final result = List<String>.of(ids);
  result.insert(newIndex, result.removeAt(oldIndex));
  return result;
}
