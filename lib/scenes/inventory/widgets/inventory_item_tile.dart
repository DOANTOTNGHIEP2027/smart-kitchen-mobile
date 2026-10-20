import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/quantity_format.dart';
import '../domain/inventory_item.dart';

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
    final displayQty = item.displayQuantity ?? item.quantity;
    final displayUnitStr = item.displayUnit ?? item.unit;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
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
                    color: _categoryBackgroundColor(item.category),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Icon(
                    _categoryIcon(item.category),
                    color: _categoryIconColor(item.category),
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
                              item.name,
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
                              color: item.isLowStock
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.sageLight,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: Text(
                              '${formatQuantity(displayQty)} $displayUnitStr',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: item.isLowStock
                                    ? AppColors.error
                                    : AppColors.sageDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          if (item.category != null) ...<Widget>[
                            Text(
                              item.category!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (item.expiryDate != null) ...<Widget>[
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
                        ],
                      ),
                      if (item.isLowStock ||
                          item.isExpiringSoon ||
                          item.isPendingSync ||
                          item.hasConflict) ...<Widget>[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppDimens.xs,
                          runSpacing: AppDimens.xs,
                          children: <Widget>[
                            if (item.isLowStock)
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

  Color _categoryBackgroundColor(String? category) {
    switch (category) {
      case 'Rau củ':
        return AppColors.sageLight;
      case 'Thịt cá':
        return const Color(0xFFFFECE5);
      case 'Trứng sữa':
        return const Color(0xFFFFF7E0);
      case 'Gia vị':
        return const Color(0xFFFFF0E6);
      case 'Đồ uống':
        return const Color(0xFFE8F4FD);
      case 'Thực phẩm khô':
      default:
        return AppColors.secondaryFill;
    }
  }

  Color _categoryIconColor(String? category) {
    switch (category) {
      case 'Rau củ':
        return AppColors.sage;
      case 'Thịt cá':
        return const Color(0xFFE85F2A);
      case 'Trứng sữa':
        return const Color(0xFFE5A100);
      case 'Gia vị':
        return const Color(0xFFD97706);
      case 'Đồ uống':
        return const Color(0xFF0284C7);
      case 'Thực phẩm khô':
      default:
        return const Color(0xFF78716C);
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Rau củ':
        return Icons.eco_rounded;
      case 'Thịt cá':
        return Icons.set_meal_rounded;
      case 'Trứng sữa':
        return Icons.egg_outlined;
      case 'Gia vị':
        return Icons.soup_kitchen_rounded;
      case 'Đồ uống':
        return Icons.local_cafe_rounded;
      case 'Thực phẩm khô':
        return Icons.grain_rounded;
      default:
        return Icons.kitchen_outlined;
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
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
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
