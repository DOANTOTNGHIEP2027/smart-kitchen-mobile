import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design token — typography (issue #17).
abstract class AppTextStyles {
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// `TextTheme` theo [brightness] (design-system.md §4.3). Ở light trả về
  /// đúng bộ style cũ; ở dark chỉ đổi màu chữ.
  static TextTheme textTheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const TextTheme(
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelSmall: label,
      );
    }
    return TextTheme(
      titleLarge: titleLarge.copyWith(color: AppColors.darkTextPrimary),
      titleMedium: titleMedium.copyWith(color: AppColors.darkTextPrimary),
      bodyLarge: bodyLarge.copyWith(color: AppColors.darkTextPrimary),
      bodyMedium: bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      labelSmall: label.copyWith(color: AppColors.darkTextSecondary),
    );
  }
}
