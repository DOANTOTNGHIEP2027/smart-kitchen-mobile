import 'household_member.dart';

/// Response GET `/households/me` (OAS HouseholdDetailResponse).
///
/// `callerRole` là role của **chính caller** trong household này — lấy từ field
/// `role` cấp cao nhất của response. Đây là nguồn ƯU TIÊN cho `FamilyStore.isOwner`
/// (Fix MODERATE-2): tươi nhất tại thời điểm `loadRoster()` chạy.
class HouseholdRoster {
  const HouseholdRoster({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.callerRole,
    required this.memberCount,
    required this.members,
  });

  final String id;
  final String name;
  final String ownerId;
  final String callerRole;
  final int memberCount;
  final List<HouseholdMember> members;
}
