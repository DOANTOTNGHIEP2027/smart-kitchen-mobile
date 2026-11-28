import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/quantity_format.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/inputs/expiry_date_chip.dart';
import '../../../widgets/states/app_state_view.dart';
import '../../inventory/domain/unit_option.dart';
import '../../inventory/widgets/unit_picker.dart';
import '../domain/checkout_preview_item.dart';
import '../stores/shopping_checkout_store.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../utils/unit_label.dart';

/// "Cất vào kho" (#239, thiết kế FE §1–§2): xem lại món đã mua, sửa hạn/số
/// lượng, bỏ chọn món không cất, rồi ghi tất cả bằng MỘT lần batch.
class ShoppingCheckoutScene extends StatefulWidget {
  const ShoppingCheckoutScene({super.key});

  @override
  State<ShoppingCheckoutScene> createState() => _ShoppingCheckoutSceneState();
}

class _ShoppingCheckoutSceneState extends State<ShoppingCheckoutScene> {
  late final ShoppingCheckoutStore _store = Get.find<ShoppingCheckoutStore>();

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _submit() async {
    final count = await _store.submit();
    if (!mounted) return;
    if (count != null) {
      AppToast.show(context.l10n.shoppingCheckoutDone(count),
          type: AppToastType.success);
      Get.back<void>();
      return;
    }
    final error = _store.submitError;
    if (error == null) return;
    final reloaded = error.code.startsWith('ERR_SHOP_');
    AppToast.show(
        reloaded
            ? '${apiErrorMessage(context.l10n, error)} ${context.l10n.shoppingCheckoutReloaded}'
            : apiErrorMessage(context.l10n, error),
        type: AppToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.shoppingCheckoutTitle,
      body: Observer(
        builder: (_) => AppStateView<List<CheckoutPreviewItem>>(
          state: _store.state,
          onRetry: _store.load,
          emptyMessage: l10n.shoppingCheckoutEmpty,
          emptyIcon: Icons.kitchen_outlined,
          successBuilder: (context, items) => ListView(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.md, AppDimens.sm, AppDimens.md, AppDimens.xxl),
            children: <Widget>[
              Text(l10n.shoppingCheckoutHint,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppDimens.sm),
              for (final item in items)
                _CheckoutRow(
                  key: ValueKey<String>('checkout-row-${item.shoppingItemId}'),
                  item: item,
                  store: _store,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Observer(builder: (_) {
        if (_store.items.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!_store.isOnline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.xs),
                    child: Text(l10n.shoppingCheckoutOffline,
                        key: const ValueKey<String>('checkout-offline'),
                        style: const TextStyle(color: AppColors.error)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey<String>('checkout-confirm'),
                    onPressed: _store.canSubmit ? _submit : null,
                    child: _store.submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.shoppingCheckoutConfirm(_store.selectedCount)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CheckoutRow extends StatelessWidget {
  const _CheckoutRow({super.key, required this.item, required this.store});

  final CheckoutPreviewItem item;
  final ShoppingCheckoutStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Observer(builder: (_) {
      final hasError = store.errorRowIds.contains(item.shoppingItemId);
      final valid = store.isRowValid(item);
      final disabled = store.submitting;
      return Card(
        margin: const EdgeInsets.only(bottom: AppDimens.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: BorderSide(
            color: hasError || (item.selected && !valid) ? AppColors.error : AppColors.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm, vertical: AppDimens.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                key: ValueKey<String>('checkout-select-${item.shoppingItemId}'),
                value: item.selected,
                onChanged: disabled ? null : (_) => store.toggleSelected(item.shoppingItemId),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: AppDimens.xs),
                    Text(item.name,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        ActionChip(
                          key: ValueKey<String>('checkout-qty-${item.shoppingItemId}'),
                          visualDensity: VisualDensity.compact,
                          label: Text(formatQuantityWithUnitLabel(context.l10n, item.quantity, item.unit)),
                          onPressed: disabled || !item.selected ? null : () => _editQuantity(context),
                        ),
                        ExpiryDateChip(
                          date: item.expiryDate,
                          suggested: item.isExpirySuggested,
                          enabled: !disabled && item.selected,
                          onChanged: (date) => store.setExpiry(item.shoppingItemId, date),
                        ),
                        if (item.duplicate)
                          Text(l10n.shoppingCheckoutDuplicate,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF7C3AED))),
                      ],
                    ),
                    if (item.selected && !valid)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l10n.shoppingCheckoutInvalidRow,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
                      ),
                    const SizedBox(height: AppDimens.xs),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _editQuantity(BuildContext context) async {
    final selectedUnit = unitOptions.where((o) => o.value == item.unit).firstOrNull;
    final controller = TextEditingController(text: formatQuantity(item.quantity));
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (dialogContext) {
        var unit = selectedUnit;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(item.name),
            content: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const ValueKey<String>('checkout-qty-input'),
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(labelText: context.l10n.inventoryQuantity),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                TextButton(
                  onPressed: () async {
                    final picked = await showUnitPicker(context, selected: unit);
                    if (picked != null) setState(() => unit = picked);
                  },
                  child: Text(unit == null
                      ? context.l10n.inventoryChooseUnit
                      : unitLabel(context, unit!.value)),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () {
                  final qty = double.tryParse(controller.text.replaceAll(',', '.'));
                  if (qty == null || unit == null) return;
                  Navigator.of(dialogContext).pop((qty, unit!.value));
                },
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          );
        });
      },
    );
    controller.dispose();
    if (result == null) return;
    store.setQuantity(item.shoppingItemId, result.$1);
    store.setUnit(item.shoppingItemId, result.$2);
  }
}
