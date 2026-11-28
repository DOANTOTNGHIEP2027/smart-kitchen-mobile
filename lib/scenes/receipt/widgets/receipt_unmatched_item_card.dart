import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../domain/shared/food_category.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/quantity_format.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/inputs/expiry_date_chip.dart';
import '../../inventory/domain/unit_option.dart';
import '../../inventory/widgets/unit_picker.dart';
import '../domain/receipt_unmatched_item.dart';
import 'receipt_matched_line_tile.dart' show ReceiptBadge;
import 'receipt_summary_header.dart';
import '../../../utils/unit_label.dart';

/// Map `confirmError` (MÃ lỗi) → câu chữ (§13.3).
String receiptConfirmErrorMessage(AppLocalizations l10n, String code) {
  return switch (code) {
    'INVALID_RECEIPT_ITEM' => l10n.inventoryUnitRequired,
    'ERR_NETWORK' => l10n.networkError,
    _ => l10n.genericRetryError,
  };
}

/// Thẻ món mua ngoài danh sách (§13.2). Sửa được tên/số lượng/đơn vị/danh mục;
/// nút riêng "Thêm vào tồn kho" theo `confirmStatus`. Đơn vị bắt đầu trống, BẮT
/// BUỘC chọn từ `unitOptions` (D9).
class ReceiptUnmatchedItemCard extends StatefulWidget {
  const ReceiptUnmatchedItemCard({
    super.key,
    required this.item,
    required this.currency,
    required this.onNameChanged,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onExpiryChanged,
    required this.onCategoryChanged,
    required this.onConfirm,
  });

  final ReceiptUnmatchedItem item;
  final String currency;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double?> onQuantityChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<DateTime> onExpiryChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onConfirm;

  @override
  State<ReceiptUnmatchedItemCard> createState() =>
      _ReceiptUnmatchedItemCardState();
}

