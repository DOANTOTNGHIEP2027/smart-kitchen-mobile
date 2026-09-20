import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../constants/app_dimens.dart';
import '../../../data/network/api_exception.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/inventory_item.dart';
import '../domain/unit_option.dart';
import '../stores/inventory_form_store.dart';
import '../widgets/conflict_dialog.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/unit_picker.dart';

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
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _quantityCtrl = TextEditingController(
        text: item == null ? '' : (item.displayQuantity ?? item.quantity).toString());
    _lowStockCtrl = TextEditingController(
        text: item?.lowStockThreshold?.toString() ?? '');
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
      title: isEdit ? 'Sửa mặt hàng' : 'Thêm mặt hàng',
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
                  decoration: const InputDecoration(
                    labelText: 'Tên mặt hàng *',
                    hintText: 'vd. Cà chua',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
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
                        decoration: const InputDecoration(
                          labelText: 'Số lượng *',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final selected = await showUnitPicker(context,
                              selected: _unit);
                          if (selected != null) {
                            setState(() => _unit = selected);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Đơn vị',
                            prefixIcon: Icon(Icons.straighten_outlined),
                          ),
                          child: Text(_unit?.label ?? 'Chọn…'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: _lowStockCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ngưỡng sắp hết (tuỳ chọn)',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
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
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setState(() => _expiryDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hạn sử dụng (tuỳ chọn)',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(_expiryDate == null
                        ? 'Chọn ngày…'
                        : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'),
                  ),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tuỳ chọn)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppDimens.lg),
                Observer(
                  builder: (_) => AppButton(
                    label: isEdit ? 'Lưu thay đổi' : 'Thêm vào kho',
                    isLoading: store.isSaving,
                    onPressed: store.isSaving ? null : _onSave,
                  ),
                ),
                if (isEdit) ...<Widget>[
                  const SizedBox(height: AppDimens.md),
                  TextButton.icon(
                    onPressed: store.isSaving ? null : _onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    label: const Text('Xoá mặt hàng',
                        style: TextStyle(color: Colors.red)),
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
    if (nameErr != null) return nameErr;
    if (_unit == null) return 'Vui lòng chọn đơn vị';
    final qtyErr = InventoryFormStore.validateQuantity(
      _quantityCtrl.text,
      mode: store.mode,
      mustBeWhole: _unit!.isWholeNumber,
    );
    if (qtyErr != null) return qtyErr;
    return null;
  }

  Future<void> _onSave() async {
    final validation = _validateForSave();
    if (validation != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final lowStock = double.tryParse(_lowStockCtrl.text.trim());
    final ok = await store.save(
      name: _nameCtrl.text,
      quantity: double.parse(_quantityCtrl.text.trim()),
      unit: _unit!.value,
      lowStockThreshold: lowStock,
      expiryDate: _expiryDate,
      note: _noteCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Get.back();
    } else if (store.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.saveError!.message)),
      );
    }
    // Nếu conflict đã mở → dialog tự bật qua _onConflictChanged; không SnackBar.
  }

  Future<void> _onDelete() async {
    final choice = await showDeleteConfirmDialog(context);
    if (choice == null) return;
    final ok = await store.delete(reason: choice.wire);
    if (!mounted) return;
    if (ok) {
      Get.back();
    } else if (store.saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.saveError!.message)),
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
            Expanded(child: Text(error.message)),
            TextButton(onPressed: onRetry, child: const Text('Bỏ')),
          ],
        ),
      ),
    );
  }
}
