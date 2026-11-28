import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../stores/session_store.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_loading_view.dart';
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
  /// Store reset ô tìm khi đổi household (OD-33) — ô nhập phải theo, không
  /// thì vẫn hiện chữ cũ trong khi danh sách không lọc.
  final TextEditingController _search = TextEditingController();
  ReactionDisposer? _searchSync;

  @override
  void initState() {
    super.initState();
    final store = Get.find<InventoryStore>();
    _search.text = store.searchQuery;
    _searchSync = reaction<String>((_) => store.searchQuery, (q) {
      if (_search.text != q) _search.text = q;
    });
    store.init();
  }

  @override
  void dispose() {
    _searchSync?.call();
    _search.dispose();
    super.dispose();
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Overview Stats Banner + Search & Filter
          // #93 F7 (app-performance-audit §7.5): tách Observer — banner chỉ
          // đọc số đếm (Computed), ô tìm kiếm nằm NGOÀI mọi Observer, chip
          // chỉ đọc knownCategories/selectedCategory.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.md,
              AppDimens.sm,
              AppDimens.md,
              0,
            ),
            child: Column(
              children: <Widget>[
                Observer(
                  builder: (_) {
                    final items = store.items;
                    if (items.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(AppDimens.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusCard),
                            border:
                                Border.all(color: AppColors.border, width: 1),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              _StatItem(
                                label: context.l10n.inventoryStatTotal,
                                value: '${items.length}',
                                icon: Icons.inventory_2_outlined,
                                color: AppColors.primary,
                                selected: store.statusFilter ==
                                    InventoryStatusFilter.all,
                                onTap: () => store.toggleStatusFilter(
                                    InventoryStatusFilter.all),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: AppColors.border,
                              ),
                              _StatItem(
                                label: context.l10n.inventoryStatExpiring,
                                value: '${store.expiringCount}',
                                icon: Icons.access_time_rounded,
                                color: store.expiringCount > 0
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                                selected: store.statusFilter ==
                                    InventoryStatusFilter.expiring,
                                onTap: () => store.toggleStatusFilter(
                                    InventoryStatusFilter.expiring),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: AppColors.border,
                              ),
                              _StatItem(
                                label: context.l10n.inventoryStatLowStock,
                                value: '${store.lowStockCount}',
                                icon: Icons.trending_down_rounded,
                                color: store.lowStockCount > 0
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                selected: store.statusFilter ==
                                    InventoryStatusFilter.lowStock,
                                onTap: () => store.toggleStatusFilter(
                                    InventoryStatusFilter.lowStock),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.sm),
                      ],
                    );
                  },
                ),

                // Search TextField
                TextField(
                  key: const ValueKey<String>('inventory-search'),
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: context.l10n.inventorySearchHint,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppDimens.sm,
                      horizontal: AppDimens.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: store.setSearchQuery,
                ),
                const SizedBox(height: AppDimens.sm),

                // Category Filter Pills
                Observer(
                  builder: (_) => SizedBox(
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
                ),
              ],
            ),
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
                      store.selectedCategory != null ||
                      store.statusFilter != InventoryStatusFilter.all;
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
                          expanded: false,
                          onPressed: () => Get.toNamed('/inventory/add'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'inventory-list-fab',
        tooltip: context.l10n.inventoryAddItem,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => Get.toNamed('/inventory/add'),
        child: const Icon(Icons.add_rounded),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Bộ lọc của ô này đang bật → nền nhạt để người dùng biết danh sách đã lọc.
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primaryShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
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
