import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';

/// Kiểu nút bấm — bám mock `docs/design/frontend/mockups/*.html` (`.btn-*`).
enum AppButtonVariant {
  /// `.btn-primary` — gradient cam + shadow hồng cam.
  primary,

  /// `.btn-secondary` — nền be `#f1eeea`, text đen.
  secondary,

  /// `.btn-outline` — nền trắng, border xám, text đen.
  outline,

  /// `.btn-google` — nền trắng, border xám, shadow rất nhẹ.
  google,

  /// `.link` (trong mock) — text-only, màu cam.
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
              strokeWidth: 2,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.primaryGradientStart,
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
          child: ElevatedButton(
            onPressed: _isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDisabled ? AppColors.textDisabled : Colors.transparent,
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
            backgroundColor: AppColors.secondaryFill,
            foregroundColor: AppColors.textPrimary,
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
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14111111),
                blurRadius: 3,
                offset: Offset(0, 1),
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
      height: AppDimens.buttonHeight,
      width: expanded ? double.infinity : null,
      child: button,
    );

    return Semantics(button: true, enabled: !_isDisabled, label: label, child: sized);
  }

  Widget _buildLabel() {
    final text = Text(
      label,
      style: AppTextStyles.button,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final iconData = icon;
    if (iconData == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(iconData, size: 18),
        const SizedBox(width: AppDimens.sm),
        Flexible(child: text),
      ],
    );
  }

  Color get _foregroundColor => switch (variant) {
        AppButtonVariant.primary => AppColors.textOnPrimary,
        AppButtonVariant.secondary => AppColors.textPrimary,
        AppButtonVariant.outline => AppColors.textPrimary,
        AppButtonVariant.google => AppColors.textPrimary,
        AppButtonVariant.text => AppColors.primary,
      };

  double get _radiusForVariant => switch (variant) {
        AppButtonVariant.text => AppDimens.radiusSm,
        _ => AppDimens.radiusMd,
      };
}
