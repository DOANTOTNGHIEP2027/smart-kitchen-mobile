import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_dimens.dart';
import '../../../../utils/l10n_x.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../domain/unit_option.dart';
import '../../widgets/unit_picker.dart';
import '../domain/ocr_item.dart';

class OcrItemCard extends StatefulWidget {
  const OcrItemCard({
    super.key,
    required this.item,
    required this.locked,
    required this.onChanged,
    required this.onSave,
    required this.onRemove,
  });

  final OcrItem item;
  final bool locked;
  final void Function({
    String? name,
    Object? quantity,
    Object? unit,
    Object? expiryEstimate,
  }) onChanged;
  final VoidCallback onSave;
  final VoidCallback onRemove;

  @override
  State<OcrItemCard> createState() => _OcrItemCardState();
}

class _OcrItemCardState extends State<OcrItemCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: _formatQuantity(widget.item.quantity),
    );
  }

  @override
  void didUpdateWidget(covariant OcrItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.name != widget.item.name &&
        _nameController.text != widget.item.name) {
      _nameController.text = widget.item.name;
    }
    final quantity = _formatQuantity(widget.item.quantity);
    if (oldWidget.item.quantity != widget.item.quantity &&
        _quantityController.text != quantity) {
      _quantityController.text = quantity;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final confirmed = item.confirmStatus == OcrConfirmStatus.confirmed;
    final confirming = item.confirmStatus == OcrConfirmStatus.confirming;
    final failed = item.confirmStatus == OcrConfirmStatus.failed;
    final invalid = !item.isValidForConfirm;
    final disabled = widget.locked || confirming || confirmed;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: confirming ? .68 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: confirmed
              ? const Color(0xFFF2FBF4)
              : invalid
                  ? const Color(0xFFFFF8F8)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: confirmed
                ? AppColors.success
                : (invalid || failed)
                    ? AppColors.error
                    : AppColors.border,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A111111),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    enabled: !disabled,
                    decoration: InputDecoration(
                      labelText: context.l10n.inventoryName,
                      isDense: true,
                    ),
                    onChanged: (value) => widget.onChanged(name: value),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                if (confirming)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (confirmed)
                  _Badge(
                    label: context.l10n.inventoryOcrSaved,
                    background: const Color(0xFFE6F7EA),
                    foreground: AppColors.success,
                  )
                else
                  TextButton.icon(
                    onPressed: disabled ? null : widget.onRemove,
                    icon: const Icon(Icons.close, size: 15),
                    label: Text(context.l10n.skip),
                  ),
              ],
            ),
            if (!confirmed) ...<Widget>[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (item.needsManualReview)
                    _Badge(
                      label: context.l10n.inventoryOcrNeedsReview,
                      background: const Color(0xFFFDECEA),
                      foreground: AppColors.error,
                    ),
                  if (item.duplicate)
                    _Badge(
                      label: context.l10n.inventoryOcrDuplicate,
                      background: const Color(0xFFF3E8FF),
                      foreground: const Color(0xFF7C3AED),
                    ),
                  if (item.expiryEstimate != null)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.event_outlined, size: 14),
                      label: Text(
                        context.l10n.inventoryOcrExpiryEstimate(
                          MaterialLocalizations.of(context)
                              .formatCompactDate(item.expiryEstimate!),
                        ),
                      ),
                      onPressed: disabled ? null : () => _pickExpiry(context),
                    ),
                ],
              ),
              if (item.rawUnit != null && item.unit == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    context.l10n.inventoryOcrRawValue(
                      _formatQuantity(item.rawQuantity),
                      item.rawUnit!,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              const SizedBox(height: AppDimens.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      enabled: !disabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.inventoryQuantityLabel,
                        hintText: context.l10n.inventoryOcrQuantityHint,
                        errorText: item.quantity == null || item.quantity! <= 0
                            ? context.l10n.inventoryOcrQuantityInvalid
                            : null,
                        isDense: true,
                      ),
                      onChanged: (value) => widget.onChanged(
                        quantity: double.tryParse(value.replaceAll(',', '.')),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      onTap: disabled ? null : () => _pickUnit(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.l10n.inventoryUnit,
                          errorText: item.unit == null
                              ? context.l10n.inventoryUnitRequired
                              : null,
                          isDense: true,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.unit ?? context.l10n.choose,
                                style: TextStyle(
                                  color: item.unit == null
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (item.confirmError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    item.confirmError == 'INVALID_OCR_ITEM'
                        ? context.l10n.inventoryOcrCompleteFields
                        : item.confirmError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              const SizedBox(height: AppDimens.sm),
              AppButton(
                label: failed
                    ? context.l10n.retry
                    : context.l10n.inventoryOcrSaveItem,
                icon: failed ? Icons.refresh : Icons.inventory_2_outlined,
                variant: failed
                    ? AppButtonVariant.primary
                    : AppButtonVariant.outline,
                expanded: true,
                onPressed: disabled || invalid ? null : widget.onSave,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickUnit(BuildContext context) async {
    final selected = widget.item.unit == null
        ? null
        : unitOptions
            .where((option) => option.value == widget.item.unit)
            .firstOrNull;
    final unit = await showUnitPicker(context, selected: selected);
    if (unit != null) widget.onChanged(unit: unit.value);
  }

  Future<void> _pickExpiry(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.item.expiryEstimate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null) widget.onChanged(expiryEstimate: selected);
  }

  static String _formatQuantity(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
