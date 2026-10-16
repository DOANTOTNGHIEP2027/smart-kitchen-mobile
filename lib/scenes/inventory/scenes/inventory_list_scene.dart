import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../stores/session_store.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../inventory_routes.dart';
import '../stores/inventory_store.dart';
import '../widgets/inventory_item_tile.dart';

/// Danh sách kho thực phẩm — phong cách Tasty:
/// Sáng sủa, hiện đại, banner thống kê trực quan, tìm kiếm & bộ lọc nhanh.
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
          tooltip: context.l10n.inventoryOcrScanAction,
          icon: const Icon(Icons.document_scanner_outlined),
          onPressed: () => Get.toNamed(InventoryRoutes.scan),
        ),
        IconButton(
          tooltip: context.l10n.add,
          icon: const Icon(Icons.add_rounded),
          onPressed: () => Get.toNamed('/inventory/add'),
        ),
      ],
      body: Column(
        children: <Widget>[
          // Sync banner
          Observer(
            builder: (_) {
              if (store.syncError != null) {
                return Material(
                  color: Colors.amber.shade100,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            store.syncError!.code ==
                                    'ERR_IDEMPOTENCY_KEY_REUSED'
                                ? context.l10n.syncIdempotencyKeyReused
                                : context.l10n.inventorySyncFailed,
                          ),
                        ),
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
                return const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.sage),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Overview Stats Banner + Search & Filter
          Observer(
            builder: (_) {
              final allItems = store.items;
              final expiringCount =
                  allItems.where((i) => i.isExpiringSoon).length;
              final lowStockCount =
                  allItems.where((i) => i.isLowStock).length;

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.md,
                  AppDimens.sm,
                  AppDimens.md,
                  0,
                ),
                child: Column(
                  children: <Widget>[
                    if (allItems.isNotEmpty) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(AppDimens.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            _StatItem(
                              label: 'Tổng mặt hàng',
                              value: '${allItems.length}',
                              icon: Icons.inventory_2_outlined,
                              color: AppColors.sage,
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.border,
                            ),
                            _StatItem(
                              label: 'Sắp hết hạn',
                              value: '$expiringCount',
                              icon: Icons.access_time_rounded,
                              color: expiringCount > 0
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.border,
                            ),
                            _StatItem(
                              label: 'Sắp hết hàng',
                              value: '$lowStockCount',
                              icon: Icons.trending_down_rounded,
                              color: lowStockCount > 0
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.sm),
                    ],

                    // Search TextField
                    TextField(
                      decoration: InputDecoration(
                        hintText: context.l10n.inventorySearchHint,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppDimens.sm,
                          horizontal: AppDimens.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusXl),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: store.setSearchQuery,
                    ),
                    const SizedBox(height: AppDimens.sm),

                    // Category Filter Pills
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          _CategoryPill(
                            label: context.l10n.all,
                            selected: store.selectedCategory == null,
                            onTap: () => store.setCategory(null),
                          ),
                          ...store.knownCategories.map(
                            (c) => _CategoryPill(
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
              );
            },
          ),
          const SizedBox(height: AppDimens.sm),

          // Items List
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
                  final isEmptyDueToFilters = store.searchQuery.isNotEmpty ||
                      store.selectedCategory != null;
                  if (isEmptyDueToFilters) {
                    return AppEmptyView(
                      icon: Icons.search_off_rounded,
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
                        const SizedBox(height: AppDimens.sm),
                        AppButton(
                          label: context.l10n.inventoryAddItem,
                          icon: Icons.add,
                          onPressed: () => Get.toNamed('/inventory/add'),
                        ),
                        const SizedBox(height: AppDimens.sm),
                        AppButton(
                          label: context.l10n.inventoryOcrScanAction,
                          icon: Icons.document_scanner_outlined,
                          variant: AppButtonVariant.outline,
                          onPressed: () => Get.toNamed(InventoryRoutes.scan),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.sage,
                  onRefresh: () => store.syncFromServer(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: AppDimens.xxl,
                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory-list-fab',
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => Get.toNamed('/inventory/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm món',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
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
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppColors.sage : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              border: Border.all(
                color: selected ? AppColors.sage : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
