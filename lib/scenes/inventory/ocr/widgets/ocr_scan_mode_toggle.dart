import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_dimens.dart';
import '../../../../utils/l10n_x.dart';
import '../domain/ocr_scan_result.dart';

class OcrScanModeToggle extends StatelessWidget {
  const OcrScanModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final OcrScanMode value;
  final ValueChanged<OcrScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: AppColors.secondaryFill,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        children: <Widget>[
          _Segment(
            label: context.l10n.inventoryOcrModeItem,
            selected: value == OcrScanMode.item,
            onTap: () => onChanged(OcrScanMode.item),
          ),
          _Segment(
            label: context.l10n.inventoryOcrModeReceipt,
            selected: value == OcrScanMode.receipt,
            onTap: () => onChanged(OcrScanMode.receipt),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.sm,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
