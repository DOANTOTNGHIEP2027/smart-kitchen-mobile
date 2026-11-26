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
import 'package:smart_kitchen_mobile/scenes/profile/api/dependent_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/dependent_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/family_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import 'family_test_fakes.dart' as ff;
import 'health_test_fakes.dart' as hf;

/// Fake dùng chung cho test hồ sơ phụ thuộc (#125 §16.14).

DependentSummary dep(
  String id, {
  String guardian = 'me',
  bool active = true,
  String name = 'Bé Bo',
  DateTime? dob,
  DietType? diet,
  List<Allergen> allergens = const <Allergen>[],
}) =>
    DependentSummary(
      id: id,
      guardianUserId: guardian,
      guardianActive: active,
      displayName: name,
      dateOfBirth: dob,
      dietType: diet,
      allergens: allergens,
    );

DependentHealthProfile depHealth(
  String id, {
  int? calories = 1400,
  String? dietRaw = 'VEGETARIAN',
  double? height = 110,
  double? weight = 19.5,
  List<Allergen> allergens = const <Allergen>[],
  bool empty = false,
}) =>
    DependentHealthProfile.fromJson(<String, dynamic>{
      'dependentId': id,
      'targetDailyCalories': empty ? null : calories,
      'dietType': empty ? null : dietRaw,
      'heightCm': empty ? null : height,
      'weightKg': empty ? null : weight,
      'updatedAt': empty ? null : '2026-11-20T10:00:00Z',
      'allergens': allergens.map((a) => a.toJson()).toList(),
    });

class FakeDependentApi implements DependentApi {
  List<DependentSummary> items = <DependentSummary>[];
  final Map<String, DependentHealthProfile> health =
      <String, DependentHealthProfile>{};
  List<Allergen> catalog = hf.kCatalog;

  Object? listError, getError, createError, deleteError, guardianError;
  Object? healthReadError, healthWriteError, allergensError;

  /// Gate theo id cho `getDependent` (test `_detailSeq`).
  final Map<String, Completer<void>> getGates = <String, Completer<void>>{};
  Completer<void>? createGate, guardianGate, healthWriteGate, deleteGate;

  /// Gate theo thứ tự gọi `listDependents` (L2 — về không theo thứ tự).
  final List<Completer<void>> listGates = <Completer<void>>[];

  /// Gate cho `getHealthProfile` (L3).
  Completer<void>? healthReadGate;

  final List<String> calls = <String>[];
  final List<Map<String, dynamic>> healthWrites = <Map<String, dynamic>>[];
  final List<List<int>> allergenWrites = <List<int>>[];
  final List<(String, DateTime?)> creates = <(String, DateTime?)>[];

  int count(String prefix) => calls.where((c) => c.startsWith(prefix)).length;

  DependentSummary? _find(String id) =>
      items.where((d) => d.id == id).firstOrNull;

  @override
  Future<List<DependentSummary>> listDependents() async {
    calls.add('list');
    final snapshot = List<DependentSummary>.of(items);
    final error = listError;
    if (listGates.isNotEmpty) await listGates.removeAt(0).future;
    if (error case final Object e) throw e;
    return snapshot;
  }

  @override
  Future<DependentSummary> getDependent(String id) async {
    calls.add('get:$id');
    await getGates[id]?.future;
    if (getError case final Object e) throw e;
    final d = _find(id);
    if (d == null) throw BusinessException('ERR_DEP_001', 'Dependent not found');
    return d;
  }

  @override
  Future<DependentSummary> createDependent({
    required String displayName,
    DateTime? dateOfBirth,
  }) async {
    calls.add('create');
    creates.add((displayName, dateOfBirth));
    await createGate?.future;
    if (createError case final Object e) throw e;
    final created = DependentSummary(
      id: 'new-${items.length + 1}',
      guardianUserId: 'me',
      guardianActive: true,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      allergens: const <Allergen>[],
    );
    items = <DependentSummary>[...items, created];
    return created;
  }

  @override
  Future<void> deleteDependent(String id) async {
    calls.add('delete:$id');
    await deleteGate?.future;
    if (deleteError case final Object e) throw e;
    items = items.where((d) => d.id != id).toList();
  }

  @override
  Future<DependentSummary> changeGuardian(
      String id, String guardianUserId) async {
    calls.add('guardian:$id:$guardianUserId');
    await guardianGate?.future;
    if (guardianError case final Object e) throw e;
    final d = _find(id)!;
    final updated = DependentSummary(
      id: d.id,
      guardianUserId: guardianUserId,
      guardianActive: true,
      displayName: d.displayName,
      dateOfBirth: d.dateOfBirth,
      dietType: d.dietType,
      allergens: d.allergens,
    );
    items = items.map((e) => e.id == id ? updated : e).toList();
    return updated;
  }

