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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: AppDimens.sm),
                decoration: BoxDecoration(
                  color: _categoryColor(item.category),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(_categoryIcon(item.category),
                    color: AppColors.primaryDark, size: 21),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(item.name,
                              style: theme.textTheme.titleMedium),
                        ),
                        Text('$displayQty $displayUnitStr',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: AppDimens.xs),
                    if (item.category != null) ...<Widget>[
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
              const SizedBox(width: AppDimens.xs),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Rau củ':
        return AppColors.success.withValues(alpha: 0.12);
      case 'Thịt cá':
        return AppColors.primaryLight;
      default:
        return AppColors.secondaryFill;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Rau củ':
        return Icons.eco_outlined;
      case 'Thịt cá':
        return Icons.set_meal_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
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
