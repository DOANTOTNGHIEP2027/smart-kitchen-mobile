import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/family_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/health_profile_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/member_detail_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/family_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

void main() {
  late _HealthApi api;
  late _MemoryCache cache;
  late ProfileStore profileStore;
  late FamilyStore familyStore;

  setUp(() {
    Get.testMode = true;
    api = _HealthApi();
    cache = _MemoryCache();
    final session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()));
    session.currentUser = const UserSummary(id: 'me', fullName: 'Tester');
    profileStore = ProfileStore(api, _UnusedProfileApi(), cache, session);
    familyStore = FamilyStore(_UnusedFamilyApi(), api, cache, session);
    Get.put<ProfileStore>(profileStore);
    Get.put<FamilyStore>(familyStore);
  });

  tearDown(Get.reset);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    String language = 'vi',
  }) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ));
    await tester.pump();
  }

  Future<void> save(WidgetTester tester,
      {String label = 'Lưu hồ sơ sức khoẻ'}) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  Finder input(String name) => find.byKey(ValueKey<String>('health-$name'));

  group('Health profile full replacement', () {
    for (final raw in <String>[
      'abc',
      '0.5',
      '1e3',
      '-1',
      '10001',
      '0x10',
      'NaN'
    ]) {
      testWidgets('invalid goal $raw never reaches API', (tester) async {
        await pumpScreen(tester, const HealthProfileScreen());
        // Field order is weight/height/calories; also exercises the baseline UI.
        await tester.enterText(find.byType(TextField).at(2), raw);
        await save(tester);
        expect(api.profileWrites, isEmpty);
        expect(find.text('Nhập số nguyên từ 0 đến 10000 hoặc để trống'),
            findsOneWidget);
      });
    }

    for (final (raw, expected) in <(String, int?)>[
      ('', null),
      ('   ', null),
      ('0', 0),
      ('1', 1),
      (' 2000 ', 2000),
      ('10000', 10000),
    ]) {
      testWidgets(
          'goal "$raw" sends $expected and preserves other draft fields',
          (tester) async {
        api.profile = _profile(diet: DietType.glutenFree, goal: 1800);
        api.writeError = NetworkException();
        await pumpScreen(tester, const HealthProfileScreen());
        await tester.enterText(input('calories'), raw);
        await save(tester);
        expect(api.profileWrites.single, <String, dynamic>{
          'targetDailyCalories': expected,
          'dietType': 'GLUTEN_FREE',
          'heightCm': 170.0,
          'weightKg': 65.0,
        });
        expect(api.allergenWrites, isEmpty);
      });
    }

    testWidgets(
        'null diet and NONE are distinct; selecting NONE does not alter allergens',
        (tester) async {
      await pumpScreen(tester, const HealthProfileScreen());
      expect(find.text('Chưa chọn chế độ ăn'), findsOneWidget);
      expect(find.text('Chưa có mục dị ứng được lưu'), findsOneWidget);
      await tester.tap(input('diet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Không chọn chế độ ăn đặc biệt').last);
      await tester.pumpAndSettle();
      await save(tester);
      expect(api.profileWrites.single['dietType'], 'NONE');
      expect(api.allergenWrites, isEmpty);
    });

    testWidgets(
        'failed save keeps draft, disables pending writes and permits explicit retry',
        (tester) async {
      api.profile = _profile(diet: DietType.vegan);
      api.writeGate = Completer<void>();
      api.writeError = NetworkException();
      await pumpScreen(tester, const HealthProfileScreen());
      await tester.enterText(input('calories'), '2500');
      await save(tester);
      expect(tester.widget<TextFormField>(input('calories')).enabled, isFalse);
      expect(api.profileWrites, hasLength(1));
      api.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('2500'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);
      expect(tester.widget<TextFormField>(input('calories')).enabled, isTrue);
      expect(api.profileWrites, hasLength(1),
          reason: 'No automatic mutation retry');
      await save(tester);
      expect(api.profileWrites, hasLength(2));
      expect(api.profileWrites.last['targetDailyCalories'], 2500);
    });

    testWidgets(
        'successful zero goal updates store/cache only after acknowledgment',
        (tester) async {
      await pumpScreen(tester, const HealthProfileScreen());
      await tester.enterText(input('calories'), '0');
      await save(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(api.profileWrites.single['targetDailyCalories'], 0);
      expect(cache.entries['health_profile:me']!.payload['targetDailyCalories'],
          0);
      expect(api.allergenWrites, isEmpty);
    });

    testWidgets(
        'clear profile fields resets only draft until Save; allergens stay intact',
        (tester) async {
      api.profile = _profile(
          diet: DietType.glutenFree,
          allergens: const [Allergen(id: 1, name: 'Gluten')]);
      api.writeError = NetworkException();
      await pumpScreen(tester, const HealthProfileScreen());
      await tester.ensureVisible(find.text('Xóa các trường hồ sơ'));
      await tester.tap(find.text('Xóa các trường hồ sơ'));
      await tester.pump();
      expect(api.profileWrites, isEmpty);
      expect(api.allergenWrites, isEmpty);
      expect(find.text('Gluten'), findsOneWidget);
      await save(tester);
      expect(api.profileWrites.single, <String, dynamic>{
        'targetDailyCalories': null,
        'dietType': null,
        'heightCm': null,
        'weightKg': null,
      });
      expect(api.allergenWrites, isEmpty);
    });

    testWidgets(
        'mobile viewport validates fields even when scrolled out of view',
        (tester) async {
      await pumpScreen(tester, const HealthProfileScreen());
      tester.view.physicalSize = const Size(390, 844);
      await tester.pump();
      await tester.enterText(input('height'), 'invalid');
      await tester.enterText(input('calories'), '0');
      await save(tester);
      expect(api.profileWrites, isEmpty);
      await tester.ensureVisible(input('height'));
      expect(find.text('Nhập chiều cao từ 1 đến 300 cm hoặc để trống'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('diet can be reset independently without erasing other fields',
        (tester) async {
      api.profile = _profile(diet: DietType.glutenFree, goal: 2000);
      api.writeError = NetworkException();
      await pumpScreen(tester, const HealthProfileScreen());
      await tester.tap(input('diet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chưa chọn chế độ ăn').last);
      await tester.pumpAndSettle();
      await save(tester);
      expect(api.profileWrites.single, <String, dynamic>{
        'targetDailyCalories': 2000,
        'dietType': null,
        'heightCm': 170.0,
        'weightKg': 65.0,
      });
      expect(api.allergenWrites, isEmpty);
    });

    testWidgets('invalid optional height is not silently replaced by null',
        (tester) async {
      await pumpScreen(tester, const HealthProfileScreen());
      await tester.enterText(input('height'), 'invalid');
      await save(tester);
      expect(api.profileWrites, isEmpty);
      expect(find.text('Nhập chiều cao từ 1 đến 300 cm hoặc để trống'),
          findsOneWidget);
    });

    testWidgets('load error retries; cached fallback remains visibly stale',
        (tester) async {
      api.readError = NetworkException();
      await pumpScreen(tester, const HealthProfileScreen());
      expect(find.byType(AppErrorView), findsOneWidget);
      api.readError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(input('calories'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      api.readError = NetworkException();
      await pumpScreen(tester, const HealthProfileScreen());
      await tester.pumpAndSettle();
      expect(profileStore.healthProfileIsFromCache, isTrue);
      expect(
          find.text(
              'Dữ liệu có thể chưa cập nhật — đang hiển thị bản lưu gần nhất.'),
          findsOneWidget);
    });

    testWidgets('English labels and zero compatibility help are localized',
        (tester) async {
      await pumpScreen(tester, const HealthProfileScreen(), language: 'en');
      expect(find.text('Diet not selected'), findsOneWidget);
      expect(find.text('No allergen entries saved'), findsOneWidget);
      expect(find.text('Leave blank or enter 0 if no calorie goal is set.'),
          findsOneWidget);
    });

    test('empty allergens save never writes or resets health profile',
        () async {
      api.profile = _profile(diet: DietType.vegan, goal: 1800);
      await profileStore.loadHealthProfile();
      expect(await profileStore.saveAllergens([]), isTrue);
      expect(api.allergenWrites.single, isEmpty);
      expect(api.profileWrites, isEmpty);
      expect(cache.entries['health_profile:me']!.payload['targetDailyCalories'],
          1800);
      expect(cache.entries['health_profile:me']!.payload['dietType'], 'VEGAN');
    });
  });

  group('Read-only member summary', () {
    for (final (diet, label) in <(DietType?, String)>[
      (null, 'Chưa chọn chế độ ăn'),
      (DietType.none, 'Không chọn chế độ ăn đặc biệt'),
    ]) {
      testWidgets('$diet uses $label and neutral empty allergens',
          (tester) async {
        api.summary = MemberHealthSummary(
            userId: 'member', dietType: diet, allergens: const []);
        await pumpScreen(tester, const MemberDetailScreen());
        expect(find.text(label), findsOneWidget);
        expect(find.text('Chưa có mục dị ứng được lưu'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Mục tiêu calo/ngày'), findsNothing);
        expect(api.profileWrites, isEmpty);
      });
    }

    testWidgets('summary loading, forbidden, retry, and chips preserve privacy',
        (tester) async {
      api.summaryGate = Completer<void>();
      api.summaryError = BusinessException('ERR_HEALTH_FORBIDDEN', 'Forbidden');
      await pumpScreen(tester, const MemberDetailScreen());
      expect(find.byType(AppLoadingView), findsOneWidget);
      api.summaryGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.byType(Chip), findsNothing);
      expect(find.text('Chưa có mục dị ứng được lưu'), findsNothing);
      api.summaryError = null;
      api.summary = const MemberHealthSummary(
          userId: 'member', allergens: [Allergen(id: 1, name: 'Gluten')]);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Chip, 'Gluten'), findsOneWidget);
      expect(api.summaryReads, 2);
      expect(api.profileWrites, isEmpty);
    });

    testWidgets('summary null diet and empty allergens localize in English',
        (tester) async {
      await pumpScreen(tester, const MemberDetailScreen(), language: 'en');
      expect(find.text('Diet not selected'), findsOneWidget);
      expect(find.text('No allergen entries saved'), findsOneWidget);
    });
  });
}

HealthProfile _profile(
        {DietType? diet, int? goal, List<Allergen> allergens = const []}) =>
    HealthProfile(
      userId: 'me',
      targetDailyCalories: goal,
      dietType: diet,
      heightCm: 170,
      weightKg: 65,
      updatedAt: DateTime.utc(2026, 11, 15),
      allergens: allergens,
    );

class _HealthApi implements HealthApi {
  HealthProfile profile = _profile();
  MemberHealthSummary summary =
      const MemberHealthSummary(userId: 'member', allergens: []);
  Object? readError, writeError, summaryError;
  Completer<void>? writeGate, summaryGate;
  final profileWrites = <Map<String, dynamic>>[];
  final allergenWrites = <List<int>>[];
  int summaryReads = 0;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    if (readError case final Object error) throw error;
    return profile;
  }

  @override
  Future<HealthProfile> updateMyHealthProfile(
      Map<String, dynamic> payload) async {
    profileWrites.add(Map.of(payload));
    await writeGate?.future;
    if (writeError case final Object error) throw error;
    profile = HealthProfile.fromJson({...profile.toJson(), ...payload});
    return profile;
  }

  @override
  Future<List<Allergen>> getAllergenCatalog() async => const [];

  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) async {
    allergenWrites.add(List.of(allergenIds));
    return const [];
  }

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) async {
    summaryReads++;
    await summaryGate?.future;
    if (summaryError case final Object error) throw error;
    return summary;
  }
}

class _MemoryCache implements ReadCacheDao {
  final entries = <String, CachedEntry>{};
  @override
  Future<CachedEntry?> get(String key) async => entries[key];
  @override
  Future<void> put(String key, Map<String, dynamic> payload) async {
    entries[key] =
        CachedEntry(payload: Map.of(payload), fetchedAt: DateTime.now());
  }

  @override
  Future<void> remove(String key) async => entries.remove(key);
}

class _UnusedProfileApi implements ProfileApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedFamilyApi implements FamilyApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
