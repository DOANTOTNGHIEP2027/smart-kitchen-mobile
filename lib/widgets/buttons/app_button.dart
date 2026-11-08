import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';

/// Kiểu nút bấm — bám mock và quy chuẩn DESIGN_SYSTEM.md (100% Solid Color, No Gradient).
enum AppButtonVariant {
  /// `.btn-primary` — Solid Cam (#FF7A45) + soft ambient shadow.
  primary,

  /// `.btn-secondary` — Nền cam kem ấm (#FFF2EA), text cam đậm (#FF7A45).
  secondary,

  /// `.btn-outline` — Nền trắng, viền hairline (#EBEBEF), text đen.
  outline,

  /// `.btn-google` — Nền trắng, viền hairline, shadow rất nhẹ.
  google,

  /// `.link` (trong mock) — Text-only, màu cam.
  text,
}

/// Button dùng chung (fe-app-shell.md §10.2).
///
/// [isLoading] thay label bằng spinner và vô hiệu hóa tap, để mọi feature có
/// UX in-flight nhất quán mà không tự implement lại.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;

  bool get _isDisabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final Widget content = isLoading
        ? SizedBox(
            height: AppDimens.buttonSpinner,
            width: AppDimens.buttonSpinner,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
            ),
          )
        : _buildLabel();

    final OutlinedBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radiusForVariant),
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => Container(
          decoration: _isDisabled
              ? null
              : const BoxDecoration(
                  color: AppColors.primary, // 100% Solid Color — Không Gradient
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppDimens.radiusCard)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
          child: ElevatedButton(
            onPressed: _isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isDisabled ? AppColors.textDisabled : Colors.transparent,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.textDisabled,
              disabledForegroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: shape,
            ),
            child: content,
          ),
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.textDisabled,
            disabledForegroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: shape,
          ),
          child: content,
        ),
      AppButtonVariant.google => DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(color: AppColors.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.textPrimary,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: AppColors.textDisabled,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: shape,
            ),
            child: content,
          ),
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            disabledForegroundColor: AppColors.textDisabled,
            side: const BorderSide(color: AppColors.border),
            shape: shape,
          ),
          child: content,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.textDisabled,
            shape: shape,
          ),
          child: content,
        ),
    };

    final Widget sized = SizedBox(
      height: 52, // Chiều cao chuẩn 52dp theo DESIGN_SYSTEM.md
      width: expanded ? double.infinity : null,
      child: button,
    );

    return Semantics(
        button: true, enabled: !_isDisabled, label: label, child: sized);
  }

  Widget _buildLabel() {
    final text = Text(
      label,
      style: AppTextStyles.button.copyWith(
        color: _foregroundColor,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final iconData = icon;
    if (iconData == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(iconData, size: 18, color: _foregroundColor),
        const SizedBox(width: AppDimens.sm),
        Flexible(child: text),
      ],
    );
  }

  Color get _foregroundColor => switch (variant) {
        AppButtonVariant.primary => AppColors.textOnPrimary,
        AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.outline => AppColors.textPrimary,
        AppButtonVariant.google => AppColors.textPrimary,
        AppButtonVariant.text => AppColors.primary,
      };

  double get _radiusForVariant => switch (variant) {
        AppButtonVariant.text => AppDimens.radiusSm,
        _ => AppDimens.radiusCard,
      };
}