class _ReceiptUnmatchedItemCardState extends State<ReceiptUnmatchedItemCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  // #201: phân loại chọn từ danh sách chuẩn (chip), không gõ tự do.
  String? _category;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.name);
    _quantityController = TextEditingController(
      text: item.quantity == null ? '' : formatQuantity(item.quantity!),
    );
    final suggested = item.category?.trim();
    _category = suggested == null || suggested.isEmpty ? null : suggested;
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
    final l10n = context.l10n;
    final status = item.confirmStatus;
    final confirmed = status == ReceiptConfirmStatus.confirmed;
    final locked = item.isLocked;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: confirmed ? AppColors.successSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: confirmed
              ? AppColors.success
              : status == ReceiptConfirmStatus.failed
                  ? AppColors.error
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _rawInfo(context),
          const SizedBox(height: AppDimens.sm),
          TextField(
            key: ValueKey<String>('receipt-unmatched-name-${item.itemId}'),
            controller: _nameController,
            enabled: !locked,
            decoration: InputDecoration(
              labelText: l10n.inventoryName,
              isDense: true,
            ),
            onChanged: widget.onNameChanged,
          ),
          const SizedBox(height: AppDimens.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _quantityField(context, locked)),
              const SizedBox(width: AppDimens.sm),
              Expanded(child: _unitField(context, locked)),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          _categoryChips(context, locked),
          const SizedBox(height: AppDimens.sm),
          // #239: hạn gợi ý của BE, luôn hiện để người dùng tự thêm/sửa.
          Align(
            alignment: Alignment.centerLeft,
            child: ExpiryDateChip(
              date: item.expiryDate,
              suggested: item.isExpirySuggested,
              enabled: !locked,
              onChanged: widget.onExpiryChanged,
            ),
          ),
          if (item.confirmError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.sm),
              child: Text(
                receiptConfirmErrorMessage(l10n, item.confirmError!),
                key: ValueKey<String>('receipt-unmatched-error-${item.itemId}'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          const SizedBox(height: AppDimens.sm),
          _action(context),
        ],
      ),
    );
  }

  Widget _rawInfo(BuildContext context) {
    final item = widget.item;
    final price = item.totalPrice;
    final raw = <String>[
      context.l10n.receiptOnReceipt(item.rawName),
      formatQuantityWithUnitLabel(context.l10n, item.rawQuantity, item.rawUnit),
      if (price != null) formatReceiptAmount(price, widget.currency),
    ].join(' · ');
    final secondary = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        );
    final confidence = item.matchConfidence;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(raw, style: secondary)),
        // Điểm catalog AI — nhãn xám tham khảo, KHÔNG phải badge cảnh báo.
        if (confidence != null)
          Padding(
            padding: const EdgeInsets.only(left: AppDimens.sm),
            child: Text(
              context.l10n.receiptCatalogHint((confidence * 100).round()),
              style: secondary,
            ),
          ),
      ],
    );
  }

  Widget _categoryChips(BuildContext context, bool locked) {
    final selected = _category;
    // Gợi ý cũ/tự do của BE không thuộc bộ chuẩn vẫn hiện để không mất.
    final options = <String>[
      ...FoodCategory.labels,
      if (selected != null && !FoodCategory.labels.contains(selected))
        selected,
    ];
    return Column(
      key: ValueKey<String>('receipt-unmatched-category-${widget.item.itemId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.receiptCategoryOptional,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppDimens.xs),
        Wrap(
          spacing: AppDimens.xs,
          runSpacing: AppDimens.xs,
          children: options.map((name) {
            final isSelected = selected == name;
            return ChoiceChip(
              label: Text(name),
              selected: isSelected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selectedColor: AppColors.primaryContainer,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppColors.onPrimaryContainer
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: locked
                  ? null
                  : (v) {
                      final next = v ? name : null;
                      setState(() => _category = next);
                      widget.onCategoryChanged(next);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _quantityField(BuildContext context, bool locked) {
    final item = widget.item;
    return TextField(
      key: ValueKey<String>('receipt-unmatched-qty-${item.itemId}'),
      controller: _quantityController,
      enabled: !locked,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: context.l10n.inventoryQuantityLabel,
        errorText: !locked && (item.quantity == null || item.quantity! <= 0)
            ? context.l10n.inventoryOcrQuantityInvalid
            : null,
        isDense: true,
      ),
      onChanged: (value) => widget.onQuantityChanged(
        double.tryParse(value.trim().replaceAll(',', '.')),
      ),
    );
  }

  Widget _unitField(BuildContext context, bool locked) {
    final item = widget.item;
    final unit = item.unit;
    return InkWell(
      key: ValueKey<String>('receipt-unmatched-unit-${item.itemId}'),
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      onTap: locked ? null : () => _pickUnit(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.l10n.inventoryUnit,
          errorText:
              !locked && unit == null ? context.l10n.receiptUnitHint : null,
          errorMaxLines: 2,
          enabled: !locked,
          isDense: true,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                unit == null
                    ? context.l10n.inventoryChooseUnit
                    : unitLabel(context, unit),
                style: TextStyle(
                  color: unit == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context) {
    final item = widget.item;
    final l10n = context.l10n;
    final key = ValueKey<String>('receipt-unmatched-action-${item.itemId}');
    switch (item.confirmStatus) {
      case ReceiptConfirmStatus.confirming:
        return AppButton(
          key: key,
          label: l10n.receiptAdding,
          isLoading: true,
          variant: AppButtonVariant.outline,
          onPressed: null,
        );
      case ReceiptConfirmStatus.confirmed:
        return Align(
          alignment: Alignment.centerLeft,
          child: ReceiptBadge(
            key: key,
            label: l10n.receiptAdded,
            background: AppColors.successSurface,
            foreground: AppColors.success,
          ),
        );
      case ReceiptConfirmStatus.failed:
        return AppButton(
          key: key,
          label: l10n.retry,
          icon: Icons.refresh,
          onPressed: item.isValidForConfirm ? widget.onConfirm : null,
        );
      case ReceiptConfirmStatus.pending:
        return AppButton(
          key: key,
          label: l10n.receiptAddToInventory,
          icon: Icons.inventory_2_outlined,
          variant: AppButtonVariant.outline,
          onPressed: item.isValidForConfirm ? widget.onConfirm : null,
        );
    }
  }

  Future<void> _pickUnit(BuildContext context) async {
    final current = widget.item.unit;
    final selected = current == null
        ? null
        : unitOptions.where((option) => option.value == current).firstOrNull;
    final unit = await showUnitPicker(context, selected: selected);
    if (unit != null) widget.onUnitChanged(unit.value);
  }
}
