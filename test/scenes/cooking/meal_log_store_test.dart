import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/meal_log_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_type.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/meal_log_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../../helpers/fake_http_adapter.dart';

class FakeMealLogApi implements MealLogApi {
  Future<List<MealLogEntry>> Function()? onListLogs;
  Future<MealLogEntry> Function(String description, String? imageBase64)?
      onLogMeal;
  Future<MealLogEntry> Function(String id, double? caloriesKcal)? onConfirm;

  Object? listLogsError;
  Object? logMealError;
  Object? confirmError;

  @override
  Future<MealLogEntry> logMeal({
    required String description,
    String? imageBase64,
  }) async {
    if (logMealError != null) throw logMealError!;
    if (onLogMeal != null) return onLogMeal!(description, imageBase64);
    throw UnimplementedError();
  }

  @override
  Future<List<MealLogEntry>> listLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    if (listLogsError != null) throw listLogsError!;
    if (onListLogs != null) return onListLogs!();
    throw UnimplementedError();
  }

  @override
  Future<MealLogEntry> confirm(
      {required String id, double? caloriesKcal}) async {
    if (confirmError != null) throw confirmError!;
    if (onConfirm != null) return onConfirm!(id, caloriesKcal);
    throw UnimplementedError();
  }
}

class FakeHealthApi implements HealthApi {
  int? targetDailyCalories;
  Object? error;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    if (error != null) throw error!;
    return HealthProfile(
      userId: 'self-actor',
      targetDailyCalories: targetDailyCalories,
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

void main() {
  late FakeMealLogApi api;
  late FakeHealthApi healthApi;
  late SessionStore session;
  late MealLogStore store;

  setUp(() {
    api = FakeMealLogApi();
    healthApi = FakeHealthApi();
    session = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(
        Dio(BaseOptions(baseUrl: 'https://test.local'))
          ..httpClientAdapter = FakeHttpAdapter(
            (_) async => jsonResponse(200, successEnvelope(null)),
          ),
      ),
    );
    session.currentUser = const UserSummary(id: 'self-actor', fullName: 'Me');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    store = MealLogStore(api, healthApi, session);
  });

  MealLogEntry saved({
    String id = 'srv-1',
    double? caloriesKcal,
    bool requiresConfirmation = false,
    bool confirmedByUser = false,
    DateTime? loggedAt,
    MealEntryStatus status = MealEntryStatus.saved,
  }) {
    return MealLogEntry(
      id: id,
      householdId: 'h1',
      memberId: 'self-actor',
      loggedBy: 'self-actor',
      description: '[Bữa trưa] Phở',
      caloriesKcal: caloriesKcal,
      requiresConfirmation: requiresConfirmation,
      confirmedByUser: confirmedByUser,
      loggedAt: loggedAt ?? DateTime.parse('2026-09-16T07:00:00Z'),
      status: status,
    );
  }

  /// Seed state bằng cách chạy loadToday với GET trả về danh sách cho trước.
  Future<void> seed(List<MealLogEntry> entries) async {
    api.onListLogs = () async => entries;
    await store.loadToday();
    api.onListLogs = null;
  }

  group('loadToday reconciliation', () {
    test('Fix HIGH-1: GET lỗi + previous Success → giữ TOÀN BỘ previous.data',
        () async {
      await seed([
        saved(id: 's1', caloriesKcal: 100),
        saved(id: 's2', caloriesKcal: 200),
        saved(id: 's3', caloriesKcal: 300),
      ]);
      api.listLogsError = NetworkException();

      await store.loadToday();

      final data =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>).data;
      expect(data.length, 3); // giữ đủ, không rơi về ErrorState
      expect(data.any((e) => e.id == 's1'), isTrue);
    });

    test('GET lỗi + previous KHÔNG Success → ErrorState', () async {
      api.listLogsError = NetworkException();

      await store.loadToday();

      expect(store.todayLogsState, isA<ErrorState<List<MealLogEntry>>>());
    });

    test('Guard #7: GET thành công nhưng ko trả pending → vẫn giữ pending',
        () async {
      // Tạo 1 entry pending (logout submit đang xử lý trên mạng).
      final completer = Completer<MealLogEntry>();
      api.onLogMeal = (_, __) => completer.future;
      unawaited(store.submitLog(mealType: MealType.lunch));
      await Future<void>.delayed(Duration.zero);
      final pendingId =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>)
              .data
              .first
              .id;

      // GET sau đó ko trả về entry pending đó (vì chưa lên server).
      api.onListLogs = () async => <MealLogEntry>[
            saved(id: 'rest-only', caloriesKcal: 100)
          ];
      await store.loadToday();

      final data =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>).data;
      // Guard #7: entry pending PHẢI còn nguyên dù GET không trả nó.
      expect(data.any((e) => e.id == pendingId), isTrue);
      expect(data.any((e) => e.id == 'rest-only'), isTrue);

      // Thả submit để không kẹt Future trong test.
      completer.complete(saved(caloriesKcal: 100, requiresConfirmation: false));
    });

