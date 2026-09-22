import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../stores/inventory_store.dart';
import '../widgets/inventory_item_tile.dart';

/// Danh sách inventory — offline-first (FE-5 §14 `InventoryListScene`).
///
/// 4 trạng thái dùng `InventoryStore.status` + `InventoryStore.filteredItems`:
/// - loading: `AppLoadingView` (chỉ lần đầu khi chưa có snapshot Drift).
/// - empty (chưa từng có item): banner + nút "Thêm mặt hàng".
/// - empty (do search/filter): thông báo không CTA.
/// - success: list `InventoryItemTile`.
///
/// `syncError`/`isSyncing` là banner không chặn (FE-5 §9.1 Decision D13).
class InventoryListScene extends StatefulWidget {
  const InventoryListScene({super.key});

  @override
  State<InventoryListScene> createState() => _InventoryListSceneState();
}

class _InventoryListSceneState extends State<InventoryListScene> {
  @override
  void initState() {
    super.initState();
    final store = Get.find<InventoryStore>();
    store.init();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<InventoryStore>();
    final session = Get.find<SessionStore>();
    return AppScaffold(
      title: context.l10n.inventoryTitle,
      actions: <Widget>[
        IconButton(
          tooltip: context.l10n.add,
          icon: const Icon(Icons.add),
          onPressed: () => Get.toNamed('/inventory/add'),
        ),
      ],
      body: Column(
        children: <Widget>[
          // Sync banner (không chặn — §9.1)
          Observer(builder: (_) {
            if (store.syncError != null) {
              return Material(
                color: Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(context.l10n.inventorySyncFailed)),
                      TextButton(
                        onPressed: () => store.syncFromServer(),
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (store.isSyncing) {
              return LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              );
            }
            return const SizedBox.shrink();
          }),
          // Search box + category chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Observer(
              builder: (_) => Column(
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                      hintText: context.l10n.inventorySearchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: store.setSearchQuery,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _CategoryChip(
                          label: context.l10n.all,
                          selected: store.selectedCategory == null,
                          onTap: () => store.setCategory(null),
                        ),
                        ...store.knownCategories.map(
                          (c) => _CategoryChip(
                            label: c,
                            selected: store.selectedCategory == c,
                            onTap: () => store.setCategory(c),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Body theo trạng thái
          Expanded(
            child: Observer(
              builder: (_) {
                if (store.householdId == null) {
                  return AppEmptyView(
                    icon: Icons.home_outlined,
                    message: context.l10n.inventoryNoHousehold,
                  );
                }
                if (store.status == InventoryLoadStatus.loading) {
                  return const AppLoadingView();
                }
                final filtered = store.filteredItems;
                if (filtered.isEmpty) {
                  // Phân biệt 2 loại empty (FE-5 §14)
                  final isEmptyDueToFilters =
                      store.searchQuery.isNotEmpty ||
                          store.selectedCategory != null;
                  if (isEmptyDueToFilters) {
                    return AppEmptyView(
                      icon: Icons.search_off,
                      message: context.l10n.inventoryNoResults,
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppEmptyView(
                          icon: Icons.kitchen_outlined,
                          message: context.l10n.inventoryEmpty,
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: context.l10n.inventoryAddItem,
                          icon: Icons.add,
                          onPressed: () => Get.toNamed('/inventory/add'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => store.syncFromServer(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppDimens.xxl),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return InventoryItemTile(
                        item: item,
                        onTap: () => Get.toNamed(
                          '/inventory/${item.id}/edit',
                          arguments: item,
                        ),
                        isCurrentUser:
                            item.createdBy == session.currentUser?.id,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/inventory/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
