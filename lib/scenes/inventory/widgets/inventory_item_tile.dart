import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/quantity_format.dart';
import '../domain/inventory_item.dart';
import 'food_category_visual.dart';
import 'inventory_presentation.dart';

/// Hiển thị một [InventoryItemModel] trong danh sách kho.
///
/// Thiết kế Tasty: Solid-color card, subtle shadow, góc bo tròn mềm mại,
/// icon phân loại thực phẩm sinh động, chỉ số hạn sử dụng rõ ràng.
class InventoryItemTile extends StatelessWidget {
  const InventoryItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.isCurrentUser = false,
  });

  final InventoryItemModel item;
  final VoidCallback onTap;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = foodCategoryVisual(context, item.category, item.name);
    final displayQty = item.displayQuantity ?? item.quantity;
    final displayUnitStr = item.displayUnit ?? item.unit;
    // #201: hết hàng (0) không phải "sắp hết".
    final lowStock = item.showsLowStock;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Category Icon Container
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: AppDimens.md),
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Icon(
                    visual.icon,
                    color: visual.color,
                    size: 24,
                  ),
                ),

                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              inventoryDisplayName(item.name),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: lowStock
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusPill),
                            ),
                            child: Text(
                              '${formatQuantity(displayQty)} $displayUnitStr',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: lowStock
                                    ? AppColors.error
                                    : AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: AppDimens.sm,
                        runSpacing: AppDimens.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          if (item.category != null) ...<Widget>[
                            Text(
                              inventoryDisplayName(item.category!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (item.expiryDate != null) ...<Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: item.isExpiringSoon
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _formatExpiry(item.expiryDate!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: item.isExpiringSoon
                                        ? AppColors.warning
                                        : AppColors.textSecondary,
                                    fontWeight: item.isExpiringSoon
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (lowStock ||
                          item.isExpiringSoon ||
                          item.isPendingSync ||
                          item.hasConflict) ...<Widget>[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppDimens.xs,
                          runSpacing: AppDimens.xs,
                          children: <Widget>[
                            if (lowStock)
                              _Badge(
                                label: context.l10n.inventoryLowStock,
                                color: AppColors.error,
                              ),
                            if (item.isExpiringSoon)
                              _Badge(
                                label: context.l10n.inventoryExpiringSoon,
                                color: AppColors.warning,
                              ),
                            if (item.isPendingSync)
                              _Badge(
                                label: context.l10n.inventoryPendingSync,
                                color: AppColors.secondary,
                              ),
                            if (item.hasConflict)
                              _Badge(
                                label: context.l10n.inventoryConflict,
                                color: AppColors.error,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatExpiry(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return 'HSD: $d/$m/${date.year}';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
