import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../data/network/api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../../inventory/ocr/data/ocr_image_service.dart';
import '../../inventory/ocr/domain/ocr_scan_result.dart' show OcrImageSource;
import '../stores/receipt_scan_store.dart';

const String _noHouseholdCode = 'ERR_RECEIPT_NO_HOUSEHOLD';
const String _inProgressCode = 'ERR_RECEIPT_SCAN_IN_PROGRESS';

/// Màn chụp/chọn ảnh hoá đơn (#68, shopping-receipt-scan.md §13.1). Loading và
/// lỗi mạng/AI hiển thị TẠI ĐÂY — chỉ sang màn kết quả khi có 200 (§2).
class ReceiptScanScene extends StatelessWidget {
  const ReceiptScanScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ReceiptScanStore>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Đang đọc → chặn back hệ thống, dùng nút Huỷ (§12.4).
        if (store.status == ReceiptScanStatus.scanning) return;
        _close(context, store);
      },
      child: Observer(
        builder: (_) {
          final scanning = store.status == ReceiptScanStatus.scanning;
          return AppScaffold(
            title: context.l10n.receiptScanTitle,
            automaticallyImplyLeading: false,
            actions: <Widget>[
              IconButton(
                key: const ValueKey<String>('receipt-scan-close'),
                tooltip: context.l10n.receiptClose,
                onPressed: scanning ? null : () => _close(context, store),
                icon: const Icon(Icons.close),
              ),
            ],
            body: Column(
              children: <Widget>[
                Expanded(
                  child: _Preview(
                    bytes: store.previewBytes,
                    scanning: scanning,
                  ),
                ),
                _ActionPanel(
                  scanning: scanning,
                  error: store.scanError,
                  canResend: store.canResend,
                  canRetry: store.canRetryScan,
                  onCamera: () => _scan(store, OcrImageSource.camera),
                  onGallery: () => _scan(store, OcrImageSource.gallery),
                  onRetry: () => _retry(store),
                  onRetryPick: () => _scan(
                    store,
                    store.lastPickSource ?? OcrImageSource.camera,
                  ),
                  onCancel: store.cancelScan,
                  onChooseAnother: () => _chooseSource(context, store),
                  onClose: () => _close(context, store),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _scan(ReceiptScanStore store, OcrImageSource source) async {
    if (await store.pickAndScan(source)) {
      await Get.toNamed<void>(AppRoutes.receiptScanResult);
    }
  }

  Future<void> _retry(ReceiptScanStore store) async {
    if (await store.retryScan()) {
      await Get.toNamed<void>(AppRoutes.receiptScanResult);
    }
  }

  Future<void> _chooseSource(
    BuildContext context,
    ReceiptScanStore store,
  ) async {
    final source = await showModalBottomSheet<OcrImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(sheetContext.l10n.inventoryOcrTakePhoto),
              onTap: () => Navigator.pop(sheetContext, OcrImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(sheetContext.l10n.inventoryOcrChooseGallery),
              onTap: () => Navigator.pop(sheetContext, OcrImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _scan(store, source);
  }

  /// Nút X / back. KHÔNG `Get.back()`: GetX 4.7.3 chỉ đóng snackbar nếu đang
  /// mở mà không pop màn (§12.4, Guard 15).
  void _close(BuildContext context, ReceiptScanStore store) {
    store.reset();
    Navigator.of(context).pop();
  }
}

/// Câu chữ lỗi màn scan — 1 nguồn duy nhất theo bảng §13.1.
String receiptScanErrorMessage(AppLocalizations l10n, Object error) {
  if (error is OcrPermissionDeniedException) {
    return l10n.inventoryOcrPermissionDenied;
  }
  if (error is OcrImageTooLargeException) return l10n.inventoryOcrImageTooLarge;
  if (error is OcrImageInvalidException) return l10n.inventoryOcrImageInvalid;
  if (error is NetworkException) return l10n.networkError;
  if (error is! ApiException) return l10n.genericRetryError;
  switch (error.code) {
    case 'ERR_AI_TIMEOUT':
    case 'ERR_AI_SERVICE_DOWN':
    case 'ERR_AI_RATE_LIMIT':
      return l10n.receiptErrorAiUnavailable;
    case _inProgressCode:
      return l10n.receiptErrorInProgress;
    case 'ERR_AI_INVALID_OUTPUT':
    case 'ERR_AI_CONTENT_FILTERED':
    case 'ERR_RECEIPT_IMAGE_INVALID':
    case 'ERR_RECEIPT_IMAGE_TOO_LARGE':
    case 'ERR_VALIDATION_FAILED':
      return l10n.receiptErrorImageRejected;
    case _noHouseholdCode:
      return l10n.receiptErrorNoHousehold;
  }
  // 5xx khác ≠ ERR_AI_INVALID_OUTPUT → tạm thời (cùng luật canRetryScan).
  if (error is ServerException) return l10n.receiptErrorAiUnavailable;
  return apiErrorMessage(l10n, error);
}

class _Preview extends StatelessWidget {
  const _Preview({required this.bytes, required this.scanning});

  final Uint8List? bytes;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimens.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (image != null)
            Image.memory(
              image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: AppDimens.stateIcon,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    context.l10n.receiptScanNoImage,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (scanning)
            ColoredBox(
              key: const ValueKey<String>('receipt-scan-overlay'),
              color: AppColors.scrim,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: AppDimens.md),
                    Text(
                      context.l10n.receiptScanning,
                      style: const TextStyle(color: AppColors.textOnPrimary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.scanning,
    required this.error,
    required this.canResend,
    required this.canRetry,
    required this.onCamera,
    required this.onGallery,
    required this.onRetry,
    required this.onRetryPick,
    required this.onCancel,
    required this.onChooseAnother,
    required this.onClose,
  });

  final bool scanning;
  final Object? error;
  final bool canResend;
  final bool canRetry;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRetry;
  final VoidCallback onRetryPick;
  final VoidCallback onCancel;
  final VoidCallback onChooseAnother;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _children(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _children(BuildContext context) {
    final l10n = context.l10n;
    if (scanning) {
      return <Widget>[
        AppButton(
          key: const ValueKey<String>('receipt-scan-cancel'),
          label: l10n.cancel,
          icon: Icons.close,
          variant: AppButtonVariant.outline,
          onPressed: onCancel,
        ),
      ];
    }
    final current = error;
    if (current == null) return _idle(l10n);
    if (current is ApiException && current.code == _noHouseholdCode) {
      return _noHousehold(context);
    }
    final banner = FeatureBanner(
      key: const ValueKey<String>('receipt-scan-error'),
      message: receiptScanErrorMessage(l10n, current),
      margin: const EdgeInsets.only(bottom: AppDimens.md),
    );
    if (current is OcrPermissionDeniedException) {
      return <Widget>[
        banner,
        AppButton(
          key: const ValueKey<String>('receipt-open-settings'),
          label: l10n.openSettings,
          icon: Icons.settings_outlined,
          onPressed: openAppSettings,
        ),
        // Lệch mock màn 5 (L4): quay lại từ Cài đặt thì chọn ảnh lại được
        // ngay, không phải đóng màn rồi mở lại.
        const SizedBox(height: AppDimens.sm),
        AppButton(
          key: const ValueKey<String>('receipt-permission-retry'),
          label: l10n.retry,
          icon: Icons.refresh,
          variant: AppButtonVariant.outline,
          onPressed: onRetryPick,
        ),
      ];
    }
    final inProgress =
        current is ApiException && current.code == _inProgressCode;
    return <Widget>[
      banner,
      if (canRetry) _retryButton(l10n),
      // 409: chỉ "Thử lại" thủ công (mock màn 6).
      if (!(inProgress && canRetry)) ...<Widget>[
        if (canRetry) const SizedBox(height: AppDimens.sm),
        AppButton(
          key: const ValueKey<String>('receipt-choose-another'),
          label: l10n.inventoryOcrChooseAnother,
          icon: Icons.add_photo_alternate_outlined,
          variant:
              canRetry ? AppButtonVariant.outline : AppButtonVariant.primary,
          onPressed: onChooseAnother,
        ),
      ],
    ];
  }

  List<Widget> _idle(AppLocalizations l10n) {
    return <Widget>[
      Text(
        l10n.receiptScanHint,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppDimens.md),
      // Vừa Huỷ: còn ảnh + key → gửi lại đúng key cũ (Guard 5).
      if (canResend) ...<Widget>[
        _retryButton(l10n),
        const SizedBox(height: AppDimens.sm),
      ],
      AppButton(
        key: const ValueKey<String>('receipt-take-photo'),
        label: l10n.inventoryOcrTakePhoto,
        icon: Icons.photo_camera_outlined,
        variant:
            canResend ? AppButtonVariant.outline : AppButtonVariant.primary,
        onPressed: onCamera,
      ),
      const SizedBox(height: AppDimens.sm),
      AppButton(
        key: const ValueKey<String>('receipt-choose-gallery'),
        label: l10n.inventoryOcrChooseGallery,
        icon: Icons.photo_library_outlined,
        variant: AppButtonVariant.outline,
        onPressed: onGallery,
      ),
    ];
  }

  List<Widget> _noHousehold(BuildContext context) {
    final l10n = context.l10n;
    return <Widget>[
      const Icon(
        Icons.home_outlined,
        size: AppDimens.stateIcon,
        color: AppColors.textDisabled,
      ),
      const SizedBox(height: AppDimens.sm),
      Text(
        l10n.receiptErrorNoHouseholdTitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: AppDimens.xs),
      Text(
        l10n.receiptErrorNoHousehold,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppDimens.md),
      AppButton(
        key: const ValueKey<String>('receipt-no-household-close'),
        label: l10n.receiptClose,
        onPressed: onClose,
      ),
    ];
  }

  Widget _retryButton(AppLocalizations l10n) => AppButton(
        key: const ValueKey<String>('receipt-scan-retry'),
        label: l10n.retry,
        icon: Icons.refresh,
        onPressed: onRetry,
      );
}
