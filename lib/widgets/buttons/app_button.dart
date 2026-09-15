import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, text }

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
    final child = isLoading
        ? SizedBox(
            height: AppDimens.buttonSpinner,
            width: AppDimens.buttonSpinner,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
            ),
          )
        : _buildLabel();

    final button = SizedBox(
      height: AppDimens.buttonHeight,
      width: expanded ? double.infinity : null,
      child: switch (variant) {
        AppButtonVariant.primary => ElevatedButton(
            onPressed: _isDisabled ? null : onPressed,
            style: _elevatedStyle,
            child: child,
          ),
        AppButtonVariant.secondary => OutlinedButton(
            onPressed: _isDisabled ? null : onPressed,
            style: _outlinedStyle,
            child: child,
          ),
        AppButtonVariant.text => TextButton(
            onPressed: _isDisabled ? null : onPressed,
            style: _textStyle,
            child: child,
          ),
      },
    );

    return Semantics(button: true, enabled: !_isDisabled, label: label, child: button);
  }

  Widget _buildLabel() {
    // Label dài + icon phải co lại thay vì tràn khỏi button — nhãn đã dịch
    // i18n có thể dài hơn nhiều so với tiếng Anh.
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
        AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.text => AppColors.primary,
      };

  static final RoundedRectangleBorder _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
  );

  ButtonStyle get _elevatedStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.textDisabled,
        disabledForegroundColor: AppColors.textOnPrimary,
        elevation: 0,
        shape: _shape,
      );

  ButtonStyle get _outlinedStyle => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        side: const BorderSide(color: AppColors.primary),
        shape: _shape,
      );

  ButtonStyle get _textStyle => TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        shape: _shape,
      );
}
