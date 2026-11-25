import 'dart:async';

import 'package:smart_kitchen_mobile/domain/shared/budget_period.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/family_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_budget.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_roster.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_tier.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/invite_result.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';

/// Fake dùng chung cho test Gia đình (tier_gate_test, family_store_test,
/// family_screen_test, member_detail_screen_test).
HouseholdMember member(String id, String role, {String provider = 'EMAIL'}) =>
    HouseholdMember(
      userId: id,
      fullName: 'Người $id',
      role: role,
      provider: provider,
      joinedAt: DateTime.utc(2026, 1, 1),
    );

HouseholdRoster roster(
    {String callerRole = 'OWNER', List<HouseholdMember>? members}) {
  final list = members ??
      <HouseholdMember>[member('me', 'OWNER'), member('a', 'MEMBER')];
  return HouseholdRoster(
    id: 'h1',
    name: 'Nhà',
    ownerId: 'me',
    callerRole: callerRole,
    memberCount: list.length,
    members: list,
  );
}

class FakeFamilyApi implements FamilyApi {
  HouseholdRoster current = roster();
  Object? changeRoleError;
  Object? updateTierError;
  int rosterCalls = 0;
  Object? rosterError;
  final List<String> calls = <String>[];
  Completer<void>? changeRoleGate;
  Completer<void>? rosterGate;

  @override
  Future<HouseholdRoster> getMyHousehold() async {
    rosterCalls++;
    await rosterGate?.future;
    if (rosterError != null) throw rosterError!;
    return current;
  }

  @override
  Future<void> changeRole(String userId, String role) async {
    calls.add('role:$userId:$role');
    await changeRoleGate?.future;
    if (changeRoleError != null) throw changeRoleError!;
  }

  @override
  Future<TierUpdateResult> updateTier(HouseholdTier tier) async {
    calls.add('tier:${tier.toWire()}');
    if (updateTierError != null) throw updateTierError!;
    return TierUpdateResult(
        householdId: 'h1', tier: tier, requiresTokenRefresh: true);
  }

  HouseholdBudget budget = const HouseholdBudget(period: BudgetPeriod.unknown);
  Object? budgetError;
  Object? upsertError;
  int budgetCalls = 0;
  Completer<void>? budgetGate;
  Completer<void>? upsertGate;
  final List<(BudgetPeriod, double)> upserts = <(BudgetPeriod, double)>[];

  @override
  Future<HouseholdBudget> getBudget() async {
    budgetCalls++;
    await budgetGate?.future;
    if (budgetError != null) throw budgetError!;
    return budget;
  }

  @override
  Future<HouseholdBudget> upsertBudget(
      {required BudgetPeriod period, required double amount}) async {
    upserts.add((period, amount));
    await upsertGate?.future;
    if (upsertError != null) throw upsertError!;
    budget = HouseholdBudget(period: period, amount: amount, currency: 'VND');
    return budget;
  }

  InviteResult invite = InviteResult(
    code: 'K7Q2M9XA',
    link: 'https://app.smartkitchen.vn/join/K7Q2M9XA',
    expiresAt: DateTime.now().toUtc().add(const Duration(days: 3)),
  );
  Object? inviteError;
  Completer<void>? inviteGate;

  @override
  Future<InviteResult> createInvite() async {
    calls.add('invite');
    await inviteGate?.future;
    if (inviteError != null) throw inviteError!;
    return invite;
  }

  Object? removeError;
  Completer<void>? removeGate;

  /// Thành công → server bỏ thành viên khỏi [current] (như BE thật).
  @override
  Future<void> removeMember(String userId) async {
    calls.add('remove:$userId');
    await removeGate?.future;
    if (removeError != null) throw removeError!;
    final members = current.members
        .where((m) => m.userId != userId)
        .toList(growable: false);
    current = roster(callerRole: current.callerRole, members: members);
  }
}

class FakeHealthApi implements HealthApi {
  MemberHealthSummary summary =
      const MemberHealthSummary(userId: 'a', allergens: <Allergen>[]);
  Object? summaryError;
  final List<String> summaryReads = <String>[];

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) async {
    summaryReads.add(userId);
    if (summaryError != null) throw summaryError!;
    return summary;
  }

  @override
  Future<List<Allergen>> getAllergenCatalog() => throw UnimplementedError();
  @override
  Future<HealthProfile> getMyHealthProfile() => throw UnimplementedError();
  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) =>
      throw UnimplementedError();
  @override
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload) =>
      throw UnimplementedError();
}
