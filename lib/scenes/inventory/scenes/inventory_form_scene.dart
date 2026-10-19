import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../constants/app_dimens.dart';
import '../../../data/network/api_exception.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/inventory_item.dart';
import '../inventory_routes.dart';
import '../domain/unit_option.dart';
import '../stores/inventory_form_store.dart';
import '../widgets/conflict_dialog.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/unit_picker.dart';
import '../widgets/waste_cause_sheet.dart';

/// Form thêm/sửa inventory (FE-5 §14 InventoryFormScene).
///
/// Một widget duy nhất cho cả add & edit — `mode` được suy từ `Get.parameters`
/// trong binding và truyền vào [InventoryFormStore].
class InventoryFormScene extends StatefulWidget {
  const InventoryFormScene({super.key});

  @override
  State<InventoryFormScene> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScene> {
  late final InventoryFormStore store;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _lowStockCtrl;
  late final TextEditingController _noteCtrl;
  late final ReactionDisposer _conflictReactionDisposer;
  InventoryItemModel? _initialItem;

  UnitOption? _unit;
  DateTime? _expiryDate;
  // Tránh mở dialog 2 lần giữa lúc đó conflict vẫn còn.
  bool _conflictDialogOpen = false;

  @override
  void initState() {
    super.initState();
    store = Get.find<InventoryFormStore>();
    final args = Get.arguments;
    final item = args is InventoryItemModel ? args : null;
    _initialItem = item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _quantityCtrl = TextEditingController(
        text: item == null
            ? ''
            : (item.displayQuantity ?? item.quantity).toString());
    _lowStockCtrl =
        TextEditingController(text: item?.lowStockThreshold?.toString() ?? '');
    _noteCtrl = TextEditingController(text: item?.note ?? '');
    if (item?.displayUnit != null) {
      _unit = unitOptions.firstWhere(
        (u) => u.value == item!.displayUnit,
        orElse: () => unitOptions.first,
      );
    }
    _expiryDate = item?.expiryDate;

    // Reaction mở dialog ngay khi store.conflict != null (Phase 0 US 2.1 AC 2).
    _conflictReactionDisposer = reaction<InventoryConflict?>(
      (_) => store.conflict,
      (c) {
        if (c != null && !_conflictDialogOpen && mounted) {
          _showConflictDialog(c);
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _conflictReactionDisposer();
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _lowStockCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = store.mode == InventoryFormMode.edit;
    return AppScaffold(
      title: isEdit
          ? context.l10n.inventoryEditItem
          : context.l10n.inventoryAddItem,
      body: Observer(
        builder: (_) {
          if (store.isSaving) {
            // Disable form khi đang lưu — visual indicator nhẹ.
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (store.saveError != null)
                  _SaveErrorBanner(
                    error: store.saveError!,
                    onRetry: store.clearError,
                  ),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.inventoryItemName,
                    hintText: context.l10n.inventoryItemNameHint,
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppDimens.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _quantityCtrl,
                        decoration: InputDecoration(
                          labelText: context.l10n.inventoryQuantity,
                          prefixIcon: const Icon(Icons.scale_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final selected =
                              await showUnitPicker(context, selected: _unit);
                          if (selected != null) {
                            setState(() => _unit = selected);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.l10n.inventoryUnit,
                            prefixIcon: const Icon(Icons.straighten_outlined),
                          ),
                          child: Text(_unit?.label ?? context.l10n.choose),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: _lowStockCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.inventoryLowStockOptional,
                    prefixIcon: const Icon(Icons.warning_amber_outlined),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppDimens.md),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiryDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setState(() => _expiryDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.inventoryExpiryOptional,
                      prefixIcon: const Icon(Icons.event_outlined),
                    ),
                    child: Text(_expiryDate == null
                        ? context.l10n.inventoryChooseDate
                        : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'),
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.inventoryNoteOptional,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppDimens.lg),
                Observer(
                  builder: (_) => AppButton(
                    label: isEdit
                        ? context.l10n.saveChanges
                        : context.l10n.inventoryAddToInventory,
                    isLoading: store.isSaving,
                    onPressed: store.isSaving ? null : _onSave,
                  ),
                ),
                if (isEdit) ...<Widget>[
                  const SizedBox(height: AppDimens.md),
                  AppButton(
                    label: context.l10n.inventoryHistoryOpen,
                    icon: Icons.history_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Get.toNamed(
                      InventoryRoutes.history
                          .replaceFirst(':id', store.itemId!),
                      arguments: Get.arguments,
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  TextButton.icon(
                    onPressed: store.isSaving ? null : _onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(context.l10n.inventoryDeleteItem,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String? _validateForSave() {
    final nameErr = InventoryFormStore.validateName(_nameCtrl.text);
    if (nameErr != null) return _validationMessage(nameErr);
    if (_unit == null) return context.l10n.inventoryUnitRequired;
    final qtyErr = InventoryFormStore.validateQuantity(
      _quantityCtrl.text,
      mode: store.mode,
      mustBeWhole: _unit!.isWholeNumber,
    );
    if (qtyErr != null) return _validationMessage(qtyErr);
    return null;
  }

  String _validationMessage(InventoryFormValidationError e) => switch (e) {
        InventoryFormValidationError.nameEmpty =>
          context.l10n.inventoryValidationNameEmpty,
        InventoryFormValidationError.quantityEmpty =>
          context.l10n.inventoryValidationQuantityEmpty,
        InventoryFormValidationError.quantityNotNumber =>
          context.l10n.inventoryValidationQuantityNotNumber,
        InventoryFormValidationError.quantityNotPositive =>
          context.l10n.inventoryValidationQuantityNotPositive,
        InventoryFormValidationError.quantityNegative =>
          context.l10n.inventoryValidationQuantityNegative,
        InventoryFormValidationError.quantityNotWhole =>
          context.l10n.inventoryValidationQuantityNotWhole,
      };

  Future<void> _onSave() async {
    final validation = _validateForSave();
    if (validation != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final quantity = double.parse(_quantityCtrl.text.trim());
    WasteReasonChoice wasteChoice = const WasteReasonChoice.skipped();
    final initial = _initialItem;
    if (store.mode == InventoryFormMode.edit &&
        initial != null &&
        initial.displayUnit == _unit!.value &&
        initial.displayQuantity != null &&
        quantity < initial.displayQuantity!) {
      wasteChoice = await showWasteCauseSheet(
        context,
        endpoint: WasteEndpoint.put,
      );
      if (!mounted) return;
    }
    final lowStock = double.tryParse(_lowStockCtrl.text.trim());
    final ok = await store.save(
      name: _nameCtrl.text,
      quantity: quantity,
      unit: _unit!.value,
      lowStockThreshold: lowStock,
      expiryDate: _expiryDate,
      note: _noteCtrl.text,
      reason: wasteChoice.reason,
      wasteCause: wasteChoice.wasteCause,
    );
    if (!mounted) return;
    if (ok) {
      Get.back();
    } else if (store.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(apiErrorMessage(context.l10n, store.saveError))),
      );
    }
    // Nếu conflict đã mở → dialog tự bật qua _onConflictChanged; không SnackBar.
  }

  Future<void> _onDelete() async {
    final choice = await showDeleteConfirmDialog(context);
    if (choice == null) return;
    if (!mounted) return;
    WasteReasonChoice wasteChoice = const WasteReasonChoice.skipped();
    if (choice.reason == DeleteReason.waste) {
      wasteChoice = await showWasteCauseSheet(
        context,
        endpoint: WasteEndpoint.delete,
      );
      if (!mounted) return;
    }
    final ok = await store.delete(
      reason: choice.wire,
      wasteCause: wasteChoice.wasteCause,
    );
    if (!mounted) return;
    if (ok) {
      Get.back();
    } else if (store.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(apiErrorMessage(context.l10n, store.saveError))),
      );
    }
  }

  void _showConflictDialog(InventoryConflict conflict) {
    _conflictDialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConflictDialog(
        conflict: conflict,
        onKeepMine: () {
          Navigator.of(context).pop();
          _conflictDialogOpen = false;
          store.resolveConflict(ConflictResolution.keepMine);
        },
        onUseServer: () {
          Navigator.of(context).pop();
          _conflictDialogOpen = false;
          store.resolveConflict(ConflictResolution.useServer);
        },
      ),
    ).then((_) => _conflictDialogOpen = false);
  }
}

class _SaveErrorBanner extends StatelessWidget {
  const _SaveErrorBanner({required this.error, required this.onRetry});

  final ApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(apiErrorMessage(context.l10n, error))),
            TextButton(onPressed: onRetry, child: Text(context.l10n.dismiss)),
          ],
        ),
      ),
    );
  }
}
