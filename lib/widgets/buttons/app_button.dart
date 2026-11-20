import 'package:flutter/material.dart';

import '../../constants/app_colors_extension.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

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

  /// Hành động phá huỷ (xoá, rời nhóm) — nền đỏ nhạt, chữ đỏ
  /// (DESIGN_SYSTEM.md §4.1D, design-system.md §7.1).
  destructive,
}

/// Button dùng chung (fe-app-shell.md §10.2, design-system.md §7.1).
///
/// Dựng trên `FilledButton`/`OutlinedButton`/`TextButton` của Material 3.
/// [isLoading] thay label bằng spinner và vô hiệu hóa tap, để mọi feature có
/// UX in-flight nhất quán mà không tự implement lại. Màu lấy theo theme nên
/// tự đổi ở dark mode.
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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final foreground = _foregroundColor(scheme, colors);
    final VoidCallback? effectiveOnPressed = _isDisabled ? null : onPressed;

    final Widget content = isLoading
        ? SizedBox(
            height: AppDimens.buttonSpinner,
            width: AppDimens.buttonSpinner,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : _buildLabel(foreground);

    final OutlinedBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radiusForVariant),
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => DecoratedBox(
          decoration: _isDisabled
              ? const BoxDecoration()
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.primaryShadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
          child: FilledButton(
            onPressed: effectiveOnPressed,
            style: _filledStyle(
              scheme: scheme,
              background: scheme.primary,
              foreground: scheme.onPrimary,
              colors: colors,
              shape: shape,
            ),
            child: content,
          ),
        ),
      AppButtonVariant.secondary => FilledButton(
          onPressed: effectiveOnPressed,
          style: _filledStyle(
            scheme: scheme,
            background: scheme.primaryContainer,
            foreground: scheme.primary,
            colors: colors,
            shape: shape,
          ),
          child: content,
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: effectiveOnPressed,
          style: _filledStyle(
            scheme: scheme,
            background: colors.errorSurface,
            foreground: scheme.error,
            colors: colors,
            shape: shape,
          ),
          child: content,
        ),
      AppButtonVariant.google => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.ambientShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _outlined(effectiveOnPressed, scheme, colors, shape, content,
              textStyle: AppTextStyles.button),
        ),
      AppButtonVariant.outline =>
        _outlined(effectiveOnPressed, scheme, colors, shape, content),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            disabledForegroundColor: colors.textDisabled,
            shape: shape,
          ),
          child: content,
        ),
    };

    final Widget sized = SizedBox(
      height: AppDimens.buttonHeight, // 52dp theo DESIGN_SYSTEM.md
      width: expanded ? double.infinity : null,
      child: button,
    );

    // excludeSemantics: label chỉ được đọc một lần (không lặp từ Text con);
    // onTap giữ để TalkBack/VoiceOver vẫn kích hoạt được; container: node
    // riêng — không bị gộp vào Card/ListTile cha (design §7.1).
    return Semantics(
      container: true,
      button: true,
      enabled: !_isDisabled,
      label: label,
      hint: isLoading ? _loadingHint(context) : null,
      excludeSemantics: true,
      onTap: effectiveOnPressed,
      child: sized,
    );
  }

  /// Không ép buộc có `AppLocalizations` trong cây chỉ vì nút đang loading.
  static String? _loadingHint(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)
          ?.commonLoading;

  ButtonStyle _filledStyle({
    required ColorScheme scheme,
    required Color background,
    required Color foreground,
    required AppColorsExtension colors,
    required OutlinedBorder shape,
  }) =>
      FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: colors.textDisabled,
        disabledForegroundColor: scheme.onPrimary,
        elevation: 0,
        // Giữ textStyle cũ của elevatedButtonTheme (letterSpacing/height).
        textStyle: AppTextStyles.button,
        shadowColor: Colors.transparent,
        shape: shape,
      );

  Widget _outlined(
    VoidCallback? onPressed,
    ColorScheme scheme,
    AppColorsExtension colors,
    OutlinedBorder shape,
    Widget content, {
    TextStyle? textStyle,
  }) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textDisabled,
          side: BorderSide(color: colors.border),
          shape: shape,
          textStyle: textStyle,
        ),
        child: content,
      );

  Widget _buildLabel(Color foreground) {
    final text = Text(
      label,
      style: AppTextStyles.button.copyWith(
        color: foreground,
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
        Icon(iconData, size: 18, color: foreground),
        const SizedBox(width: AppDimens.sm),
        Flexible(child: text),
      ],
    );
  }

  Color _foregroundColor(ColorScheme scheme, AppColorsExtension colors) {
    // Màu chữ theo variant, kể cả khi disabled — giữ đúng hành vi light trước
    // issue #17 (code review M3).
    return switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.secondary => scheme.primary,
      AppButtonVariant.destructive => scheme.error,
      AppButtonVariant.outline => colors.textPrimary,
      AppButtonVariant.google => colors.textPrimary,
      AppButtonVariant.text => scheme.primary,
    };
  }

  double get _radiusForVariant => switch (variant) {
        AppButtonVariant.text => AppDimens.radiusSm,
        _ => AppDimens.radiusCard,
      };
}
