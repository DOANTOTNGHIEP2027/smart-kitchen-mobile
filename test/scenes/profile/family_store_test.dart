import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_roster.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/profile_mappers.dart';
import 'package:smart_kitchen_mobile/scenes/profile/family_error_l10n.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/family_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import 'family_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late AppDatabase db;
  final vi = lookupAppLocalizations(const Locale('vi'));

  setUp(() {
    storageChannel.install();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    storageChannel.uninstall();
    await db.close();
  });

  Future<SessionStore> session(String role) async {
    final s = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
    );
    s.currentUser = const UserSummary(id: 'me', fullName: 'Tôi');
    s.applyRefreshedClaims(fakeJwt(<String, dynamic>{
      'sub': 'me',
      'household_id': 'h1',
      'role': role,
    }));
    return s;
  }

  Future<(FamilyStore, FakeFamilyApi)> store({
    HouseholdRoster? r,
    bool load = true,
  }) async {
    final api = FakeFamilyApi();
    if (r != null) api.current = r;
    final s = await session(r?.callerRole ?? 'OWNER');
    final st = FamilyStore(api, FakeHealthApi(), ReadCacheDao(db), s);
    if (load) await st.loadRoster();
    return (st, api);
  }

  final threeMembers = <HouseholdMember>[
    member('me', 'OWNER'),
    member('a', 'MEMBER'),
    member('v', 'REMOTE_VIEWER'),
  ];

  List<String> ids(FamilyStore st) =>
      (st.rosterState as SuccessState<HouseholdRoster>)
          .data
          .members
          .map((m) => m.userId)
          .toList();

  group('canRemove / canInvite', () {
    test('OWNER: true cho MEMBER và REMOTE_VIEWER; false cho mình và OWNER',
        () async {
      final (st, _) = await store(
          r: roster(members: <HouseholdMember>[
        ...threeMembers,
        member('o2', 'OWNER'),
      ]));
      expect(st.canInvite, isTrue);
      expect(st.canRemove(member('a', 'MEMBER')), isTrue);
      expect(st.canRemove(member('v', 'REMOTE_VIEWER')), isTrue);
      expect(st.canRemove(member('me', 'OWNER')), isFalse);
      expect(st.canRemove(member('o2', 'OWNER')), isFalse);
    });

    test('caller không phải OWNER → false hết', () async {
      final (st, _) = await store(r: roster(callerRole: 'MEMBER'));
      expect(st.canInvite, isFalse);
      expect(st.canRemove(member('a', 'MEMBER')), isFalse);
    });

    test('roster từ cache → chỉ đọc (Guard 13)', () async {
      final (st, api) = await store();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      api.rosterError = NetworkException();
      await st.loadRoster();
      expect(st.rosterIsFromCache, isTrue);
      expect(st.canInvite, isFalse);
      expect(st.canRemove(member('a', 'MEMBER')), isFalse);
      expect(await st.createInvite(), isFalse);
      expect(api.calls, isNot(contains('invite')));
    });
  });

  group('removeMember', () {
    test('thành công → dòng biến mất, KHÔNG nháy Loading, cờ mời không đổi',
        () async {
      final (st, api) = await store(r: roster(members: threeMembers));
      final seen = <String>[];
      final dispose =
          autorun((_) => seen.add(st.rosterState.runtimeType.toString()));
      final ok = await st.removeMember('a');
      dispose();
      expect(ok, isTrue);
      expect(api.calls, contains('remove:a'));
      expect(ids(st), <String>['me', 'v']);
      expect(seen.where((t) => t.startsWith('LoadingState')), isEmpty);
      expect(st.removeMemberStatus, FormStatus.success);
      expect(st.inviteStatus, FormStatus.idle);
    });

    test('đang gửi → removeMemberStatus submitting, inviteStatus vẫn idle',
        () async {
      final (st, api) = await store(r: roster(members: threeMembers));
      api.removeGate = Completer<void>();
      final pending = st.removeMember('a');
      expect(st.isRemovingMember, isTrue);
      expect(st.inviteStatus, FormStatus.idle);
      api.removeGate!.complete();
      await pending;
      expect(st.isRemovingMember, isFalse);
    });

    test('M3 — vẫn submitting tới khi nạp lại roster xong', () async {
      final (st, api) = await store(r: roster(members: threeMembers));
      api.rosterGate = Completer<void>();
      final pending = st.removeMember('a');
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, contains('remove:a'));
      expect(ids(st), <String>['me', 'v'], reason: 'vá roster ngay');
      expect(st.isRemovingMember, isTrue, reason: 'nút Xóa còn khoá');
      expect(await st.removeMember('a'), isFalse);
      api.rosterGate!.complete();
      expect(await pending, isTrue);
      expect(st.removeMemberStatus, FormStatus.success);
      expect(api.calls.where((c) => c.startsWith('remove')), hasLength(1));
    });

    test('canRemove false → trả false, KHÔNG gọi API', () async {
      final (st, api) = await store(
          r: roster(members: <HouseholdMember>[
        ...threeMembers,
        member('o2', 'OWNER'),
      ]));
      expect(await st.removeMember('me'), isFalse); // chính mình
      expect(await st.removeMember('o2'), isFalse); // dòng OWNER
      expect(await st.removeMember('ghost'), isFalse); // không có trong roster
      expect(api.calls.where((c) => c.startsWith('remove')), isEmpty);

      final (memberStore, memberApi) =
          await store(r: roster(callerRole: 'MEMBER'));
      expect(await memberStore.removeMember('a'), isFalse); // không phải OWNER
      expect(memberApi.calls, isEmpty);
    });

    test('roster từ cache → không gọi API', () async {
      final (st, api) = await store();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      api.rosterError = NetworkException();
      await st.loadRoster();
      expect(await st.removeMember('a'), isFalse);
      expect(api.calls, isEmpty);
    });

    for (final code in <String>['ERR_HH_007', 'ERR_HH_004']) {
      test('lỗi BE $code → failure + tải lại roster + copy theo code',
          () async {
        final (st, api) = await store();
        api.removeError = BusinessException(code, 'English BE message');
        final before = api.rosterCalls;
        expect(await st.removeMember('a'), isFalse);
        expect(st.removeMemberStatus, FormStatus.failure);
        expect(st.mutationError?.code, code);
        expect(api.rosterCalls, before + 1);
        // Roster vẫn hiển thị (nạp nền), không về Loading/Error.
        expect(st.rosterState, isA<SuccessState<HouseholdRoster>>());
        final copy = familyErrorMessage(vi, st.mutationError);
        expect(copy, isNot(contains('English')));
        expect(
            copy,
            code == 'ERR_HH_004'
                ? vi.familyErrorNotOwner
                : vi.familyErrorCannotRemove);
      });
    }

    test('mất mạng → failure, KHÔNG tải lại', () async {
      final (st, api) = await store();
      api.removeError = NetworkException();
      final before = api.rosterCalls;
      expect(await st.removeMember('a'), isFalse);
      expect(st.removeMemberStatus, FormStatus.failure);
      expect(api.rosterCalls, before);
      expect(familyErrorMessage(vi, st.mutationError), vi.networkError);
    });
  });

  group('createInvite', () {
    test('thành công → lưu lastInvite; clearInviteError giữ lastInvite',
        () async {
      final (st, api) = await store();
      expect(await st.createInvite(), isTrue);
      expect(st.inviteStatus, FormStatus.success);
      expect(st.lastInvite?.code, api.invite.code);
      expect(st.lastInvite?.link, api.invite.link);
      st.clearInviteError();
      expect(st.inviteStatus, FormStatus.idle);
      expect(st.lastInvite, isNotNull);
    });

    test('429 ERR_HH_006 → failure, copy giới hạn theo code, KHÔNG tải lại',
        () async {
      final (st, api) = await store();
      api.inviteError = BusinessException(
          'ERR_HH_006', 'Maximum active invite limit reached (3)');
      final before = api.rosterCalls;
      expect(await st.createInvite(), isFalse);
      expect(st.inviteStatus, FormStatus.failure);
      expect(st.mutationError?.code, 'ERR_HH_006');
      expect(
          familyErrorMessage(vi, st.mutationError), vi.familyErrorInviteLimit);
      expect(api.rosterCalls, before);
    });

    test('403 ERR_HH_004 → copy "không còn quyền" + tải lại → ẩn quản lý',
        () async {
      final (st, api) = await store();
      api.inviteError = BusinessException(
          'ERR_HH_004', 'Only household owner can create invites');
      api.current = roster(callerRole: 'MEMBER');
      final before = api.rosterCalls;
      expect(await st.createInvite(), isFalse);
      expect(familyErrorMessage(vi, st.mutationError), vi.familyErrorNotOwner);
      expect(api.rosterCalls, before + 1);
      expect(st.isOwner, isFalse);
      expect(st.canInvite, isFalse);
    });

    test('mã lạ → genericRetryError, không lộ message BE', () {
      expect(familyErrorMessage(vi, BusinessException('ERR_WHATEVER', 'Boom')),
          vi.genericRetryError);
    });
  });

  group('loadRoster', () {
    test(
        '404 ERR_HH_001 → ErrorState(ERR_HH_001) dù có cache (tín hiệu redirect)',
        () async {
      final (st, api) = await store(load: false);
      await ReadCacheDao(db)
          .put('roster:h1', HouseholdRosterMapper.toJson(roster()));
      api.rosterError = BusinessException('ERR_HH_001', 'Household not found');
      await st.loadRoster();
      final state = st.rosterState;
      expect(state, isA<ErrorState<HouseholdRoster>>());
      expect((state as ErrorState<HouseholdRoster>).error.code, 'ERR_HH_001');
      expect(st.rosterIsFromCache, isFalse);
    });

    test('isOwner: roster thắng JWT; chưa có roster thì dùng JWT', () async {
      final (st, api) = await store(load: false);
      expect(st.isOwner, isTrue); // JWT OWNER
      api.current = roster(callerRole: 'MEMBER');
      await st.loadRoster();
      expect(st.isOwner, isFalse);
    });
  });
}
