import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_dimens.dart';
import '../../../../data/network/api_exception.dart';
import '../../../../utils/l10n_x.dart';
import '../../../../widgets/app_scaffold.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../inventory_routes.dart';
import '../data/ocr_image_service.dart';
import '../domain/ocr_scan_result.dart';
import '../stores/ocr_store.dart';
import '../widgets/ocr_scan_mode_toggle.dart';

class CameraScanScene extends StatelessWidget {
  const CameraScanScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<OcrStore>();
    return Observer(
      builder: (_) {
        final isScanning = store.status == OcrStatus.scanning;
        return AppScaffold(
          title: context.l10n.inventoryOcrScanTitle,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              tooltip: context.l10n.dismiss,
              onPressed: isScanning ? null : () => _close(store),
              icon: const Icon(Icons.close),
            ),
          ],
          body: Column(
            children: <Widget>[
              Expanded(
                child: _Preview(
                  bytes: store.previewBytes,
                  scanning: isScanning,
                  error: store.scanError,
                ),
              ),
              _CapturePanel(
                store: store,
                disabled: isScanning,
                onCamera: () => _scan(store, OcrImageSource.camera),
                onGallery: () => _scan(store, OcrImageSource.gallery),
                onRetry: () => _retry(store),
                onChooseAnother: () => _chooseSource(context, store),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scan(OcrStore store, OcrImageSource source) async {
    final success = await store.pickAndScan(source);
    if (success) await Get.toNamed<void>(InventoryRoutes.scanReview);
  }

  Future<void> _retry(OcrStore store) async {
    final success = await store.retryScan();
    if (success) await Get.toNamed<void>(InventoryRoutes.scanReview);
  }

  Future<void> _chooseSource(BuildContext context, OcrStore store) async {
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
              onTap: () => Navigator.pop(
                sheetContext,
                OcrImageSource.camera,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(sheetContext.l10n.inventoryOcrChooseGallery),
              onTap: () => Navigator.pop(
                sheetContext,
                OcrImageSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _scan(store, source);
  }

  void _close(OcrStore store) {
    store.reset();
    Get.back<void>();
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.bytes,
    required this.scanning,
    required this.error,
  });

  final Uint8List? bytes;
  final bool scanning;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null;
    return Container(
      width: double.infinity,
      color: const Color(0xFF171719),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (hasImage)
            Image.memory(bytes!, fit: BoxFit.contain)
          else
            Center(
              child: Container(
                width: MediaQuery.sizeOf(context).width * .78,
                height: MediaQuery.sizeOf(context).height * .3,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .35),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: Text(
                  context.l10n.inventoryOcrFrameHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0x99FFFFFF)),
                ),
              ),
            ),
          if (scanning)
            ColoredBox(
              color: Colors.black.withValues(alpha: .64),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: AppDimens.md),
                    Text(
                      context.l10n.inventoryOcrAnalyzing,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (!scanning && error != null && hasImage)
            Align(
              alignment: Alignment.topCenter,
              child: _ErrorBanner(error: error!),
            ),
        ],
      ),
    );
  }
}

class _CapturePanel extends StatelessWidget {
  const _CapturePanel({
    required this.store,
    required this.disabled,
    required this.onCamera,
    required this.onGallery,
    required this.onRetry,
    required this.onChooseAnother,
  });

  final OcrStore store;
  final bool disabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRetry;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final error = store.scanError;
    final isPermissionError = error is OcrPermissionDeniedException;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (error != null && store.previewBytes == null)
                _ErrorBanner(error: error),
              if (error == null && !disabled) ...<Widget>[
                OcrScanModeToggle(
                  value: store.mode,
                  onChanged: store.setMode,
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  store.mode == OcrScanMode.item
                      ? context.l10n.inventoryOcrItemHint
                      : context.l10n.inventoryOcrReceiptHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppDimens.sm),
              ],
              if (isPermissionError)
                AppButton(
                  label: context.l10n.openSettings,
                  icon: Icons.settings_outlined,
                  onPressed: openAppSettings,
                )
              else if (error != null) ...<Widget>[
                if (store.canRetryScan) ...<Widget>[
                  AppButton(
                    label: context.l10n.retry,
                    icon: Icons.refresh,
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: AppDimens.sm),
                ],
                AppButton(
                  label: context.l10n.inventoryOcrChooseAnother,
                  icon: Icons.add_photo_alternate_outlined,
                  variant: store.canRetryScan
                      ? AppButtonVariant.outline
                      : AppButtonVariant.primary,
                  onPressed: onChooseAnother,
                ),
              ] else ...<Widget>[
                AppButton(
                  label: context.l10n.inventoryOcrTakePhoto,
                  icon: Icons.photo_camera_outlined,
                  isLoading: disabled,
                  onPressed: disabled ? null : onCamera,
                ),
                const SizedBox(height: AppDimens.sm),
                AppButton(
                  label: context.l10n.inventoryOcrChooseGallery,
                  icon: Icons.photo_library_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: disabled ? null : onGallery,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimens.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Text(
              _message(context, error),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _message(BuildContext context, Object value) {
    if (value is OcrPermissionDeniedException) {
      return context.l10n.inventoryOcrPermissionDenied;
    }
    if (value is OcrImageTooLargeException) {
      return context.l10n.inventoryOcrImageTooLarge;
    }
    if (value is OcrImageInvalidException) {
      return context.l10n.inventoryOcrImageInvalid;
    }
    if (value is NetworkException) return context.l10n.networkError;
    if (value is ApiException) {
      return switch (value.code) {
        'ERR_AI_TIMEOUT' => context.l10n.inventoryOcrAiTimeout,
        'ERR_AI_SERVICE_DOWN' => context.l10n.inventoryOcrAiUnavailable,
        'ERR_AI_RATE_LIMIT' => context.l10n.inventoryOcrAiRateLimit,
        'ERR_AI_CONTENT_FILTERED' => context.l10n.inventoryOcrContentFiltered,
        'ERR_AI_INVALID_OUTPUT' => context.l10n.inventoryOcrInvalidOutput,
        'ERR_INVENTORY_IMAGE_INVALID' => context.l10n.inventoryOcrImageInvalid,
        'ERR_INVENTORY_IMAGE_TOO_LARGE' =>
          context.l10n.inventoryOcrImageTooLarge,
        'ERR_INVENTORY_SCAN_IN_PROGRESS' =>
          context.l10n.inventoryOcrScanInProgress,
        'ERR_INVENTORY_NO_HOUSEHOLD' => context.l10n.inventoryOcrNoHousehold,
        _ => context.l10n.genericRetryError,
      };
    }
    return context.l10n.genericRetryError;
  }
}
