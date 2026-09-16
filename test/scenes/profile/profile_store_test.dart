import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late TokenStorage tokenStorage;

  setUp(() {
    storageChannel.install();
    tokenStorage = TokenStorage();
  });
  tearDown(storageChannel.uninstall);

  late AppDatabase db;
  late ReadCacheDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ReadCacheDao(db);
  });
  tearDown(() => db.close());

  ProfileStore buildStore(HealthApi healthApi, {ProfileApi? profileApi}) {
    // Dựng SessionStore thật (như session_store_test.dart) để userId/householdId
    // reflect qua cache key. TokenStorage + secure-storage fake đủ để bootstrap
    // không gọi network.
    final session = SessionStore(
      tokenStorage,
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter =
            FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null)))),
    );
    session.currentUser = const UserSummary(id: 'u1', fullName: 'Tester');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    return ProfileStore(
        healthApi, profileApi ?? _StubProfileApi(), dao, session);
  }


  group('loadHealthProfile — 3 nhánh cache-fallback', () {
    test('online success → SuccessState + isFromCache=false + ghi cache',
        () async {
      final api = _StubHealthApi(
        profile: _sampleHealthProfile(allergens: const <Allergen>[
          Allergen(id: 1, name: 'Fish'),
        ]),
      );
      final store = buildStore(api);

      await store.loadHealthProfile();

      expect(store.healthProfileState, isA<SuccessState<HealthProfile>>());
      expect(store.healthProfileIsFromCache, isFalse);

      final cached = await dao.get('health_profile:u1');
      expect(cached, isNotNull);
      expect(
        (cached!.payload['allergens'] as List<dynamic>).length,
        1,
        reason: 'cache phải được ghi khi online success',
      );
    });

    test('NetworkException + có cache → SuccessState + isFromCache=true',
        () async {
      await dao.put('health_profile:u1', _sampleHealthProfile().toJson());

      final api = _StubHealthApi(error: NetworkException());
      final store = buildStore(api);

      await store.loadHealthProfile();

      expect(store.healthProfileState, isA<SuccessState<HealthProfile>>());
      expect(store.healthProfileIsFromCache, isTrue,
          reason: 'phải hiện badge "data cũ" khi fallback cache');
    });

    test('NetworkException + chưa có cache → ErrorState (không phải SuccessState)',
        () async {
      final api = _StubHealthApi(error: NetworkException());
      final store = buildStore(api);

      await store.loadHealthProfile();

      expect(store.healthProfileState, isA<ErrorState<HealthProfile>>());
      expect(store.healthProfileIsFromCache, isFalse);
    });
  });

  group('saveAllergens — Fix HIGH-1 (regression test)', () {
    test(
        'patch healthProfileState tại chỗ sau khi lưu, không cần load lại',
        () async {
      final initial = _sampleHealthProfile(allergens: const <Allergen>[
        Allergen(id: 1, name: 'Fish'),
      ]);
      final api = _StubHealthApi(profile: initial);
      final store = buildStore(api);
      await store.loadHealthProfile();

      const updated = <Allergen>[
        Allergen(id: 2, name: 'Peanut'),
        Allergen(id: 3, name: 'Shellfish'),
      ];
      api.profile = api.profile!.copyWith(allergens: updated);

      final ok = await store.saveAllergens(const <int>[2, 3]);

      expect(ok, isTrue);
      final state = store.healthProfileState as SuccessState<HealthProfile>;
      expect(
        state.data.allergens,
        equals(updated),
        reason:
            'Cốt lõi của bug Fix HIGH-1: sau saveAllergens, allergens phải '
            'reflect kết quả mới mà không cần load lại. Hai state độc lập cho '
            'cùng 1 fact sẽ lệch nhau — đây là regression test cho bug đó.',
      );
      expect(store.allergensSaveStatus, FormStatus.success);
    });
  });

  group('saveHealthProfile', () {
    test('thành công → healthSaveStatus.success + state update + cache', () async {
      final api = _StubHealthApi(profile: _sampleHealthProfile());
      final store = buildStore(api);
      await store.loadHealthProfile();

      api.profile = HealthProfile(
        userId: 'u1',
        targetDailyCalories: 2000,
        dietType: DietType.keto,
        heightCm: null,
        weightKg: null,
        updatedAt: DateTime.parse('2026-09-15T10:00:00Z'),
        allergens: const <Allergen>[],
      );

      final ok = await store.saveHealthProfile(
        targetDailyCalories: 2000,
        dietTypeWire: 'KETO',
      );

      expect(ok, isTrue);
      expect(store.healthSaveStatus, FormStatus.success);
      final state = store.healthProfileState as SuccessState<HealthProfile>;
      expect(state.data.targetDailyCalories, 2000);
      expect(state.data.dietType, DietType.keto);
    });

    test('ApiException → healthSaveStatus.failure + mutationError set', () async {
      final api = _StubHealthApi(
        profile: _sampleHealthProfile(),
        mutationError: ValidationException(
          'ERR_VALIDATION_FAILED',
          'Validation failed',
          fieldErrors: const <String, String>{'dietType': 'invalid'},
        ),
      );
      final store = buildStore(api);
      await store.loadHealthProfile();

      final ok = await store.saveHealthProfile(dietTypeWire: 'INVALID');

      expect(ok, isFalse);
      expect(store.healthSaveStatus, FormStatus.failure);
      expect(store.mutationError, isNotNull);
      expect(store.mutationError!.code, 'ERR_VALIDATION_FAILED');
    });
  });
}

HealthProfile _sampleHealthProfile({List<Allergen>? allergens}) {
  final stubAllergens = allergens ?? const <Allergen>[];
  return HealthProfile(
    userId: 'u1',
    targetDailyCalories: null,
    dietType: null,
    heightCm: null,
    weightKg: null,
    updatedAt: DateTime.parse('2026-09-15T10:00:00Z'),
    allergens: stubAllergens,
  );
}

/// Stub [HealthApi] programmable để test cache-fallback mà không cần Dio.
class _StubHealthApi implements HealthApi {
  _StubHealthApi({this.profile, this.error, this.mutationError});

  HealthProfile? profile;
  Object? error;
  Object? mutationError;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    if (error != null) throw error!;
    return profile!;
  }

  @override
  Future<HealthProfile> updateMyHealthProfile(
      Map<String, dynamic> payload) async {
    if (mutationError != null) throw mutationError!;
    return profile!;
  }

  @override
  Future<List<Allergen>> getAllergenCatalog() async {
    throw UnimplementedError();
  }

  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) async {
    if (mutationError != null) throw mutationError!;
    return allergenIds
        .map((int id) => Allergen(id: id, name: 'a$id'))
        .toList(growable: false);
  }

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) async {
    throw UnimplementedError();
  }
}

class _StubProfileApi implements ProfileApi {
  @override
  Future<UserSummary> updateMe(
      {required String fullName, String? avatarUrl}) async {
    throw UnimplementedError();
  }
}

