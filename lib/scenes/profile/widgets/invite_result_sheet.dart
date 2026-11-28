import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../constants/app_dimens.dart';
import '../../../constants/app_text_styles.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/invite_result.dart';
import '../../../widgets/feedback/app_toast.dart';

/// Kết quả `createInvite()` (S12.9, Guard 16a): QR + mã + link + hạn + sao chép.
class InviteResultSheet extends StatelessWidget {
  const InviteResultSheet({super.key, required this.invite});

  static const double _qrSize = 188;

  final InviteResult invite;

  Future<void> _copy(BuildContext context, String text) async {
    final copied = context.l10n.familyInviteCopied;
    await Clipboard.setData(ClipboardData(text: text));
    AppToast.show(copied, type: AppToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final expires =
        DateFormat.yMd(locale).add_Hm().format(invite.expiresAt.toLocal());
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.inviteMembers, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimens.md),
            Semantics(
              label: l10n.inviteQrSemantics,
              child: QrImageView(
                key: const ValueKey<String>('invite-qr'),
                data: invite.link,
                size: _qrSize,
              ),
            ),
            const SizedBox(height: AppDimens.md),
            SelectableText(
              invite.code,
              key: const ValueKey<String>('invite-code'),
              style: AppTextStyles.titleLarge.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: AppDimens.xs),
            Text(l10n.familyInviteExpiresAt(expires),
                style: AppTextStyles.label),
            const SizedBox(height: AppDimens.sm),
            SelectableText(
              invite.link,
              key: const ValueKey<String>('invite-link'),
              textAlign: TextAlign.center,
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppDimens.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    key: const ValueKey<String>('invite-copy-code'),
                    label: l10n.familyInviteCopyCode,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _copy(context, invite.code),
                  ),
                ),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: AppButton(
                    key: const ValueKey<String>('invite-copy-link'),
                    label: l10n.familyInviteCopyLink,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _copy(context, invite.link),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
