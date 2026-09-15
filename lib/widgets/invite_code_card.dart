import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_text_styles.dart';
import '../utils/l10n_x.dart';
import 'buttons/app_button.dart';
import 'cards/app_card.dart';

/// Hiển thị mã mời dưới dạng QR + chuỗi thô kèm nút sao chép (S7.4).
///
/// Flow 12 của `#29` (S12.9 — quản lý invite) sẽ dùng lại chính widget này.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.code,
    this.expiresAt,
    this.onCopied,
  });

  /// Link deep-link mà QR mã hoá — cùng dạng với link chia sẻ của BE.
  static const String joinLinkPrefix = 'https://app.smartkitchen.vn/join/';

  final String code;
  final DateTime? expiresAt;
  final VoidCallback? onCopied;

  String get link => '$joinLinkPrefix$code';

  @override
  Widget build(BuildContext context) {
    final expiry = expiresAt;
    return AppCard(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: link,
                size: 176,
                backgroundColor: Colors.white,
                // Mã mời là dữ liệu ngắn; mức sửa lỗi cao giúp quét được cả
                // khi ảnh bị che một phần hoặc chụp lại từ màn hình.
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          Text(
            context.l10n.inviteCodeLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppDimens.xs),
          SelectableText(
            code,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(letterSpacing: 6),
          ),
          if (expiry != null) ...<Widget>[
            const SizedBox(height: AppDimens.sm),
            Text(
              context.l10n.inviteExpiresAt(expiry),
              textAlign: TextAlign.center,
              style: AppTextStyles.label,
            ),
          ],
          const SizedBox(height: AppDimens.md),
          AppButton(
            label: context.l10n.inviteCopyCta,
            icon: Icons.copy,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              onCopied?.call();
            },
          ),
        ],
      ),
    );
  }
}
