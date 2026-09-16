import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../domain/inventory_item.dart';

/// Hiển thị một [InventoryItemModel] trong danh sách (FE-5 §14 InventoryItemTile).
///
/// Badge 4 trạng thái hiển thị song song:
/// - Đỏ "Sắp hết" khi [InventoryItemModel.isLowStock].
/// - Cam "HSD" khi [InventoryItemModel.isExpiringSoon].
/// - Vàng "Chưa đồng bộ" khi [InventoryItemModel.isPendingSync].
/// - Đỏ đậm "Xung đột" khi [InventoryItemModel.hasConflict].
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
    final displayQty = item.displayQuantity ?? item.quantity;
    final displayUnitStr = item.displayUnit ?? item.unit;
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppDimens.xs),
                    Text('$displayQty $displayUnitStr',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary)),
                    if (item.category != null) ...<Widget>[
                      const SizedBox(height: AppDimens.xs),
                      Text(item.category!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: AppDimens.sm),
                    Wrap(
                      spacing: AppDimens.xs,
                      runSpacing: AppDimens.xs,
                      children: <Widget>[
                        if (item.isLowStock)
                          const _Badge(
                              label: 'Sắp hết', color: AppColors.error),
                        if (item.isExpiringSoon)
                          const _Badge(
                              label: 'HSD sắp tới', color: AppColors.warning),
                        if (item.isPendingSync)
                          const _Badge(
                              label: 'Chưa đồng bộ',
                              color: AppColors.secondary),
                        if (item.hasConflict)
                          const _Badge(
                              label: 'Xung đột', color: AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
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
          horizontal: AppDimens.sm, vertical: AppDimens.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
