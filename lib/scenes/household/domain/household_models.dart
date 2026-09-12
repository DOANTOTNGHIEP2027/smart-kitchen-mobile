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
  });

  final String householdName;
  final String ownerName;
  final int memberCount;
  final DateTime expiresAt;
  final bool isValid;

  factory InvitePreview.fromJson(Map<String, dynamic> json) => InvitePreview(
        householdName: json['householdName'] as String,
        ownerName: json['ownerName'] as String,
        memberCount: (json['memberCount'] as num).toInt(),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isValid: json['isValid'] == true,
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
