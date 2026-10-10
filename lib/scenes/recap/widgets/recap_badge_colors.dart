import 'package:flutter/material.dart';

import '../domain/recap_badge.dart';

/// Bảng màu badge cố định theo issue #86 (weekly-recap-screen.md §9.3).
abstract class RecapBadgeColors {
  static Color of(RecapBadge badge) => switch (badge) {
        RecapBadge.greatWeek => const Color(0xFFFFB300),
        RecapBadge.onTrack => const Color(0xFF2E7D32),
        RecapBadge.under => const Color(0xFFF57C00),
        RecapBadge.over => const Color(0xFFC62828),
        RecapBadge.unknown => const Color(0xFF9E9E9E),
      };
}