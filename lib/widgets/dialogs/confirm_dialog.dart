import 'package:flutter/material.dart';

import '../../constants/app_dimens.dart';
import '../../utils/l10n_x.dart';
import '../buttons/app_button.dart';

/// Mở [ConfirmDialog]; trả `true` khi xác nhận, `false` khi huỷ / chạm ra ngoài /
/// back — không bao giờ `null` (design-system.md §7.7).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

/// Hộp thoại xác nhận dùng chung. Thường gọi qua [showConfirmDialog].
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          AppButton(
            key: const ValueKey<String>('confirm-dialog-cancel'),
            label: cancelLabel ?? context.l10n.cancel,
            variant: AppButtonVariant.text,
            expanded: false,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            key: const ValueKey<String>('confirm-dialog-confirm'),
            label: confirmLabel ?? context.l10n.commonConfirm,
            variant: isDestructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
}
