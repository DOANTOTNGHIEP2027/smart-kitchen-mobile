import 'package:flutter/material.dart';

/// Design token — màu (issue #17, fe-app-shell.md §11).
///
/// Đây là bộ giá trị mặc định hợp lý, chưa phải design-system đã sign-off.
/// Cái quan trọng là *hình dạng*: một nguồn token duy nhất được
/// [AppTheme] tiêu thụ, không phải các mã hex cụ thể.
abstract class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFFA5D6A7);
  static const Color secondary = Color(0xFFFF8F00);

  static const Color background = Color(0xFFF6F8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE1E5DD);

  static const Color textPrimary = Color(0xFF1B1C19);
  static const Color textSecondary = Color(0xFF5E6358);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFF9AA093);

  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFE65100);
  static const Color success = Color(0xFF2E7D32);
}
