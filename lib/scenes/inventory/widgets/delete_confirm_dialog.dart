import 'package:flutter/material.dart';

import '../../../utils/l10n_x.dart';

/// Dialog xác nhận xoá (FE-5 §14 DeleteConfirmDialog, fix M12 hậu D21).
///
/// 3 lựa chọn — mỗi lựa chọn map sang đúng `reason` của BE trên endpoint
/// DELETE (`/v1/inventory-items/{id}` nhận `WASTE | COOKED | CORRECTED`,
/// inventory-core OAS v1.2.0). Lý do "Xoá nhầm" được giữ để người dùng có
/// đường.undo nhập sai chứ không phải ép chọn "đã dùng hết".
enum DeleteReason { cooked, waste, corrected }

class DeleteReasonChoice {
  const DeleteReasonChoice(this.reason);
  final DeleteReason reason;

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

/// Hiển thị [DeleteConfirmDialog], trả về lựa chọn hoặc null khi huỷ.
Future<DeleteReasonChoice?> showDeleteConfirmDialog(
    BuildContext context) async {
  final result = await showDialog<DeleteReasonChoice>(
    context: context,
    builder: (_) => const DeleteConfirmDialog(),
  );
  return result;
}

class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.inventoryDeleteTitle),
      content: Text(context.l10n.inventoryDeleteMessage),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(const DeleteReasonChoice(DeleteReason.cooked)),
          child: Text(context.l10n.inventoryDeleteCooked),
        ),
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(const DeleteReasonChoice(DeleteReason.waste)),
          style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
          child: Text(context.l10n.inventoryDeleteWaste),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop(const DeleteReasonChoice(DeleteReason.corrected)),
          child: Text(context.l10n.inventoryDeleteCorrected),
        ),
      ],
    );
  }
}
