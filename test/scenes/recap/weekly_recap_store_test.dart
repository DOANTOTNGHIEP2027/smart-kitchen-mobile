import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/recap_api.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/household_streak.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/recap_badge.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/weekly_recap_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recap/stores/weekly_recap_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';

class FakeRecapApi implements RecapApi {
  WeeklyRecapSummary? summary;
  HouseholdStreak? streak;
  ApiException? weeklyError;
  ApiException? streakError;
  int streakCalls = 0;

  WeeklyRecapSummary defaultSummary() => WeeklyRecapSummary(
        householdId: 'h1',
        weekStart: DateTime(2026, 3, 2),
        mealsLoggedCount: 12,
        avgCaloriesKcal: 1900,
        adherencePercent: 88,
        memberInsights: <MemberWeeklyInsight>[
          _insight('self'),
          _insight('other'),
        ],
        householdSummary: 'Cả nhà tốt',
        suggestedFocus: 'Rau',
        isStale: false,
        computedAt: DateTime.utc(2026, 3, 8, 7),
      );

  static MemberWeeklyInsight _insight(String id) => MemberWeeklyInsight(
        memberId: id,
        calorieAvg: 1800,
        calorieGoal: 2000,
        compliancePct: 95,
        badge: RecapBadge.onTrack,
        topNutrientGap: 'protein',
        highlight: 'highlight $id',
        tip: 'tip $id',
      );

  @override
  Future<WeeklyRecapSummary> getWeeklyRecap() {
    if (weeklyError != null) throw weeklyError!;
    return Future.value(summary ?? defaultSummary());
  }

  @override
  Future<HouseholdStreak> getHouseholdStreak({required String memberId}) {
    streakCalls++;
    if (streakError != null) throw streakError!;
    return Future.value(
      streak ??
          const HouseholdStreak(
            householdId: 'h1',
            currentStreak: 4,
            bestStreak: 9,
            lastComputedWeekStart: null,
          ),
    );
  }
}

void main() {
  late FakeRecapApi api;
  late SessionStore session;

  SessionStore makeSession({String? householdId = 'h1', bool withUser = true}) {
    final s = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(
        Dio(BaseOptions(baseUrl: 'https://test.local'))
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          ),
      ),
    );
    if (withUser) {
      s.currentUser = const UserSummary(id: 'self', fullName: 'Me');
    }
    if (householdId != null) {
      s.applyHouseholdContext(householdId: householdId, role: 'MEMBER');
    }
    return s;
  }

  setUp(() {
    api = FakeRecapApi();
    session = makeSession();
  });

  test('fetchAll thành công → ready, ownInsight khớp self, streak ready', () async {
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();

    expect(store.status, RecapLoadStatus.ready);
    expect(store.summary!.mealsLoggedCount, 12);
    expect(store.ownInsight!.memberId, 'self');
    expect(store.orderedMemberInsights, hasLength(2));
    expect(store.isLoading, isFalse);
    expect(store.streak!.currentStreak, 4);
    expect(store.streakStatus, RecapLoadStatus.ready);
  });

  test('isStale=true vẫn ready (Guard #3) + ownInsight null + empty insights',
      () async {
    api.summary = WeeklyRecapSummary(
      householdId: 'h1',
      weekStart: DateTime(2026, 3, 2),
      mealsLoggedCount: 8,
      avgCaloriesKcal: 700,
      adherencePercent: 60,
      memberInsights: <MemberWeeklyInsight>[],
      householdSummary: null,
      suggestedFocus: null,
      isStale: true,
      computedAt: DateTime.utc(2026, 3, 8, 7),
    );
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();

    // KHÔNG phải lỗi — chỉ phần AI rơi vào fallback.
    expect(store.status, RecapLoadStatus.ready);
    expect(store.summary!.isStale, isTrue);
    expect(store.ownInsight, isNull);
    expect(store.orderedMemberInsights, isEmpty);
  });

  test('householdId == null → noHousehold, KHÔNG gọi API (Guard #9)', () async {
    session = makeSession(householdId: null);
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();

    expect(store.status, RecapLoadStatus.noHousehold);
    expect(api.streakCalls, 0); // không gọi bất kỳ endpoint nào
  });

  test('weekly lỗi → error, streak vẫn ready (2 nhóm độc lập, Guard #7)',
      () async {
    api.weeklyError = ServerException('ERR_SERVER', 'boom');
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();

    expect(store.status, RecapLoadStatus.error);
    // streak không bị ảnh hưởng bởi lỗi weekly.
    expect(store.streakStatus, RecapLoadStatus.ready);
    expect(store.streak, isNotNull);
  });

  test('ERR_RECAP_NOT_FOUND → empty (case 3)', () async {
    api.weeklyError = throwBusiness('ERR_RECAP_NOT_FOUND');
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();
    expect(store.status, RecapLoadStatus.empty);
  });

  test('streak lỗi độc lập → streakStatus error, weekly vẫn ready (state 8)',
      () async {
    api.streakError = ServerException('ERR_SERVER', 'net fail');
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();

    expect(store.status, RecapLoadStatus.ready); // phần chính không đổi
    expect(store.streakStatus, RecapLoadStatus.error);
    expect(store.streak, isNull);
  });

  test('currentUser == null → streak error, KHÔNG gọi streak API (Guard #11)',
      () async {
    session = makeSession(withUser: false);
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();

    // weekly vẫn chạy bình thường.
    expect(store.status, RecapLoadStatus.ready);
    expect(store.ownInsight, isNull);
    // streak: self null → error không gọi API.
    expect(store.streakStatus, RecapLoadStatus.error);
    expect(api.streakCalls, 0);
  });

  test('retryStreak: chỉ retry nhánh streak, không đụng weekly', () async {
    api.streakError = ServerException('ERR_SERVER', 'net fail');
    final store = WeeklyRecapStore(api, session);
    await store.fetchAll();
    expect(store.streakStatus, RecapLoadStatus.error);

    api.streakError = null;
    store.retryStreak();
    await Future<void>.delayed(Duration.zero);

    expect(store.streakStatus, RecapLoadStatus.ready);
    expect(store.streak!.bestStreak, 9);
    expect(store.status, RecapLoadStatus.ready); // weekly không đổi
  });
}

// Tạo BusinessException theo class thật để test mã `when (e.code == ...)`.
BusinessException throwBusiness(String code) =>
    BusinessException(code, 'msg');