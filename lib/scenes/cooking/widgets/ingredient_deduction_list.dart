import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../domain/ingredient_deduction.dart';

/// Danh sách kết quả trừ kho sau `complete()` (FE-6 §7.4).
///
/// `hasShortfall` (badge cảnh báo) là cách FE biểu diễn **"thiếu nguyên liệu"**
/// mà không văng lỗi — BE `complete()` luôn 200 (OD-04).
class IngredientDeductionList extends StatelessWidget {
  const IngredientDeductionList({super.key, required this.deductions});

  final List<IngredientDeduction> deductions;

  @override
  Widget build(BuildContext context) {
    if (deductions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.md),
        child: Text('Không có nguyên liệu nào để trừ (recipe rỗng).'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deductions.length,
      itemBuilder: (_, i) {
        final d = deductions[i];
        return _DeductionRow(deduction: d);
      },
    );
  }
}

class _DeductionRow extends StatelessWidget {
  const _DeductionRow({required this.deduction});

  final IngredientDeduction deduction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.md, vertical: AppDimens.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(deduction.ingredientName,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    'Cần: ${deduction.requiredQuantity} ${deduction.requiredUnit}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Đã trừ: ${deduction.deductedQuantity} ${deduction.requiredUnit}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  if (deduction.deductedQuantity <
                      deduction.requiredQuantity)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimens.xs),
                      child: Text(
                        'Thiếu: ${deduction.shortfallQuantity} ${deduction.requiredUnit}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.error),
                      ),
                    ),
                  Text(
                    'Từ ${deduction.matchedItemCount} lô hàng',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (deduction.hasShortfall)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.sm, vertical: AppDimens.xs),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Không đủ',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
