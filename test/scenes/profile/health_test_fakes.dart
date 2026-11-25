import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

/// Fake dùng chung cho test HealthProfileScreen / AllergenSelectScreen.
const List<Allergen> kCatalog = <Allergen>[
  Allergen(id: 1, name: 'Gluten'),
  Allergen(id: 2, name: 'Trứng'),
  Allergen(id: 3, name: 'Cá'),
];

HealthProfile healthProfile({
  int? goal,
  DietType? diet,
  double? height = 170,
  double? weight = 65,
  List<Allergen> allergens = const <Allergen>[],
  bool empty = false,
}) =>
    HealthProfile(
      userId: 'me',
      targetDailyCalories: goal,
      dietType: diet,
      heightCm: height,
      weightKg: weight,
      updatedAt: empty ? null : DateTime.utc(2026, 11, 15),
      allergens: allergens,
    );

class FakeHealthApi implements HealthApi {
  HealthProfile profile = healthProfile();
  List<Allergen> catalog = kCatalog;
  Object? readError, writeError, allergenWriteError, catalogError;
  Completer<void>? readGate;
  final profileWrites = <Map<String, dynamic>>[];
  final allergenWrites = <List<int>>[];
  int profileReads = 0;
  int catalogReads = 0;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    profileReads++;
    await readGate?.future;
    if (readError case final Object error) throw error;
    return profile;
  }

  @override
  Future<HealthProfile> updateMyHealthProfile(
      Map<String, dynamic> payload) async {
    profileWrites.add(Map.of(payload));
    if (writeError case final Object error) throw error;
    profile = HealthProfile.fromJson(<String, dynamic>{
      ...profile.toJson(),
      ...payload,
    });
    return profile;
  }

  @override
  Future<List<Allergen>> getAllergenCatalog() async {
    catalogReads++;
    if (catalogError case final Object error) throw error;
    return catalog;
  }

  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) async {
    allergenWrites.add(List.of(allergenIds));
    if (allergenWriteError case final Object error) throw error;
    return catalog.where((a) => allergenIds.contains(a.id)).toList();
  }

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) =>
      throw UnimplementedError();
}

class MemoryReadCache implements ReadCacheDao {
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

class UnusedProfileApi implements ProfileApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Dựng ProfileStore + đăng ký vào GetX (màn hình gọi `Get.find`).
ProfileStore putProfileStore(HealthApi api, ReadCacheDao cache) {
  Get.testMode = true;
  final session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()));
  session.currentUser = const UserSummary(id: 'me', fullName: 'Tester');
  final store = ProfileStore(api, UnusedProfileApi(), cache, session);
  Get.put<ProfileStore>(store);
  return store;
}

Future<void> pumpHealthScreen(
  WidgetTester tester,
  Widget screen, {
  String language = 'vi',
}) async {
  tester.view.physicalSize = const Size(900, 1600);
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

Finder byKey(String key) => find.byKey(ValueKey<String>(key));

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(byKey(key));
  await tester.tap(byKey(key));
  await tester.pump();
}
