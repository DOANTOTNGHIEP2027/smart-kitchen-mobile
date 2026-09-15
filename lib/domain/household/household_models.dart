/// Kết quả `POST /v1/households` (schema `HouseholdResponse`).
class HouseholdCreated {
  const HouseholdCreated({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
  });

  final String id;
  final String name;
  final String ownerId;

  /// Invite code đầu tiên, auto-generate cùng lúc tạo household (8 ký tự).
  final String inviteCode;

  factory HouseholdCreated.fromJson(Map<String, dynamic> json) =>
      HouseholdCreated(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerId: json['ownerId'] as String? ?? '',
        inviteCode: json['inviteCode'] as String,
      );
}

/// Kết quả `GET /v1/households/invites/{code}` (schema `InvitePreviewResponse`).
///
/// `isValid: true` **không** đảm bảo lượt join tiếp theo thành công (race) —
/// không được cache kết quả này.
class InvitePreview {
  const InvitePreview({
    required this.householdName,
    required this.ownerName,
    required this.memberCount,
    required this.expiresAt,
    required this.isValid,
  });

  final String householdName;
  final String ownerName;
  final int memberCount;
  final DateTime? expiresAt;
  final bool isValid;

  factory InvitePreview.fromJson(Map<String, dynamic> json) => InvitePreview(
        householdName: json['householdName'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        memberCount: json['memberCount'] as int? ?? 0,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
        isValid: json['isValid'] as bool? ?? false,
      );
}

/// Kết quả `POST /v1/households/join` (schema `JoinHouseholdResponse`).
class JoinHouseholdResult {
  const JoinHouseholdResult({
    required this.householdId,
    required this.householdName,
    required this.role,
    required this.requiresTokenRefresh,
  });

  final String householdId;
  final String householdName;
  final String role;

  /// Luôn `true` cho luồng join thường — client BẮT BUỘC gọi `/auth/refresh`
  /// để lấy JWT mới mang `household_id` + `role` (S8.11).
  final bool requiresTokenRefresh;

  factory JoinHouseholdResult.fromJson(Map<String, dynamic> json) =>
      JoinHouseholdResult(
        householdId: json['householdId'] as String,
        householdName: json['householdName'] as String? ?? '',
        role: json['role'] as String? ?? 'MEMBER',
        requiresTokenRefresh: json['requiresTokenRefresh'] as bool? ?? true,
      );
}
