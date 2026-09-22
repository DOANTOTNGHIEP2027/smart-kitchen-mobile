import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/unit_option.dart';

/// Picker cho [unitOptions] (FE-5 §14 UnitPicker). Hiển thị dưới dạng
/// bottom-sheet, trả về [UnitOption] đã chọn hoặc null khi huỷ.
Future<UnitOption?> showUnitPicker(BuildContext context,
    {UnitOption? selected}) async {
  return showModalBottomSheet<UnitOption>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Text(context.l10n.inventoryChooseUnit,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ...unitOptions.map((u) {
            final isSelected = selected?.value == u.value;
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              tileColor: isSelected ? AppColors.primaryLight : null,
              leading: Icon(isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
                  color: isSelected ? AppColors.primaryDark : null),
              title: Text(u.label),
              onTap: () => Navigator.of(context).pop(u),
            );
          }),
          const SizedBox(height: AppDimens.sm),
        ],
      ),
    ),
  );
}
