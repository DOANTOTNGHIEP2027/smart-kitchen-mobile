import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../stores/household_store.dart';
import '../../utils/l10n_x.dart';
import '../../utils/validators.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/app_error_view.dart';
import '../../widgets/invite_code_card.dart';
import 'onboarding_routes.dart';

/// S8.1 / S8.2 — quét QR mã mời, và state bị từ chối quyền camera.
class InviteScanScene extends StatefulWidget {
  const InviteScanScene({super.key});

  @override
  State<InviteScanScene> createState() => _InviteScanSceneState();
}

class _InviteScanSceneState extends State<InviteScanScene> {
  final HouseholdStore _store = Get.find<HouseholdStore>();
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  /// Chặn xử lý nhiều lần khi camera bắn liên tiếp cùng một mã trong lúc đang
  /// điều hướng sang màn preview.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Chấp nhận cả link deep-link lẫn mã trần: QR do [InviteCodeCard] sinh ra
  /// mã hoá link đầy đủ, còn QR in sẵn ở nơi khác có thể chỉ chứa mã.
  String? _extractCode(String raw) {
    final value = raw.trim();
    final fromLink = value.startsWith(InviteCodeCard.joinLinkPrefix)
        ? value.substring(InviteCodeCard.joinLinkPrefix.length)
        : value;
    final code = fromLink.split('?').first.split('/').first.toUpperCase();
    return Validators.isValidInviteCode(code) ? code : null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes
        .map((Barcode b) => b.rawValue)
        .whereType<String>()
        .map(_extractCode)
        .whereType<String>()
        .firstOrNull;
    if (raw == null) return;

    _handled = true;
    await _controller.stop();
    final ok = await _store.loadPreview(raw);
    if (!mounted) return;
    if (ok) {
      await Get.toNamed<void>(OnboardingRoutes.invitePreview);
    }
    // Quét lại được sau khi quay về, kể cả khi preview thất bại.
    _handled = false;
    if (mounted) await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.scanTitle,
      body: Column(
        children: <Widget>[
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (BuildContext context, MobileScannerException error) =>
                  _ScanUnavailable(error: error),
              overlayBuilder: (BuildContext context, BoxConstraints _) =>
                  const _ScanReticle(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              children: <Widget>[
                Text(
                  context.l10n.scanHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppDimens.md),
                AppButton(
                  label: context.l10n.scanEnterManually,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      Get.offNamed<void>(OnboardingRoutes.inviteCode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// S8.2 — quyền bị từ chối, hoặc thiết bị/trình duyệt không có camera dùng
/// được. Luôn kèm lối thoát sang nhập tay để user không bị kẹt.
class _ScanUnavailable extends StatelessWidget {
  const _ScanUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) => AppErrorView(
        message: context.l10n.scanPermissionDenied,
        onRetry: () => Get.offNamed<void>(OnboardingRoutes.inviteCode),
      );
}

class _ScanReticle extends StatelessWidget {
  const _ScanReticle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surface, width: 3),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
        ),
      );
}
