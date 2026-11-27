import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/diet_type.dart';
import 'diet_type_label.dart';

/// Chọn chế độ ăn bằng hàng chip tự xuống dòng (thay dropdown bị tràn màn
/// hẹp). `null` = "Chưa chọn" — khác [DietType.none] ("Không kiêng"), giữ
/// đúng ngữ nghĩa của form cũ. Mô tả của lựa chọn hiện ngay dưới chip.
/// Dùng chung cho hồ sơ sức khoẻ của mình và của người phụ thuộc.
class DietTypeSelector extends StatelessWidget {
  const DietTypeSelector({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.helpText,
  });

  final DietType? value;
  final bool enabled;
  final ValueChanged<DietType?> onChanged;

  /// Ghi chú phụ cố định (vd. "chọn không gluten không đồng nghĩa đã khai dị
  /// ứng Gluten").
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final current = value;

    Widget chip(DietType? d, String label, String keySuffix) {
      final selected = d == current;
      return ChoiceChip(
        key: ValueKey<String>('health-diet-$keySuffix'),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primaryContainer,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: selected ? AppColors.onPrimaryContainer : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: enabled && !selected ? (_) => onChanged(d) : null,
      );
    }

    return Column(
      key: const ValueKey<String>('health-diet'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.restaurant_menu_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppDimens.sm),
            Text(l.healthProfileDietType, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: AppDimens.sm),
        Wrap(
          spacing: AppDimens.sm,
          runSpacing: AppDimens.xs,
          children: <Widget>[
            chip(null, l.dietTypeUnsetShort, 'unset'),
            for (final DietType d in DietType.values)
              chip(d, d.shortLabel(l), dietTypeToWire(d)),
          ],
        ),
        const SizedBox(height: AppDimens.sm),
        Text(
          current == null ? l.dietTypeUnsetDescription : current.description(l),
          key: const ValueKey<String>('health-diet-description'),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        if (helpText != null) ...<Widget>[
          const SizedBox(height: AppDimens.xs),
          Text(
            helpText!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
