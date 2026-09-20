import 'package:flutter/material.dart';

/// Design token — màu (issue #17, fe-app-shell.md §11).
///
/// Bám mock `docs/design/frontend/mockups/*.html` (đối chiếu 2026-09-16):
/// accent cam, surface trắng, nền xám nhạt. Trước đây mặc Material green
/// `#2E7D32` — lệch hoàn toàn so với mock.
abstract class AppColors {
  // Brand — mock dùng accent cam `--accent: #ff7a45`, nút primary có gradient
  // `linear-gradient(135deg, #ff9d6e → #ff7a45)`.
  static const Color primary = Color(0xFFFF7A45);
  static const Color primaryDark = Color(0xFFE85F2A);
  static const Color primaryLight = Color(0xFFFFE4D6);
  static const Color primaryGradientStart = Color(0xFFFF9D6E);
  static const Color secondary = Color(0xFFFF9500);

  // `--bg: #f2f2f5` — nền xám tím nhạt theo mock (trước đây #F6F8F4 xanh nhạt).
  static const Color background = Color(0xFFF2F2F5);
  // `--surface: #ffffff`.
  static const Color surface = Color(0xFFFFFFFF);

  // `--border: #e5e5ea`.
  static const Color border = Color(0xFFE5E5EA);

  // `.btn-secondary` của mock — nền be ấm `#f1eeea` (trắng ngà).
  static const Color secondaryFill = Color(0xFFF1EEEA);

  // `--text: #1c1c1e` — đen gần đen pur.
  static const Color textPrimary = Color(0xFF1C1C1E);
  // `--muted: #8e8e93`.
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFC7C7CC);

  // `--danger: #d64545` (thay Material `#BA1A1A`).
  static const Color error = Color(0xFFD64545);
  static const Color warning = Color(0xFFFF9500);
  static const Color success = Color(0xFF34C759);

  // Bóng nút primary theo mock: `rgba(255,122,64,0.32)` (~ 0x52 alpha).
  static const Color primaryShadow = Color(0x52FF7A45);
}
