import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/avatar_image_processor.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/edit_profile_phase.dart';
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

  late SessionStore session;

  ProfileStore buildStore(HealthApi healthApi,
      {ProfileApi? profileApi, AvatarImageProcessor? processor}) {
    // Dựng SessionStore thật (như session_store_test.dart) để userId/householdId
    // reflect qua cache key. TokenStorage + secure-storage fake đủ để bootstrap
    // không gọi network.
    session = SessionStore(
      tokenStorage,
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter =
            FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null)))),
    );
    session.currentUser = const UserSummary(id: 'u1', fullName: 'Tester');
    session.applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    return ProfileStore(healthApi, profileApi ?? _StubProfileApi(), dao,
        session, processor ?? _FakeProcessor());
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

  group('saveProfile — luồng 2 bước (D11, Guard 1/2/15)', () {
    final picked = Uint8List.fromList(<int>[1, 2, 3]);
    const uploadedUrl = 'http://localhost:8080/api/files/abc.jpg';

    test('upload OK + PUT OK → persist qua TokenStorage + currentUser mới',
        () async {
      final api = _StubProfileApi(uploadUrl: uploadedUrl);
      final store = buildStore(_StubHealthApi(), profileApi: api);

      final ok = await store.saveProfile(
          newFullName: '  Nguyễn Văn A ', rawAvatar: picked);

      expect(ok, isTrue);
      expect(store.editProfilePhase, isA<EditSuccess>());
      expect(store.pendingAvatarUrl, isNull);
      expect(api.uploadCalls, 1);
      expect(api.lastUploadBytes, <int>[9, 9],
          reason: 'phải upload bytes ĐÃ nén, không phải bytes gốc');
      expect(api.updateCalls.single, <String?>['Nguyễn Văn A', uploadedUrl]);
      expect(session.currentUser?.fullName, 'Nguyễn Văn A');
      expect(session.currentUser?.avatarUrl, uploadedUrl);
      final persisted = await tokenStorage.readUser();
      expect(persisted?['fullName'], 'Nguyễn Văn A',
          reason: 'Guard 2: phải ghi TokenStorage để cold start không mất');
      expect(persisted?['avatarUrl'], uploadedUrl);
    });

    test('upload lỗi → EditUploadError, updateMe KHÔNG được gọi', () async {
      final api = _StubProfileApi(
          uploadError: BusinessException('ERR_FILE_INVALID', 'bad'));
      final store = buildStore(_StubHealthApi(), profileApi: api);

      final ok = await store.saveProfile(newFullName: 'A', rawAvatar: picked);

      expect(ok, isFalse);
      expect((store.editProfilePhase as EditUploadError).code,
          'ERR_FILE_INVALID');
      expect(api.updateCalls, isEmpty);
      expect(store.pendingAvatarUrl, isNull);
    });

    test('processor ném tooLarge → không gọi uploadAvatar', () async {
      final api = _StubProfileApi(uploadUrl: uploadedUrl);
      final store = buildStore(
        _StubHealthApi(),
        profileApi: api,
        processor:
            _FakeProcessor(error: const AvatarImageException.tooLarge()),
      );

      final ok = await store.saveProfile(rawAvatar: picked);

      expect(ok, isFalse);
      expect((store.editProfilePhase as EditUploadError).code,
          'ERR_FILE_TOO_LARGE');
      expect(api.uploadCalls, 0);
      expect(api.updateCalls, isEmpty);
    });

    test('PUT lỗi sau khi upload → retry chỉ PUT lại, không upload lần 2',
        () async {
      final api = _StubProfileApi(
          uploadUrl: uploadedUrl, updateError: NetworkException());
      final store = buildStore(_StubHealthApi(), profileApi: api);

      expect(await store.saveProfile(rawAvatar: picked), isFalse);
      expect(store.editProfilePhase, isA<EditSaveError>());
      expect(store.pendingAvatarUrl, uploadedUrl);

      api.updateError = null;
      final ok = await store.saveProfile(rawAvatar: picked);

      expect(ok, isTrue);
      expect(api.uploadCalls, 1, reason: 'Guard 1: retry KHÔNG upload lại');
      expect(api.updateCalls, hasLength(2));
      expect(api.updateCalls.last, <String?>[null, uploadedUrl]);
      expect(store.pendingAvatarUrl, isNull);
    });

    test('PUT 400 ERR_VALIDATION_FAILED → giữ fieldErrors trong EditSaveError',
        () async {
      final api = _StubProfileApi(
        updateError: ValidationException(
          'ERR_VALIDATION_FAILED',
          'Validation failed',
          fieldErrors: const <String, String>{'fullName': 'too long'},
        ),
      );
      final store = buildStore(_StubHealthApi(), profileApi: api);

      expect(await store.saveProfile(newFullName: 'B'), isFalse);

      final phase = store.editProfilePhase as EditSaveError;
      expect(phase.error, isA<ValidationException>());
      expect(phase.error.fieldErrors, containsPair('fullName', 'too long'));
      expect(session.currentUser?.fullName, 'Tester');
    });

    test('tên toàn khoảng trắng / > 100 ký tự / không đổi gì → không gọi API',
        () async {
      final api = _StubProfileApi(uploadUrl: uploadedUrl);
      final store = buildStore(_StubHealthApi(), profileApi: api);

      expect(await store.saveProfile(newFullName: '   '), isFalse);
      expect(
          await store.saveProfile(newFullName: 'x' * 101, rawAvatar: picked),
          isFalse);
      expect(await store.saveProfile(), isFalse);
      expect(api.uploadCalls, 0);
      expect(api.updateCalls, isEmpty);
      expect(store.editProfilePhase, isA<EditIdle>());
    });

    test('chỉ đổi tên → không upload, không gửi avatarUrl', () async {
      final api = _StubProfileApi();
      final store = buildStore(_StubHealthApi(), profileApi: api);

      expect(await store.saveProfile(newFullName: 'Chỉ tên'), isTrue);
      expect(api.uploadCalls, 0);
      expect(api.updateCalls.single, <String?>['Chỉ tên', null]);
    });

    test('clearEditProfileError → EditIdle nhưng GIỮ pendingAvatarUrl',
        () async {
      final api = _StubProfileApi(
          uploadUrl: uploadedUrl, updateError: NetworkException());
      final store = buildStore(_StubHealthApi(), profileApi: api);
      await store.saveProfile(rawAvatar: picked);

      store.clearEditProfileError();

      expect(store.editProfilePhase, isA<EditIdle>());
      expect(store.pendingAvatarUrl, uploadedUrl);

      store.onAvatarRepicked();
      expect(store.pendingAvatarUrl, isNull);
    });
  });

  group('clear*Error reset cả mutationError dùng chung', () {
    test('clearHealthSaveError / clearAllergensSaveError / clearEditProfileError',
        () async {
      final api = _StubHealthApi(
        profile: _sampleHealthProfile(),
        mutationError: NetworkException(),
      );
      final store = buildStore(api);
      await store.loadHealthProfile();

      await store.saveHealthProfile(dietTypeWire: 'KETO');
      expect(store.mutationError, isNotNull);
      store.clearHealthSaveError();
      expect(store.healthSaveStatus, FormStatus.idle);
      expect(store.mutationError, isNull);

      await store.saveAllergens(const <int>[1]);
      expect(store.mutationError, isNotNull);
      store.clearAllergensSaveError();
      expect(store.allergensSaveStatus, FormStatus.idle);
      expect(store.mutationError, isNull);

      await store.saveHealthProfile(dietTypeWire: 'KETO');
      expect(store.mutationError, isNotNull);
      store.clearEditProfileError();
      expect(store.mutationError, isNull);
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
  _StubProfileApi({this.uploadUrl, this.uploadError, this.updateError});

  String? uploadUrl;
  Object? uploadError;
  Object? updateError;
  int uploadCalls = 0;
  List<int>? lastUploadBytes;

  /// Mỗi phần tử = [fullName, avatarUrl] của một lần gọi updateMe.
  final List<List<String?>> updateCalls = <List<String?>>[];

  @override
  Future<FileUploadResult> uploadAvatar(Uint8List jpegBytes) async {
    uploadCalls++;
    lastUploadBytes = jpegBytes.toList();
    if (uploadError != null) throw uploadError!;
    return FileUploadResult(key: 'abc.jpg', url: uploadUrl!);
  }

  @override
  Future<UserSummary> updateMe({String? fullName, String? avatarUrl}) async {
    updateCalls.add(<String?>[fullName, avatarUrl]);
    if (updateError != null) throw updateError!;
    return UserSummary(
      id: 'u1',
      fullName: fullName ?? 'Tester',
      avatarUrl: avatarUrl,
    );
  }
}

class _FakeProcessor implements AvatarImageProcessor {
  _FakeProcessor({this.error});

  final Object? error;

  @override
  Future<Uint8List> process(Uint8List picked) async {
    if (error != null) throw error!;
    return Uint8List.fromList(<int>[9, 9]);
  }
}
