import 'allergen.dart';
import 'diet_type.dart';
import 'health_profile.dart';
import 'household_member.dart';
import 'household_roster.dart';
import 'invite_result.dart';
import 'member_health_summary.dart';

class HouseholdRosterMapper {
  static HouseholdRoster fromJson(Map<String, dynamic> json) => HouseholdRoster(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerId: json['ownerId'] as String,
        callerRole: json['role'] as String,
        memberCount: (json['memberCount'] as num).toInt(),
        members: (json['members'] as List<dynamic>)
            .map((Object? e) => _memberFromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  static Map<String, dynamic> toJson(HouseholdRoster r) => <String, dynamic>{
        'id': r.id,
        'name': r.name,
        'ownerId': r.ownerId,
        'role': r.callerRole,
        'memberCount': r.memberCount,
        'members': r.members.map(_memberToJson).toList(growable: false),
      };

  static HouseholdMember _memberFromJson(Map<String, dynamic> json) =>
      HouseholdMember(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String,
        provider: json['provider'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );

  static Map<String, dynamic> _memberToJson(HouseholdMember m) =>
      <String, dynamic>{
        'userId': m.userId,
        'fullName': m.fullName,
        'avatarUrl': m.avatarUrl,
        'role': m.role,
        'provider': m.provider,
        'joinedAt': m.joinedAt.toUtc().toIso8601String(),
      };
}

class InviteResultMapper {
  static InviteResult fromJson(Map<String, dynamic> json) => InviteResult(
        code: json['code'] as String,
        link: json['link'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

class MemberHealthSummaryMapper {
  static MemberHealthSummary fromJson(Map<String, dynamic> json) {
    final dietRaw = json['dietType'] as String?;
    return MemberHealthSummary(
      userId: json['userId'] as String,
      dietType: dietRaw == null ? null : dietTypeFromWire(dietRaw),
      allergens: (json['allergens'] as List<dynamic>)
          .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

typedef HealthProfileMapper = HealthProfile;