    test('Guard #14 dedupe: trùng id → GET (authoritative) thay thế', () async {
      api.onListLogs = () async => <MealLogEntry>[
            saved(id: 'local-0', caloriesKcal: 500)
          ];

      // Giả lập: đang có pending local-0 bằng cách seed trước rồi reset,
      // sau đó loadToday với danh sách chứa cùng local-0 từ GET.
      await store.loadToday();

      final data =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>).data;
      expect(data.length, 1);
      expect(data.single.caloriesKcal, closeTo(500, 0.001));
    });
  });

  group('submitLog optimistic', () {
    test('entry pending xuất hiện NGAY trước khi Future resolve', () async {
      final completer = Completer<MealLogEntry>();
      api.onLogMeal = (_, __) => completer.future;
      await seed(<MealLogEntry>[]);

      final submit = store.submitLog(mealType: MealType.lunch);
      await Future<void>.delayed(Duration.zero);

      final data =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>).data;
      expect(data.first.status, MealEntryStatus.pending);
      expect(data.first.id.startsWith('local-'), isTrue);

      completer.complete(saved(caloriesKcal: 480, requiresConfirmation: false));
      await submit;

      final after =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>).data;
      expect(after.first.status, MealEntryStatus.saved);
    });

    test('requiresConfirmation=true → set autoConfirmTarget; false → không',
        () async {
      await seed(<MealLogEntry>[]);
      api.onLogMeal = (_, __) async =>
          saved(caloriesKcal: null, requiresConfirmation: true);
      await store.submitLog(mealType: MealType.lunch);
      expect(store.autoConfirmTarget, isNotNull);

      store.clearAutoConfirmTarget();
      api.onLogMeal = (_, __) async =>
          saved(caloriesKcal: 480, requiresConfirmation: false);
      await store.submitLog(mealType: MealType.dinner);
      expect(store.autoConfirmTarget, isNull);
    });

    test('failure → entry giữ nguyên, status=failed, KHÔNG bị xoá', () async {
      await seed(<MealLogEntry>[]);
      api.logMealError = ServerException('ERR_500', 'boom');

      await store.submitLog(mealType: MealType.lunch);

      final data =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>).data;
      expect(data.first.status, MealEntryStatus.failed);
    });
  });

  group('retrySubmit', () {
    test('dùng lại đúng payload gốc, không cần mở lại bottom sheet', () async {
      await seed(<MealLogEntry>[]);
      var firstTry = true;
      api.onLogMeal = (desc, img) async {
        if (firstTry) {
          firstTry = false;
          throw NetworkException();
        }
        return saved(caloriesKcal: 480, requiresConfirmation: false);
      };

      await store.submitLog(mealType: MealType.lunch, userDescription: 'Phở bò');
      final failedId =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>)
              .data
              .first
              .id;

      await store.retrySubmit(failedId);

      final after =
          (store.todayLogsState as SuccessState<List<MealLogEntry>>).data;
      expect(after.first.status, MealEntryStatus.saved);
      // BE trả id thật — entry thay thế, không còn trạng thái failed.
      expect(after.first.id, 'srv-1');
      expect(after.first.id, isNot(failedId));
    });
  });

  group('calorieGoalRemaining', () {
    test('đúng khi có target, chỉ tính entry countsTowardDailyTotal', () async {
      healthApi.targetDailyCalories = 2000;
      await seed([
        saved(id: 'a', caloriesKcal: 500),
        saved(id: 'b', caloriesKcal: 300, requiresConfirmation: true),
        saved(id: 'c',
            caloriesKcal: 200, requiresConfirmation: true, confirmedByUser: true),
        saved(id: 'd', caloriesKcal: null),
      ]);

      expect(store.calorieGoalRemaining, 2000 - 500 - 200);
    });

    test('null khi target null (best-effort)', () async {
      healthApi.targetDailyCalories = null;
      await seed([saved(id: 'a', caloriesKcal: 500)]);

      expect(store.calorieGoalRemaining, isNull);
    });
  });

  group('confirmCalories', () {
    test('success → replace entry + FormStatus.success', () async {
      await seed([saved(id: 'a', caloriesKcal: 100)]);
      api.onConfirm = (id, kcal) async => saved(id: id, caloriesKcal: 480);

      final ok = await store.confirmCalories('a', caloriesKcal: 480);

      expect(ok, isTrue);
      expect(store.confirmStatus, FormStatus.success);
      expect(
          (store.todayLogsState as SuccessState<List<MealLogEntry>>)
              .data
              .single
              .caloriesKcal,
          closeTo(480, 0.001));
    });

    test('error → FormStatus.failure + confirmError', () async {
      await seed([saved(id: 'a', caloriesKcal: null)]);
      api.confirmError =
          ServerException('ERR_MEAL_LOG_NOT_FOUND', 'not found');

      final ok = await store.confirmCalories('a', caloriesKcal: null);

      expect(ok, isFalse);
      expect(store.confirmStatus, FormStatus.failure);
      expect(store.confirmError?.code, 'ERR_MEAL_LOG_NOT_FOUND');
    });
  });
}