import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Màu thương hiệu không có trong Material 3 [ColorScheme]
/// (design-system.md §5). Widget dùng chung đọc qua `context.appColors` để
/// tự đổi theo light/dark.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.textPrimary,
    required this.surfaceSubtle,
    required this.border,
    required this.textSecondary,
    required this.textDisabled,
    required this.errorSurface,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.info,
    required this.infoSurface,
    required this.primaryShadow,
    required this.ambientShadow,
    required this.scrim,
  });

  static const AppColorsExtension light = AppColorsExtension(
    textPrimary: AppColors.textPrimary,
    surfaceSubtle: AppColors.surfaceSubtle,
    border: AppColors.border,
    textSecondary: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
    errorSurface: AppColors.errorSurface,
    success: AppColors.success,
    successSurface: AppColors.successSurface,
    warning: AppColors.warning,
    warningSurface: AppColors.warningSurface,
    info: AppColors.info,
    infoSurface: AppColors.infoSurface,
    primaryShadow: AppColors.primaryShadow,
    ambientShadow: AppColors.ambientShadow,
    scrim: AppColors.scrim,
  );

  static const AppColorsExtension dark = AppColorsExtension(
    textPrimary: AppColors.darkTextPrimary,
    surfaceSubtle: AppColors.darkSurfaceSubtle,
    border: AppColors.darkBorder,
    textSecondary: AppColors.darkTextSecondary,
    textDisabled: AppColors.darkTextDisabled,
    errorSurface: AppColors.darkErrorSurface,
    success: AppColors.darkSuccess,
    successSurface: AppColors.darkSuccessSurface,
    warning: AppColors.darkWarning,
    warningSurface: AppColors.darkWarningSurface,
    info: AppColors.darkInfo,
    infoSurface: AppColors.darkInfoSurface,
    primaryShadow: AppColors.darkPrimaryShadow,
    ambientShadow: AppColors.darkAmbientShadow,
    scrim: AppColors.darkScrim,
  );

  /// Màu chữ chính. Light KHÔNG override `ColorScheme.onSurface` (giữ
  /// theme cũ) nên widget dùng field này thay cho `onSurface`.
  final Color textPrimary;
  final Color surfaceSubtle;
  final Color border;
  final Color textSecondary;
  final Color textDisabled;
  final Color errorSurface;
  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color info;
  final Color infoSurface;
  final Color primaryShadow;
  final Color ambientShadow;
  final Color scrim;

  @override
  AppColorsExtension copyWith({
    Color? textPrimary,
    Color? surfaceSubtle,
    Color? border,
    Color? textSecondary,
    Color? textDisabled,
    Color? errorSurface,
    Color? success,
    Color? successSurface,
    Color? warning,
    Color? warningSurface,
    Color? info,
    Color? infoSurface,
    Color? primaryShadow,
    Color? ambientShadow,
    Color? scrim,
  }) =>
      AppColorsExtension(
        textPrimary: textPrimary ?? this.textPrimary,
        surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
        border: border ?? this.border,
        textSecondary: textSecondary ?? this.textSecondary,
        textDisabled: textDisabled ?? this.textDisabled,
        errorSurface: errorSurface ?? this.errorSurface,
        success: success ?? this.success,
        successSurface: successSurface ?? this.successSurface,
        warning: warning ?? this.warning,
        warningSurface: warningSurface ?? this.warningSurface,
        info: info ?? this.info,
        infoSurface: infoSurface ?? this.infoSurface,
        primaryShadow: primaryShadow ?? this.primaryShadow,
        ambientShadow: ambientShadow ?? this.ambientShadow,
        scrim: scrim ?? this.scrim,
      );

  @override
  AppColorsExtension lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorsExtension(
      textPrimary: mix(textPrimary, other.textPrimary),
      surfaceSubtle: mix(surfaceSubtle, other.surfaceSubtle),
      border: mix(border, other.border),
      textSecondary: mix(textSecondary, other.textSecondary),
      textDisabled: mix(textDisabled, other.textDisabled),
      errorSurface: mix(errorSurface, other.errorSurface),
      success: mix(success, other.success),
      successSurface: mix(successSurface, other.successSurface),
      warning: mix(warning, other.warning),
      warningSurface: mix(warningSurface, other.warningSurface),
      info: mix(info, other.info),
      infoSurface: mix(infoSurface, other.infoSurface),
      primaryShadow: mix(primaryShadow, other.primaryShadow),
      ambientShadow: mix(ambientShadow, other.ambientShadow),
      scrim: mix(scrim, other.scrim),
    );
  }
}

extension AppColorsX on BuildContext {
  /// Rơi về [AppColorsExtension.light] khi theme không gắn extension (vd. test
  /// tự dựng `ThemeData`) — không bao giờ null-crash.
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      AppColorsExtension.light;
}
