class HouseholdCreated {
  const HouseholdCreated(
      {required this.id, required this.name, required this.inviteCode});

  final String id;
  final String name;
  final String inviteCode;

  factory HouseholdCreated.fromJson(Map<String, dynamic> json) =>
      HouseholdCreated(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['inviteCode'] as String,
      );
}

class InvitePreview {
  const InvitePreview({
    required this.householdName,
    required this.ownerName,
    required this.memberCount,
    required this.expiresAt,
    required this.isValid,
    this.isFull = false,
  });

  final String householdName;
  final String ownerName;
  final int memberCount;
  final DateTime expiresAt;
  final bool isValid;

  /// Nhà đã đủ 10 thành viên (contract `household-invite-role.yaml`, OD-54)
  /// → S8.12, không cho bấm "Tham gia".
  final bool isFull;

  /// Chịu được response "mã hết hạn / đã dùng" của BE: `200 isValid:false`
  /// với `householdName`/`ownerName`/`expiresAt` null (review v2 H3).
  factory InvitePreview.fromJson(Map<String, dynamic> json) => InvitePreview(
        householdName: json['householdName'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        isValid: json['isValid'] == true,
        isFull: json['isFull'] == true,
      );
}

class HouseholdJoinResult {
  const HouseholdJoinResult({
    required this.householdId,
    required this.householdName,
    required this.role,
    required this.requiresTokenRefresh,
  });

  final String householdId;
  final String householdName;
  final String role;
  final bool requiresTokenRefresh;

  factory HouseholdJoinResult.fromJson(Map<String, dynamic> json) =>
      HouseholdJoinResult(
        householdId: json['householdId'] as String,
        householdName: json['householdName'] as String,
        role: json['role'] as String,
        requiresTokenRefresh: json['requiresTokenRefresh'] == true,
      );
}