  @override
  Future<DependentHealthProfile> getHealthProfile(String id) async {
    calls.add('health:$id');
    final snapshot = health[id] ?? depHealth(id, empty: true);
    await healthReadGate?.future;
    if (healthReadError case final Object e) throw e;
    return snapshot;
  }

  @override
  Future<DependentHealthProfile> updateHealthProfile(
      String id, Map<String, dynamic> payload) async {
    calls.add('putHealth:$id');
    healthWrites.add(Map<String, dynamic>.of(payload));
    await healthWriteGate?.future;
    if (healthWriteError case final Object e) throw e;
    final current = health[id];
    final updated = DependentHealthProfile.fromJson(<String, dynamic>{
      ...payload,
      'dependentId': id,
      'updatedAt': '2026-11-25T10:00:00Z',
      'allergens': (current?.allergens ?? const <Allergen>[])
          .map((a) => a.toJson())
          .toList(),
    });
    health[id] = updated;
    return updated;
  }

  @override
  Future<List<Allergen>> updateAllergens(
      String id, List<int> allergenIds) async {
    calls.add('allergens:$id');
    allergenWrites.add(List<int>.of(allergenIds));
    if (allergensError case final Object e) throw e;
    return catalog.where((a) => allergenIds.contains(a.id)).toList();
  }
}

SessionStore makeSession({String role = 'OWNER', String me = 'me'}) {
  final s = SessionStore(
    TokenStorage(),
    AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
  );
  s.currentUser = UserSummary(id: me, fullName: 'Tôi');
  s.applyRefreshedClaims(fakeJwt(<String, dynamic>{
    'sub': me,
    'household_id': 'h1',
    'role': role,
  }));
  return s;
}

List<HouseholdMember> defaultMembers(String role) => <HouseholdMember>[
      if (role != 'OWNER') ff.member('o', 'OWNER'),
      ff.member('me', role),
      ff.member('a', 'MEMBER'),
      ff.member('v', 'REMOTE_VIEWER'),
    ];

/// Bộ đồ chơi đầy đủ cho test store/màn hình dependent.
class DepFixture {
  DepFixture._(this.api, this.familyApi, this.family, this.store, this.cache,
      this.healthApi, this.session);

  final FakeDependentApi api;
  final ff.FakeFamilyApi familyApi;
  final FamilyStore family;
  final DependentStore store;
  final hf.MemoryReadCache cache;
  final hf.FakeHealthApi healthApi;
  final SessionStore session;
}

/// [loadRoster] = nạp sẵn roster (role lấy từ `callerRole`); `false` = role
/// rơi về JWT.
Future<DepFixture> makeDepFixture({
  String role = 'OWNER',
  List<HouseholdMember>? members,
  bool loadRoster = true,
  bool register = false,
}) async {
  final api = FakeDependentApi();
  final familyApi = ff.FakeFamilyApi()
    ..current = ff.roster(
        callerRole: role, members: members ?? defaultMembers(role));
  final cache = hf.MemoryReadCache();
  final session = makeSession(role: role);
  final family = FamilyStore(familyApi, ff.FakeHealthApi(), cache, session);
  if (loadRoster) await family.loadRoster();
  final healthApi = hf.FakeHealthApi();
  final store = DependentStore(api, healthApi, family, cache, session);
  if (register) {
    Get.testMode = true;
    Get.put<FamilyStore>(family);
    Get.put<DependentStore>(store);
  }
  return DepFixture._(api, familyApi, family, store, cache, healthApi, session);
}

/// [v1.2 review-125] MEDIUM-2 — MỌI test pump `FamilyScreen` gọi helper này
/// sau khi đã `Get.put<FamilyStore>` (nếu không, `Get.find` trong initState
/// throw).
DependentStore registerFakeDependentStore({
  FakeDependentApi? api,
  ReadCacheDao? cache,
}) {
  final session = Get.isRegistered<SessionStore>()
      ? Get.find<SessionStore>()
      : makeSession();
  final store = DependentStore(
    api ?? FakeDependentApi(),
    hf.FakeHealthApi(),
    Get.find<FamilyStore>(),
    cache ?? hf.MemoryReadCache(),
    session,
  );
  Get.put<DependentStore>(store);
  return store;
}

/// Pump [screen] trong GetMaterialApp (màn dependent dùng Get.toNamed).
Future<void> pumpDependentScreen(
  WidgetTester tester,
  Widget screen, {
  List<GetPage<dynamic>> pages = const <GetPage<dynamic>>[],
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(GetMaterialApp(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: screen,
    getPages: pages,
  ));
  await tester.pump();
  await tester.pump();
}

Finder byKey(String key) => find.byKey(ValueKey<String>(key));
