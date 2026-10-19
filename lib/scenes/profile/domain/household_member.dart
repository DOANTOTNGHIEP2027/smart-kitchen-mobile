/// Một thành viên trong `HouseholdRoster.members` (OAS HouseholdMemberResponse).
///
/// `provider` là nguồn badge GUEST (`EMAIL | GOOGLE | GUEST`). GUEST sẽ có
/// `fullName` rỗng + `avatarUrl` null tới khi upgrade.
class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.provider,
    required this.joinedAt,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String provider;
  final DateTime joinedAt;
}

/// Value-set `role` mở rộng thêm `REMOTE_VIEWER` (#96) — không đổi type.
extension HouseholdMemberRoleX on HouseholdMember {
  bool get isRemoteViewer => role == 'REMOTE_VIEWER';
}
