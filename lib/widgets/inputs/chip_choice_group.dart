import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

/// Một lựa chọn của [ChipChoiceGroup]: giá trị, nhãn hiển thị và hậu tố key
/// (key chip = `'$groupKey-$keySuffix'`).
class ChipChoiceOption<T> {
  const ChipChoiceOption(this.value, this.label, this.keySuffix);

  final T value;
  final String label;
  final String keySuffix;
}

/// #201: nhóm chip một lựa chọn, tự xuống dòng — thay cho mọi dropdown.
///
/// - [allLabel] khác `null` → thêm chip đầu tiên mang giá trị `null`
///   (vd. "Tất cả"), key `'$groupKey-all'`.
/// - [allowDeselect] `true` → bấm lại chip đang chọn = bỏ chọn (`null`);
///   `false` → giữ nguyên lựa chọn (trường bắt buộc).
class ChipChoiceGroup<T> extends StatelessWidget {
  const ChipChoiceGroup({
    super.key,
    required this.groupKey,
    required this.value,
    required this.options,
    required this.onChanged,
    this.title,
    this.icon,
    this.enabled = true,
    this.allLabel,
    this.allowDeselect = true,
  });

  final String groupKey;
  final T? value;
  final List<ChipChoiceOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? title;
  final IconData? icon;
  final bool enabled;
  final String? allLabel;
  final bool allowDeselect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      if (allLabel != null)
        _chip(
          theme,
          key: '$groupKey-all',
          label: allLabel!,
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
      for (final option in options)
        _chip(
          theme,
          key: '$groupKey-${option.keySuffix}',
          label: option.label,
          selected: option.value == value,
          onSelected: (bool v) {
            if (v) {
              onChanged(option.value);
            } else if (allowDeselect) {
              onChanged(null);
            }
          },
        ),
    ];
    return Column(
      key: ValueKey<String>(groupKey),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (title != null) ...<Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppDimens.sm),
              ],
              Flexible(child: Text(title!, style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
        ],
        Wrap(
          spacing: AppDimens.sm,
          runSpacing: AppDimens.xs,
          children: chips,
        ),
      ],
    );
  }

  Widget _chip(
    ThemeData theme, {
    required String key,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) =>
      ChoiceChip(
        key: ValueKey<String>(key),
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
        onSelected: enabled ? onSelected : null,
      );
}
