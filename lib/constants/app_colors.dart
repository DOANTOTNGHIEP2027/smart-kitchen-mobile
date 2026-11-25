import 'package:flutter/material.dart';

/// Design token — màu (issue #17, fe-app-shell.md §11).
///
/// Bám mock `docs/design/frontend/mockups/*.html` (đối chiếu 2026-09-16):
/// accent cam, surface trắng, nền xám nhạt. Trước đây mặc Material green
/// `#2E7D32` — lệch hoàn toàn so với mock.
abstract class AppColors {
  // Brand — Cam tươi mới (#FF7A45) theo DESIGN_SYSTEM.md và mockups gốc
  static const Color primary = Color(0xFFFF7A45);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFFE65A20);
  static const Color primaryContainer = Color(0xFFFFF2EA); // Soft Warm Peach
  static const Color onPrimaryContainer = Color(0xFF9A3412);
  static const Color primaryLight = Color(0xFFFFE4D6);
  static const Color primaryGradientStart = Color(0xFFFF9D6E); // Legacy fallback
  static const Color secondary = Color(0xFFFF9500);

  // Background & Surfaces — Nền sáng, thoáng, ấm áp (#F8F9FA)
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF4F4F7);
  static const Color surfaceWarm = Color(0xFFFFFBF8);

  // Borders & Dividers — Hairline mảnh tinh tế (#EBEBEF)
  static const Color border = Color(0xFFEBEBEF);

  // Secondary fill
  static const Color secondaryFill = Color(0xFFF1EEEA);

  // Typography
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFA1A1AA);

  // Semantic Status
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFDECEC);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSurface = Color(0xFFFEF7EA);
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFEAF7EE);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // Ambient Soft Shadows (Không gắt, không gradient)
  static const Color primaryShadow = Color(0x2EFF7A45);
  static const Color ambientShadow = Color(0x08000000);

  // Sage green tokens
  static const Color sage = Color(0xFF4A7C59);
  static const Color sageDark = Color(0xFF385E43);
  static const Color sageLight = Color(0xFFEFF6F0);
  static const Color sageBorder = Color(0xFFCFE2D3);
  static const Color sageSurface = Color(0xFFF7FAF8);

  // Nutrition compliance (DESIGN_SYSTEM.md §2.4, nutrition-summary-widget.md §9)
  static const Color nutritionExcellent = Color(0xFF2E7D32);
  static const Color nutritionGood = Color(0xFF1565C0);
  static const Color nutritionNeedsImprovement = Color(0xFFD97706);
  static const Color nutritionPoor = Color(0xFFC62828);
  static const Color macroProtein = Color(0xFF4C6FFF);
  static const Color macroCarbs = Color(0xFFFF9F43);
  static const Color macroFat = Color(0xFFEF5350);

  // Scrim cho LoadingOverlay (design-system.md §5)
  static const Color scrim = Color(0x52000000);

  // Dark theme — chỉ phần nền (design-system.md §4.1). Màn feature chưa
  // migrate nên app vẫn mặc định ThemeMode.light.
  static const Color darkPrimaryContainer = Color(0xFF3A2418);
  static const Color darkOnPrimaryContainer = Color(0xFFFFB899);
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1C1C1F);
  static const Color darkSurfaceSubtle = Color(0xFF26262A);
  static const Color darkBorder = Color(0xFF2E2E33);
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextDisabled = Color(0xFF6B6B73);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkErrorSurface = Color(0xFF3B1D1D);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkWarningSurface = Color(0xFF33270F);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkSuccessSurface = Color(0xFF16301F);
  static const Color darkInfo = Color(0xFF60A5FA);
  static const Color darkInfoSurface = Color(0xFF172338);
  static const Color darkPrimaryShadow = Color(0x00000000);
  static const Color darkAmbientShadow = Color(0x00000000);
  static const Color darkScrim = Color(0x99000000);
}
