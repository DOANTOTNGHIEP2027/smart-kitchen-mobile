import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/family_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_roster.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_tier.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/invite_result.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/family_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/family_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/scenes/profile/tier_upgrade_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/change_role_sheet.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/household_plan_strip.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/tier_widgets.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';

HouseholdMember member(String id, String role) => HouseholdMember(
      userId: id,
      fullName: 'Người $id',
      role: role,
      provider: 'EMAIL',
      joinedAt: DateTime.utc(2026, 1, 1),
    );

HouseholdRoster roster({String callerRole = 'OWNER', List<HouseholdMember>? members}) {
  final list = members ?? <HouseholdMember>[member('me', 'OWNER'), member('a', 'MEMBER')];
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
    return TierUpdateResult(householdId: 'h1', tier: tier, requiresTokenRefresh: true);
  }

  @override
  Future<InviteResult> createInvite() => throw UnimplementedError();

  @override
  Future<void> removeMember(String userId) => throw UnimplementedError();
}

class _NoopHealthApi implements HealthApi {
  @override
  Future<List<Allergen>> getAllergenCatalog() => throw UnimplementedError();
  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) => throw UnimplementedError();
  @override
  Future<HealthProfile> getMyHealthProfile() => throw UnimplementedError();
  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) => throw UnimplementedError();
  @override
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late TokenStorage tokenStorage;
  late AppDatabase db;
  late FakeHttpAdapter refreshAdapter;

  /// Claim `tier` mà lần `/auth/refresh` kế tiếp sẽ trả.
  String? nextTier;
  bool refreshFails = false;

  setUp(() {
    storageChannel.install();
    tokenStorage = TokenStorage();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    nextTier = 'PREMIUM';
    refreshFails = false;
    refreshAdapter = FakeHttpAdapter((_) async {
      if (refreshFails) return jsonResponse(500, errorEnvelope('ERR_SERVER', 'down'));
      return jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            'accessToken': fakeJwt(<String, dynamic>{
              'sub': 'me',
              'household_id': 'h1',
              'role': 'OWNER',
              if (nextTier != null) 'tier': nextTier,
            }),
            'refreshToken': 'refresh-2',
            'expiresIn': 900,
          }));
    });
  });
  tearDown(() async {
    storageChannel.uninstall();
    await db.close();
    Get.reset();
  });

  Future<SessionStore> session({String? tier = 'FREE', String role = 'OWNER'}) async {
    await tokenStorage.saveTokens('access-1', 'refresh-1');
    final s = SessionStore(
      tokenStorage,
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = refreshAdapter),
    );
    s.currentUser = const UserSummary(id: 'me', fullName: 'Tôi');
    s.applyRefreshedClaims(fakeJwt(<String, dynamic>{
      'sub': 'me',
      'household_id': 'h1',
      'role': role,
      if (tier != null) 'tier': tier,
    }));
    return s;
  }

  Future<(FamilyStore, FakeFamilyApi, SessionStore)> store({
    String? tier = 'FREE',
    HouseholdRoster? r,
    bool load = true,
  }) async {
    final api = FakeFamilyApi();
    if (r != null) api.current = r;
    final s = await session(tier: tier, role: r?.callerRole ?? 'OWNER');
    final st = FamilyStore(api, _NoopHealthApi(), ReadCacheDao(db), s);
    if (load) await st.loadRoster();
    return (st, api, s);
  }

  group('Domain', () {
    test('fromApi 3 nhánh; unknown fail-safe về 1 ghế (Guard 2)', () {
      expect(HouseholdTier.fromApi('FREE'), HouseholdTier.free);
      expect(HouseholdTier.fromApi('PREMIUM'), HouseholdTier.premium);
      expect(HouseholdTier.fromApi('gold'), HouseholdTier.unknown);
      expect(HouseholdTier.fromApi(null), HouseholdTier.unknown);
      expect(HouseholdTier.unknown.remoteViewerSeatLimit, 1);
      expect(() => HouseholdTier.unknown.toWire(), throwsStateError);
    });

    test('isFull đúng ở biên used == limit và used > limit', () {
      expect(const RemoteViewerSeatInfo(used: 0, tier: HouseholdTier.free).isFull, isFalse);
      expect(const RemoteViewerSeatInfo(used: 1, tier: HouseholdTier.free).isFull, isTrue);
      expect(const RemoteViewerSeatInfo(used: 2, tier: HouseholdTier.free).isFull, isTrue);
      expect(const RemoteViewerSeatInfo(used: 4, tier: HouseholdTier.premium).isFull, isFalse);
    });

    test('TierUpdateResult đọc camelCase thật của BE', () {
      final r = TierUpdateResult.fromJson(<String, dynamic>{
        'householdId': 'h1',
        'tier': 'PREMIUM',
        'requiresTokenRefresh': true,
      });
      expect(r.tier, HouseholdTier.premium);
      expect(r.requiresTokenRefresh, isTrue);
    });
  });

  group('FamilyApiImpl', () {
    test('changeRole PATCH đúng path/body, chấp nhận 204; updateTier gửi FREE/PREMIUM', () async {
      final adapter = FakeHttpAdapter((o) async => o.path.endsWith('/role')
          ? ResponseBody.fromString('', 204)
          : jsonResponse(200,
              successEnvelope(<String, dynamic>{'householdId': 'h1', 'tier': 'PREMIUM', 'requiresTokenRefresh': true})));
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))..httpClientAdapter = adapter;
      final api = FamilyApiImpl(DioClient.build(tokenStorage: tokenStorage, dio: dio));

      await api.changeRole('u2', 'REMOTE_VIEWER');
      final res = await api.updateTier(HouseholdTier.premium);

      expect(adapter.requests[0].method, 'PATCH');
      expect(adapter.requests[0].path, '/api/v1/households/members/u2/role');
      expect(adapter.requests[0].data, <String, dynamic>{'role': 'REMOTE_VIEWER'});
      expect(adapter.requests[1].path, '/api/v1/households/me/tier');
      expect(adapter.requests[1].data, <String, dynamic>{'tier': 'PREMIUM'});
      expect(res.tier, HouseholdTier.premium);
    });
  });

  group('SessionStore.refreshClaims', () {
    test('decode claim tier mới; lỗi refresh không throw, giữ tier cũ', () async {
      final s = await session(tier: 'FREE');
      expect(s.tier, 'FREE');
      await s.refreshClaims();
      expect(s.tier, 'PREMIUM');

      refreshFails = true;
      await expectLater(s.refreshClaims(), completes);
      expect(s.tier, 'PREMIUM');
    });
  });

  group('FamilyStore', () {
    test('seatInfo đếm REMOTE_VIEWER từ roster + tier JWT', () async {
      final (st, _, _) = await store(r: roster(members: <HouseholdMember>[member('me', 'OWNER'), member('v', 'REMOTE_VIEWER')]));
      expect(st.seatInfo!.used, 1);
      expect(st.seatInfo!.limit, 1);
      expect(st.seatInfo!.isFull, isTrue);
    });

    test('changeRole thành công → success + tải lại roster', () async {
      final (st, api, _) = await store();
      final before = api.rosterCalls;
      expect(await st.changeRole('a', 'REMOTE_VIEWER'), isTrue);
      expect(st.changeRoleStatus, FormStatus.success);
      expect(api.rosterCalls, before + 1);
    });

    test('changeRole giữ submitting tới khi roster tải lại xong (không mở lại nút giữa chừng)', () async {
      final (st, api, _) = await store();
      api.rosterGate = Completer<void>();
      final pending = st.changeRole('a', 'REMOTE_VIEWER');
      await Future<void>.delayed(Duration.zero);
      expect(st.changeRoleStatus, FormStatus.submitting);
      expect(await st.changeRole('a', 'REMOTE_VIEWER'), isFalse);
      api.rosterGate!.complete();
      expect(await pending, isTrue);
      expect(st.changeRoleStatus, FormStatus.success);
      expect(api.calls.where((c) => c.startsWith('role:')).length, 1);
    });

    test('changeRole 403 ERR_TIER_SEAT_LIMIT → isSeatLimitError', () async {
      final (st, api, _) = await store();
      api.changeRoleError = BusinessException('ERR_TIER_SEAT_LIMIT', 'full');
      expect(await st.changeRole('a', 'REMOTE_VIEWER'), isFalse);
      expect(st.isSeatLimitError, isTrue);
    });

    test('changeRole lỗi khác → failure nhưng KHÔNG phải seat-limit', () async {
      final (st, api, _) = await store();
      api.changeRoleError = BusinessException('ERR_HH_007', 'owner');
      expect(await st.changeRole('a', 'MEMBER'), isFalse);
      expect(st.changeRoleStatus, FormStatus.failure);
      expect(st.isSeatLimitError, isFalse);
    });

    test('updateTier thành công → await refresh claim TRƯỚC khi báo success (Guard 4)', () async {
      final (st, _, s) = await store();
      expect(st.tier, HouseholdTier.free);
      expect(await st.updateTier(HouseholdTier.premium), isTrue);
      expect(s.tier, 'PREMIUM');
      expect(st.tier, HouseholdTier.premium);
      expect(st.tierUpdateStatus, FormStatus.success);
    });

    test('updateTier lỗi → failure, KHÔNG gọi refresh', () async {
      final (st, api, _) = await store();
      api.updateTierError = BusinessException('ERR_HH_004', 'forbidden');
      expect(await st.updateTier(HouseholdTier.premium), isFalse);
      expect(st.tierUpdateStatus, FormStatus.failure);
      expect(refreshAdapter.requests, isEmpty);
    });

    test('isRemoteViewer: roster thắng JWT; chưa có roster thì dùng JWT', () async {
      final (st, _, _) = await store(r: roster(callerRole: 'REMOTE_VIEWER'), load: false);
      expect(st.isRemoteViewer, isTrue); // JWT role = REMOTE_VIEWER
      final (st2, api2, _) = await store(load: false);
      api2.current = roster(callerRole: 'MEMBER');
      await st2.loadRoster();
      expect(st2.isRemoteViewer, isFalse);
    });
  });

  group('Widget', () {
    testWidgets('TierUpgradeScreen Premium: roster lỗi → báo rõ cảnh báo ghế có thể thiếu + thử lại', (tester) async {
      await tester.runAsync(() async {
        final (st, api, s) = await store(tier: 'PREMIUM', load: false);
        api.rosterError = ServerException('ERR_SERVER', 'down');
        await st.loadRoster();
        Get.put<FamilyStore>(st);
        Get.put<SessionStore>(s);
      });
      await tester.pumpAppWidget(const TierUpgradeScreen(), wrapInScaffold: false);
      await tester.pump();
      // isOwner fallback JWT khi roster lỗi → vẫn vào được form.
      expect(find.byKey(const ValueKey<String>('tier-roster-error')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('tier-change')), findsOneWidget);
    });

    testWidgets('FamilyScreen: roster lỗi nhưng JWT là REMOTE_VIEWER → banner Chỉ xem vẫn hiện (§10.4)', (tester) async {
      await tester.runAsync(() async {
        final (st, api, _) = await store(r: roster(callerRole: 'REMOTE_VIEWER'), load: false);
        api.rosterError = ServerException('ERR_SERVER', 'down');
        Get.put<FamilyStore>(st);
      });
      await tester.pumpAppWidget(const FamilyScreen(), wrapInScaffold: false);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('remote-viewer-banner')), findsOneWidget);
    });

    testWidgets('FamilyScreen: "Đổi vai trò" chỉ cho OWNER, không trên dòng của mình/OWNER (§10.3)', (tester) async {
      Future<void> pumpFamily(String callerRole) async {
        await tester.runAsync(() async {
          Get.reset();
          final (st, _, _) = await store(
            r: roster(callerRole: callerRole, members: <HouseholdMember>[
              member('me', 'OWNER'),
              member('a', 'MEMBER'),
              member('v', 'REMOTE_VIEWER'),
            ]),
            load: false,
          );
          Get.put<FamilyStore>(st);
        });
        // Key khác nhau → State mới, đọc lại FamilyStore vừa đăng ký.
        await tester.pumpAppWidget(FamilyScreen(key: ValueKey<String>(callerRole)), wrapInScaffold: false);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }

      await pumpFamily('OWNER');
      expect(find.byKey(const ValueKey<String>('member-change-role-a')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('member-change-role-v')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('member-change-role-me')), findsNothing);
      expect(find.byKey(const ValueKey<String>('remote-viewer-banner')), findsNothing);

      await pumpFamily('MEMBER');
      expect(find.byKey(const ValueKey<String>('member-change-role-a')), findsNothing);
      expect(find.byKey(const ValueKey<String>('member-change-role-v')), findsNothing);
    });

    Future<void> pumpSheet(WidgetTester tester, FamilyStore st, HouseholdMember m) async {
      await tester.pumpAppWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeRoleSheet(store: st, member: m, onUpgrade: () {}),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('ChangeRoleSheet: nút Xác nhận khoá khi chưa đổi; hint chỉ khi THÊM MỚI viewer lúc đã đầy', (tester) async {
      late FamilyStore st;
      await tester.runAsync(() async {
        (st, _, _) = await store(r: roster(members: <HouseholdMember>[member('me', 'OWNER'), member('v', 'REMOTE_VIEWER'), member('a', 'MEMBER')]));
      });
      await pumpSheet(tester, st, member('a', 'MEMBER'));
      final confirm = find.descendant(of: find.byKey(const ValueKey<String>('change-role-confirm')), matching: find.byType(ElevatedButton));
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
      expect(find.byKey(const ValueKey<String>('change-role-soft-hint')), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('change-role-REMOTE_VIEWER')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('change-role-soft-hint')), findsOneWidget);
      // Guard 1: hint KHÔNG chặn gửi.
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
    });

    testWidgets('ChangeRoleSheet: member đã là viewer → không hiện hint dù đầy (Guard 10)', (tester) async {
      late FamilyStore st;
      await tester.runAsync(() async {
        (st, _, _) = await store(r: roster(members: <HouseholdMember>[member('me', 'OWNER'), member('v', 'REMOTE_VIEWER')]));
      });
      await pumpSheet(tester, st, member('v', 'REMOTE_VIEWER'));
      expect(find.byKey(const ValueKey<String>('change-role-soft-hint')), findsNothing);
    });

    testWidgets('ChangeRoleSheet: seat-limit → thay toàn bộ sheet bằng upsell; lỗi khác → banner inline', (tester) async {
      late FamilyStore st;
      late FakeFamilyApi api;
      await tester.runAsync(() async {
        (st, api, _) = await store();
      });
      api.changeRoleError = BusinessException('ERR_TIER_SEAT_LIMIT', 'full');
      await pumpSheet(tester, st, member('a', 'MEMBER'));
      await tester.tap(find.byKey(const ValueKey<String>('change-role-REMOTE_VIEWER')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('change-role-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('tier-upsell')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('change-role-REMOTE_VIEWER')), findsNothing);

      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      api.changeRoleError = BusinessException('ERR_HH_007', 'Không thể tự hạ quyền');
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('change-role-REMOTE_VIEWER')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('change-role-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('change-role-error')), findsOneWidget);
      expect(find.text('Không thể tự hạ quyền'), findsOneWidget);
    });

    testWidgets('ChangeRoleSheet: PREMIUM hết ghế → upsell KHÔNG mời nâng lên Premium', (tester) async {
      late FamilyStore st;
      late FakeFamilyApi api;
      await tester.runAsync(() async {
        (st, api, _) = await store(tier: 'PREMIUM');
      });
      api.changeRoleError = BusinessException('ERR_TIER_SEAT_LIMIT', 'full');
      await pumpSheet(tester, st, member('a', 'MEMBER'));
      await tester.tap(find.byKey(const ValueKey<String>('change-role-REMOTE_VIEWER')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('change-role-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('tier-upsell')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('tier-upsell-upgrade')), findsNothing);
    });

    testWidgets('HouseholdPlanStrip: không phải OWNER → nút vẫn CÓ, bị khoá + tooltip (Guard 6)', (tester) async {
      late FamilyStore st;
      await tester.runAsync(() async {
        (st, _, _) = await store(r: roster(callerRole: 'MEMBER'));
      });
      await tester.pumpAppWidget(HouseholdPlanStrip(store: st, onChangePlan: () {}));
      await tester.pump();
      final btn = find.descendant(of: find.byKey(const ValueKey<String>('household-plan-change')), matching: find.byType(ElevatedButton));
      expect(btn, findsOneWidget);
      expect(tester.widget<ElevatedButton>(btn).onPressed, isNull);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('RemoteViewerBanner: visible true/false', (tester) async {
      await tester.pumpAppWidget(const RemoteViewerBanner(visible: true));
      expect(find.byKey(const ValueKey<String>('remote-viewer-banner')), findsOneWidget);
      await tester.pumpAppWidget(const RemoteViewerBanner(visible: false));
      expect(find.byKey(const ValueKey<String>('remote-viewer-banner')), findsNothing);
    });

    testWidgets('TierUpgradeScreen: không phải OWNER → blocked, không có nút đổi gói (Guard 7)', (tester) async {
      await tester.runAsync(() async {
        final (st, _, _) = await store(r: roster(callerRole: 'MEMBER'));
        Get.put<FamilyStore>(st);
        Get.put<SessionStore>(await session(role: 'MEMBER'));
      });
      await tester.pumpAppWidget(const TierUpgradeScreen(), wrapInScaffold: false);
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('tier-owner-only')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('tier-change')), findsNothing);
    });

    testWidgets('TierUpgradeScreen: disclaimer ở banner VÀ dialog; huỷ thì không gọi API; cảnh báo hạ cấp khi >1 viewer', (tester) async {
      late FakeFamilyApi api;
      await tester.runAsync(() async {
        final (st, a, s) = await store(
          tier: 'PREMIUM',
          r: roster(members: <HouseholdMember>[member('me', 'OWNER'), member('v1', 'REMOTE_VIEWER'), member('v2', 'REMOTE_VIEWER')]),
        );
        api = a;
        Get.put<FamilyStore>(st);
        Get.put<SessionStore>(s);
      });
      await tester.pumpAppWidget(const TierUpgradeScreen(), wrapInScaffold: false);
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('tier-disclaimer')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('tier-downgrade-warning')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('tier-change')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('tier-dialog-disclaimer')), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);
    });

    testWidgets('TierUpgradeScreen: refresh claim lỗi → toast vẫn báo tier ĐÍCH, không phải tier cũ', (tester) async {
      refreshFails = true;
      await tester.runAsync(() async {
        final (st, _, s) = await store(tier: 'FREE');
        Get.put<FamilyStore>(st);
        Get.put<SessionStore>(s);
      });
      await tester.pumpAppWidget(const TierUpgradeScreen(), wrapInScaffold: false);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('tier-change')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tier-dialog-confirm')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Đã cập nhật gói household thành Premium'), findsOneWidget);
    });

    testWidgets('TierUpgradeScreen: tier unknown → Thử tải lại; vẫn unknown thì báo đăng nhập lại (Guard 11)', (tester) async {
      nextTier = null; // refresh vẫn không có claim tier
      late SessionStore s;
      await tester.runAsync(() async {
        final (st, _, sess) = await store(tier: null);
        s = sess;
        Get.put<FamilyStore>(st);
        Get.put<SessionStore>(s);
      });
      await tester.pumpAppWidget(const TierUpgradeScreen(), wrapInScaffold: false);
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('tier-unknown')), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey<String>('tier-retry')));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('tier-retry-failed')), findsOneWidget);
      expect(s.tier, isNull);
    });
  });
}
