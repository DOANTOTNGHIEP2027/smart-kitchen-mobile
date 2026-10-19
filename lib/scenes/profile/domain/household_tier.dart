/// Gói của household (tier-gate-screens.md §5.1). Đọc từ JWT claim `tier` —
/// `GET /households/me` KHÔNG trả field này (Guard 5).
enum HouseholdTier {
  free,
  premium,

  /// Claim thiếu/lạ — fail-safe về giới hạn THẤP NHẤT, không fail-open (Guard 2).
  unknown;

  static HouseholdTier fromApi(String? raw) => switch (raw) {
        'FREE' => HouseholdTier.free,
        'PREMIUM' => HouseholdTier.premium,
        _ => HouseholdTier.unknown,
      };

  String toWire() => switch (this) {
        HouseholdTier.free => 'FREE',
        HouseholdTier.premium => 'PREMIUM',
        HouseholdTier.unknown =>
          throw StateError('Không thể gửi tier "unknown" lên BE'),
      };

  /// FREE=1, PREMIUM=5 — mirror enum `HouseholdTier` của BE. CHỈ là hint hiển
  /// thị; seat-limit thật luôn do BE quyết (`403 ERR_TIER_SEAT_LIMIT`).
  int get remoteViewerSeatLimit => switch (this) {
        HouseholdTier.free => 1,
        HouseholdTier.premium => 5,
        HouseholdTier.unknown => 1,
      };
}

/// `PATCH /households/me/tier` → `HouseholdTierResponse` (camelCase thật của
/// BE, không phải snake_case như bản thiết kế §7.1).
class TierUpdateResult {
  const TierUpdateResult({
    required this.householdId,
    required this.tier,
    required this.requiresTokenRefresh,
  });

  final String householdId;
  final HouseholdTier tier;
  final bool requiresTokenRefresh;

  factory TierUpdateResult.fromJson(Map<String, dynamic> json) =>
      TierUpdateResult(
        householdId: json['householdId'] as String,
        tier: HouseholdTier.fromApi(json['tier'] as String?),
        requiresTokenRefresh: json['requiresTokenRefresh'] as bool? ?? true,
      );
}

/// Hint số ghế Remote Viewer — dựng từ roster đã tải + tier JWT, KHÔNG bao giờ
/// dùng để chặn cứng (Guard 1).
class RemoteViewerSeatInfo {
  const RemoteViewerSeatInfo({required this.used, required this.tier});

  final int used;
  final HouseholdTier tier;

  int get limit => tier.remoteViewerSeatLimit;
  bool get isFull => used >= limit;
}
