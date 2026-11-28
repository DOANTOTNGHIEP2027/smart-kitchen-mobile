import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/l10n_x.dart';

/// Nhãn "Đã nấu" trên món (hoặc "Đã nấu xong" cho cả bữa qua [label]).
class DishCookedBadge extends StatelessWidget {
  const DishCookedBadge({super.key, this.label, this.compact = false});

  /// `null` ⇒ "Đã nấu".
  final String? label;

  /// Cỡ nhỏ cho thẻ món trong lịch tuần.
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey<String>('dish-cooked-badge'),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 8,
          vertical: compact ? 1 : 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(compact ? 3 : 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_rounded,
                size: compact ? 10 : 14, color: AppColors.success),
            SizedBox(width: compact ? 2 : 4),
            Flexible(
              child: Text(
                label ?? context.l10n.mealPlanDishCooked,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 9 : 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
}
