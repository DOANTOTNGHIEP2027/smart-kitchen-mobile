import 'package:flutter/material.dart';

import '../domain/recap_badge.dart';

/// Bảng màu badge chuẩn hóa theo DESIGN_SYSTEM.md và UI/UX Pro Max.
/// Sử dụng bảng màu ấm, tươi mới, có độ tương phản cao và hỗ trợ màu nền mềm (container).
abstract class RecapBadgeColors {
  static Color of(RecapBadge badge) => switch (badge) {
        RecapBadge.greatWeek => const Color(0xFFF59E0B), // Vàng cam ấm áp / Xuất sắc
        RecapBadge.onTrack => const Color(0xFF10B981),   // Xanh ngọc tươi mới / Đạt chuẩn
        RecapBadge.under => const Color(0xFFFF7A45),     // Cam hệ thống / Cần nỗ lực
        RecapBadge.over => const Color(0xFFEF4444),      // Đỏ san hô / Vượt mức
        RecapBadge.unknown => const Color(0xFF94A3B8),   // Xám phiến mềm
      };

  static Color containerOf(RecapBadge badge) => switch (badge) {
        RecapBadge.greatWeek => const Color(0xFFFEF3C7),
        RecapBadge.onTrack => const Color(0xFFEAF7EE),
        RecapBadge.under => const Color(0xFFFFF2EA),
        RecapBadge.over => const Color(0xFFFDECEC),
        RecapBadge.unknown => const Color(0xFFF1F5F9),
      };

  static Color trackOf(RecapBadge badge) => switch (badge) {
        RecapBadge.greatWeek => const Color(0xFFFDE68A).withValues(alpha: 0.6),
        RecapBadge.onTrack => const Color(0xFFA7F3D0).withValues(alpha: 0.6),
        RecapBadge.under => const Color(0xFFFFD8C2).withValues(alpha: 0.6),
        RecapBadge.over => const Color(0xFFFECACA).withValues(alpha: 0.6),
        RecapBadge.unknown => const Color(0xFFE2E8F0),
      };

  static String labelOf(RecapBadge badge) => switch (badge) {
        RecapBadge.greatWeek => 'Xuất sắc',
        RecapBadge.onTrack => 'Đạt mục tiêu',
        RecapBadge.under => 'Cần tăng thêm',
        RecapBadge.over => 'Vượt chỉ tiêu',
        RecapBadge.unknown => 'Đang theo dõi',
      };
}
