import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_colors_extension.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';

/// Lắp ráp token thành [ThemeData] chuẩn DESIGN_SYSTEM.md (fe-app-shell.md §11,
/// design-system.md §6). `GetMaterialApp(theme: light, darkTheme: dark)` là
/// consumer duy nhất.
///
/// Bất biến: [light] giữ đúng giá trị trước issue #17 — có test so toàn bộ
/// ThemeData với bản sao đóng băng (`test/constants/legacy_light_theme.dart`).
abstract class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final ext = isDark ? AppColorsExtension.dark : AppColorsExtension.light;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final error = isDark ? AppColors.darkError : AppColors.error;
    final textTheme = AppTextStyles.textTheme(brightness);

    // Light: giữ đúng bộ override cũ — KHÔNG thêm onSurface (design §6, review H1).
    final colorScheme = isDark
        ? ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            primaryContainer: AppColors.darkPrimaryContainer,
            onPrimaryContainer: AppColors.darkOnPrimaryContainer,
            secondary: AppColors.primary,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkTextPrimary,
            error: AppColors.darkError,
            brightness: Brightness.dark,
          )
        : ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            primaryContainer: AppColors.primaryContainer,
            onPrimaryContainer: AppColors.onPrimaryContainer,
            secondary: AppColors.primaryDark,
            surface: AppColors.surface,
            error: AppColors.error,
            brightness: Brightness.light,
          );

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          side: BorderSide(color: ext.border, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: 15,
        ),
        labelStyle: textTheme.labelSmall,
        hintStyle: textTheme.bodyMedium,
        errorStyle: const TextStyle(fontSize: 12, height: 1.2),
        border: inputBorder(ext.border, 1.0),
        enabledBorder: inputBorder(ext.border, 1.0),
        focusedBorder: inputBorder(AppColors.primary, 1.5),
        errorBorder: inputBorder(error, 1.5),
        focusedErrorBorder: inputBorder(error, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(textTheme.labelSmall),
      ),
      dividerTheme: DividerThemeData(
        color: ext.border,
        thickness: AppDimens.borderWidth,
        space: AppDimens.borderWidth,
      ),
      extensions: <ThemeExtension<dynamic>>[ext],
    );
  }
}
