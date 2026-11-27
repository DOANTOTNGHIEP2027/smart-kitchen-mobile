import 'package:flutter/material.dart';

import '../../../utils/l10n_x.dart';
import 'waste_cause_sheet.dart';

/// Xoá mặt hàng (FE-5 §14 DeleteConfirmDialog, fix M12 hậu D21; gọn lại #201).
///
/// Luồng 2 bước, mỗi bước hỏi đúng một việc:
/// 1. [showDeleteConfirmDialog] — chỉ `Huỷ` / `Xoá`.
/// 2. [showDeleteReasonSheet] — MỘT sheet lý do duy nhất, map sang `reason`
///    của BE trên endpoint DELETE (`/v1/inventory-items/{id}` nhận
///    `WASTE | COOKED | CORRECTED`, inventory-core OAS v1.2.0) và `wasteCause`
///    khi bỏ đi (qua [wasteChoiceFor]). Đóng sheet không chọn → `CORRECTED`.
enum DeleteReason { cooked, waste, corrected }

class DeleteReasonChoice {
  const DeleteReasonChoice(this.reason, {this.wasteCause});
  final DeleteReason reason;

  /// Chỉ có khi [reason] là [DeleteReason.waste].
  final String? wasteCause;

  /// Wire format cho API.
  String get wire {
    switch (reason) {
      case DeleteReason.cooked:
        return 'COOKED';
      case DeleteReason.waste:
        return 'WASTE';
      case DeleteReason.corrected:
        return 'CORRECTED';
    }
  }
}

/// Hiển thị [DeleteConfirmDialog]; `true` khi người dùng bấm Xoá.
Future<bool> showDeleteConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const DeleteConfirmDialog(),
  );
  return result ?? false;
}

class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.inventoryDeleteTitle),
      content: Text(context.l10n.inventoryDeleteConfirmMessage),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('inventory-delete-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('inventory-delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.delete),
        ),
      ],
    );
  }
}

/// Sheet lý do xoá. Bỏ qua (vuốt/chạm ngoài) → `CORRECTED`.
Future<DeleteReasonChoice> showDeleteReasonSheet(BuildContext context) async {
  final result = await showModalBottomSheet<DeleteReasonChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _DeleteReasonSheet(),
  );
  return result ?? const DeleteReasonChoice(DeleteReason.corrected);
}

class _DeleteReasonSheet extends StatelessWidget {
  const _DeleteReasonSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.inventoryDeleteReasonTitle,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.inventoryDeleteMessage),
            const SizedBox(height: 8),
            _tile(
              context,
              key: 'delete-reason-cooked',
              icon: Icons.restaurant_outlined,
              label: l10n.inventoryDeleteCooked,
              choice: const DeleteReasonChoice(DeleteReason.cooked),
            ),
            _tile(
              context,
              key: 'delete-reason-corrected',
              icon: Icons.edit_note_outlined,
              label: l10n.inventoryDeleteCorrected,
              choice: const DeleteReasonChoice(DeleteReason.corrected),
            ),
            const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(l10n.inventoryDeleteWaste,
                  style: theme.textTheme.labelLarge),
            ),
            _waste(context, Icons.shopping_basket_outlined,
                l10n.inventoryWasteOverbought, WasteCause.overbought),
            _waste(context, Icons.event_busy_outlined,
                l10n.inventoryWasteForgotten, WasteCause.forgotten),
            _waste(context, Icons.warning_amber_outlined,
                l10n.inventoryWasteSpoiledEarly, WasteCause.spoiledEarly),
          ],
        ),
      ),
    );
  }

  Widget _waste(
      BuildContext context, IconData icon, String label, WasteCause cause) {
    final choice = wasteChoiceFor(cause, WasteEndpoint.delete);
    return _tile(
      context,
      key: 'delete-reason-waste-${cause.name}',
      icon: icon,
      label: label,
      choice: DeleteReasonChoice(DeleteReason.waste,
          wasteCause: choice.wasteCause),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String key,
    required IconData icon,
    required String label,
    required DeleteReasonChoice choice,
  }) =>
      ListTile(
        key: ValueKey<String>(key),
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        onTap: () => Navigator.of(context).pop(choice),
      );
}
