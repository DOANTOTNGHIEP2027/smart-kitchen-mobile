import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/app_scaffold.dart';
import '../../inventory/domain/unit_option.dart';
import '../domain/shopping_item.dart';
import '../stores/shopping_store.dart';
import '../widgets/price_capture_sheet.dart';

enum ShoppingFilter { all, pending, completed }

/// Màn hình danh sách mua sắm — phong cách Tasty:
/// Sáng sủa, mềm mại, thoáng, solid-color cards với subtle shadow,
/// typography rõ ràng, phân vùng Cần mua / Đã mua, accent sage-green.
class ShoppingListScene extends StatefulWidget {
  const ShoppingListScene({super.key});

  @override
  State<ShoppingListScene> createState() => _ShoppingListSceneState();
}

class _ShoppingListSceneState extends State<ShoppingListScene> {
  ShoppingFilter _filter = ShoppingFilter.all;
  bool _completedExpanded = true;

  @override
  void initState() {
    super.initState();
    Get.find<ShoppingStore>().init();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ShoppingStore>();
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.l10n.navShopping,
      actions: <Widget>[
        IconButton(
          tooltip: context.l10n.refresh,
          onPressed: store.sync,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Column(
        children: <Widget>[
          // #55: thao tác thêm bị server từ chối vì cùng key nhưng khác nội
          // dung (offline-sync-contract.md §5) — báo người dùng.
          Observer(
            builder: (_) => store.error?.code == 'ERR_IDEMPOTENCY_KEY_REUSED'
                ? Material(
                    color: Colors.amber.shade100,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.md,
                        vertical: AppDimens.sm,
                      ),
                      child: Text(context.l10n.syncIdempotencyKeyReused),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // AM-TB-4 (§12): toggle mang giá bị từ chối vì món đã đổi ở nơi khác
          // — giá người dùng nhập đã mất, không được im lặng.
          Observer(
            builder: (_) => store.priceNotSaved
                ? Material(
                    key: const ValueKey<String>('shopping-price-not-saved'),
                    color: Colors.amber.shade100,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.md,
                        vertical: AppDimens.sm,
                      ),
                      child: Text(context.l10n.shoppingPriceNotSaved),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(child: Observer(
        builder: (_) {
          if (store.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allItems = store.items;
          final pendingItems = store.pending;
          final completedItems = store.completed;

          if (allItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.sageLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_basket_outlined,
                        size: 40,
                        color: AppColors.sage,
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),
                    Text(
                      context.l10n.shoppingEmptyTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      context.l10n.shoppingEmptyBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sage,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.lg,
                          vertical: AppDimens.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      onPressed: () => _showAddDialog(context, store),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.l10n.shoppingAddNeeded),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredItems = switch (_filter) {
            ShoppingFilter.all => allItems,
            ShoppingFilter.pending => pendingItems,
            ShoppingFilter.completed => completedItems,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.md,
              AppDimens.sm,
              AppDimens.md,
              AppDimens.xxl,
            ),
            children: <Widget>[
              // Summary card
              _buildSummaryCard(
                context,
                pendingItems.length,
                completedItems.length,
              ),
              const SizedBox(height: AppDimens.md),

              // Filter pills
              _buildFilterBar(
                context,
                pendingItems.length,
                completedItems.length,
              ),
              const SizedBox(height: AppDimens.md),

              // Section views
              if (_filter == ShoppingFilter.all) ...<Widget>[
                if (pendingItems.isNotEmpty) ...<Widget>[
                  _buildSectionHeader(
                    context,
                    context.l10n.shoppingPendingCount(pendingItems.length),
                    Icons.radio_button_unchecked_rounded,
                  ),
                  const SizedBox(height: AppDimens.xs),
                  ...pendingItems.map((item) =>
                      _buildItemTile(context, item, false, store)),
                ],
                if (completedItems.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppDimens.md),
                  InkWell(
                    onTap: () => setState(
                        () => _completedExpanded = !_completedExpanded),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppDimens.xs),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _completedExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimens.xs),
                          Text(
                            context.l10n.shoppingCompletedCount(
                                completedItems.length),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_completedExpanded) ...<Widget>[
                    const SizedBox(height: AppDimens.xs),
                    ...completedItems.map((item) =>
                        _buildItemTile(context, item, true, store)),
                  ],
                ],
              ] else ...<Widget>[
                if (filteredItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.xl),
                    child: Center(
                      child: Text(
                        _filter == ShoppingFilter.pending
                            ? context.l10n.shoppingAllBought
                            : context.l10n.shoppingNoneBought,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredItems.map(
                    (item) => _buildItemTile(
                      context,
                      item,
                      item.status == ShoppingItemStatus.completed,
                      store,
                    ),
                  ),
              ],
            ],
          );
        },
      )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'shopping-list-fab',
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _showAddDialog(context, store),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          context.l10n.shoppingAddItem,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int pendingCount,
    int completedCount,
  ) {
    final theme = Theme.of(context);
    final total = pendingCount + completedCount;
    final percent = total == 0 ? 0 : (completedCount / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.shoppingProgressTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.shoppingProgressDetail(
                        completedCount, total, percent),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Text(
                  context.l10n.shoppingPendingBadge(pendingCount),
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completedCount / total,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    int pendingCount,
    int completedCount,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _FilterChip(
            label: context.l10n
                .shoppingFilterAll(pendingCount + completedCount),
            isSelected: _filter == ShoppingFilter.all,
            onTap: () => setState(() => _filter = ShoppingFilter.all),
          ),
          const SizedBox(width: AppDimens.xs),
          _FilterChip(
            label: context.l10n.shoppingPendingCount(pendingCount),
            isSelected: _filter == ShoppingFilter.pending,
            onTap: () => setState(() => _filter = ShoppingFilter.pending),
          ),
          const SizedBox(width: AppDimens.xs),
          _FilterChip(
            label: context.l10n.shoppingCompletedCount(completedCount),
            isSelected: _filter == ShoppingFilter.completed,
            onTap: () => setState(() => _filter = ShoppingFilter.completed),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppDimens.xs),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    ShoppingItem item,
    bool isCompleted,
    ShoppingStore store,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: InkWell(
          onTap: item.canToggle
              ? () => toggleShoppingItemWithPrice(context, store, item)
              : null,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.sm,
            ),
            child: Row(
              children: <Widget>[
                // Rounded Custom Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.sage : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? AppColors.sage : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: AppDimens.md),

                // Name & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          if (item.category != null)
                            Text(
                              item.category!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          if (item.source == ShoppingItemSource.auto)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sageLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.l10n.shoppingWeeklyMenuBadge,
                                style: const TextStyle(
                                  color: AppColors.sage,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Có giá thì hiện; không giá thì KHÔNG nhắc gì (§9.4).
                          if (isCompleted && item.price != null)
                            Text(
                              formatVnd(item.price!),
                              key: ValueKey<String>('shopping-price-${item.id}'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.sageDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (item.isPendingSync)
                            const Icon(
                              Icons.sync_rounded,
                              size: 13,
                              color: AppColors.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quantity badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.background
                        : AppColors.sageLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Text(
                    '${_formatQty(item.displayQuantity)} ${item.displayUnit}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isCompleted
                          ? AppColors.textSecondary
                          : AppColors.sageDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }

  Future<void> _showAddDialog(BuildContext context, ShoppingStore store) async {
    final name = TextEditingController();
    final quantity = TextEditingController(text: '1');
    String unit = unitOptions.first.value;
    String? category;

    final categories = <String>[
      'Rau củ',
      'Thịt cá',
      'Gia vị',
      'Trứng sữa',
      'Thực phẩm khô',
      'Đồ uống',
      'Khác',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.lg,
            AppDimens.lg,
            AppDimens.lg,
            MediaQuery.of(context).viewInsets.bottom + AppDimens.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                context.l10n.shoppingAddSheetTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppDimens.md),
              TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.shoppingNameHint,
                  labelText: context.l10n.shoppingNameLabel,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantity,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '1',
                        labelText: context.l10n.shoppingQuantityLabel,
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: unit,
                      decoration: InputDecoration(
                        labelText: context.l10n.shoppingUnitLabel,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      items: unitOptions
                          .map(
                            (o) => DropdownMenuItem(
                              value: o.value,
                              child: Text(o.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => unit = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                context.l10n.shoppingCategoryLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final selected = category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: AppColors.sageLight,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.sageDark
                              : AppColors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setModalState(() => category = val ? cat : null);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                onPressed: () async {
                  final text = name.text.trim();
                  if (text.isEmpty) return;
                  final qty = double.tryParse(quantity.text) ?? 1.0;
                  await store.add(text, qty, unit, category: category);
                  if (context.mounted) Navigator.pop(bottomSheetContext);
                },
                child: Text(
                  context.l10n.shoppingAddToList,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.sage : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(
              color: isSelected ? AppColors.sage : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
