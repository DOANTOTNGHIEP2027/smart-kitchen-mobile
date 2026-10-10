import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/insights/data/adherence_api.dart';
import 'package:smart_kitchen_mobile/scenes/insights/data/history_api.dart';
import 'package:smart_kitchen_mobile/scenes/insights/domain/streak_summary.dart';
import 'package:smart_kitchen_mobile/scenes/insights/domain/week_quick_stat.dart';
import 'package:smart_kitchen_mobile/scenes/insights/stores/history_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../../helpers/fake_http_adapter.dart';

class FakeHistoryApi implements HistoryApi {
  Future<List<MealLogEntry>> Function(DateTime from, DateTime to)? onListAll;
  Future<WeekQuickStat> Function(String)? onQuickStat;
  Object? listError;

  @override
  Future<List<MealLogEntry>> listAllLogsInRange({
    required String memberId,
    required DateTime from,
    required DateTime to,
  }) async {
    if (listError != null) throw listError!;
    if (onListAll != null) return onListAll!(from, to);
    return <MealLogEntry>[];
  }

  @override
  Future<WeekQuickStat> getSelfWeekQuickStat(String memberId) async {
    if (onQuickStat != null) return onQuickStat!(memberId);
    return const WeekQuickStat(avgCaloriesKcal: null, loggedCount: null);
  }
}

class FakeAdherenceApi implements AdherenceApi {
  double? percent;
  Object? error;
  StreakSummary streak = const StreakSummary(
    currentStreak: 0,
    bestStreak: 0,
    lastComputedWeekStart: null,
  );
  final List<DateTime> askedWeeks = <DateTime>[];

  @override
  Future<double?> getWeeklyAdherencePercent(DateTime weekStart) async {
    if (error != null) throw error!;
    askedWeeks.add(weekStart);
    return percent;
  }

  @override
  Future<StreakSummary> getStreak(String memberId) async => streak;
}

class FakeHealthApi implements HealthApi {
  int? target;
  Object? error;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    if (error != null) throw error!;
    return HealthProfile(
      userId: 'self',
      targetDailyCalories: target,
      allergens: const <Allergen>[],
    );
  }

  @override
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload) =>
      throw UnimplementedError();

  @override
  Future<List<Allergen>> getAllergenCatalog() => throw UnimplementedError();

  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) =>
      throw UnimplementedError();

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) =>
      throw UnimplementedError();
}

String _id(String seed) => 'log-$seed';

MealLogEntry _log(String seed, int day, {double cal = 100, int hour = 12}) =>
    MealLogEntry(
      id: _id(seed),
      householdId: 'h1',
      memberId: 'self',
      loggedBy: 'self',
      caloriesKcal: cal,
      nutrition: null,
      requiresConfirmation: false,
      confirmedByUser: true,
      loggedAt: DateTime.utc(2026, 3, day, hour),
      status: MealEntryStatus.saved,
    );

void main() {
  // Clock cố định: hôm nay = 2026-03-20 (VN).
  DateTime now() => DateTime(2026, 3, 20);

  late FakeHistoryApi historyApi;
  late FakeAdherenceApi adherenceApi;
  late FakeHealthApi healthApi;
  late SessionStore session;
  late HistoryStore store;

  setUp(() {
    historyApi = FakeHistoryApi();
    adherenceApi = FakeAdherenceApi();
    healthApi = FakeHealthApi()..target = 2000;
    session = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(
        Dio(BaseOptions(baseUrl: 'https://test.local'))
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          ),
      ),
    );
    session.currentUser = const UserSummary(id: 'self', fullName: 'Me');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    store = HistoryStore(historyApi, adherenceApi, healthApi, session, now: now);
  });

  test('loadMonth: aggregate theo tháng, target + quick stat nạp 1 lần đầu',
      () async {
    historyApi.onListAll = (from, to) async => <MealLogEntry>[
          _log('a', 5, cal: 300),
          _log('b', 5, cal: 200),
        ];
    await store.loadMonth();

    expect(store.targetDailyCalories, 2000);
    expect(store.dailyNutritionState, isA<SuccessState<List<Object>>>());
    final s = store.dailyNutritionState as SuccessState;
    final pts = s.data as List<dynamic>;
    // 2026-03-05: 500 kcal.
    final day5 = pts.firstWhere((p) => p.date == DateTime(2026, 3, 5));
    expect(day5.caloriesKcal, 500);
  });

  test('loadMonth: _monthEnd không vượt quá hôm nay khi tháng hiện tại', () async {
    // Tháng 3/2026 có 31 ngày nhưng hôm nay là 20 → chỉ fetch logs tới 20.
    DateTime? askedTo;
    historyApi.onListAll = (from, to) async {
      askedTo = to;
      return <MealLogEntry>[];
    };
    await store.loadMonth();
    // monthCursor = 2026-03-01 (hôm nay 20/3).
    expect(askedTo, DateTime(2026, 3, 20));
  });

  test('previousMonth/nextMonth: nextMonth no-op tại tháng hiện tại', () async {
    await store.loadMonth();
    expect(store.isCurrentMonth, isTrue);

    store.nextMonth(); // no-op
    expect(store.monthCursor, DateTime(2026, 3, 1));
    expect(store.isCurrentMonth, isTrue);

    store.previousMonth(); // 2026-03-01 -> 2026-02-01
    expect(store.monthCursor, DateTime(2026, 2, 1));
    expect(store.isCurrentMonth, isFalse);

    store.nextMonth(); // 2026-02-01 -> 2026-03-01 (đã cập nhật lại)
    expect(store.monthCursor, DateTime(2026, 3, 1));

    store.nextMonth(); // gọi lần nữa, đang ở tháng hiện tại → no-op
    expect(store.monthCursor, DateTime(2026, 3, 1));
  });

  test('race guard: response cũ bị bỏ đi khi có loadMonth() mới hơn', () async {
    // Lần 1: listAll chậm (Future chưa resolve).
    final slow = Completer<List<MealLogEntry>>();
    var call = 0;
    historyApi.onListAll = (from, to) {
      call++;
      if (call == 1) return slow.future;
      return Future.value(<MealLogEntry>[_log('b', 5, cal: 900)]);
    };
    healthApi.target = 1000;

    final first = store.loadMonth();
    // Lần 2 resolve nhanh — override.
    await store.loadMonth();
    slow.complete(<MealLogEntry>[_log('a', 5, cal: 100)]);
    await first; // lần 1 resolve SAU.

    // Value cuối phải là 900 (của response MỚI), KHÔNG bị 1 bh ghi đè.
    final pts = (store.dailyNutritionState as SuccessState).data;
    expect(pts.firstWhere((p) => p.date == DateTime(2026, 3, 5)).caloriesKcal, 900);
  });

  test('adherence: bao nhiêu Monday giao với tháng → đúng số điểm', () async {
    adherenceApi.percent = 80;
    store.previousMonth(); // 3/2026 -> 2/2026 (28 ngày).
    await store.loadMonth();
    final pts = (store.adherenceState as SuccessState).data;
    // Feb 2026 (CN đầu tháng): các Monday giao = 26/1,2/2,9/2,16/2,23/2 → 5.
    expect(pts.length, 5);
    expect(pts.first.weekStart.weekday, 1);
  });
}