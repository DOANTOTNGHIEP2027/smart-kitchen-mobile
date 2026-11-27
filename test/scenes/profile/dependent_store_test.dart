import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart';
import 'family_test_fakes.dart' as ff;

/// #125 §16.14 — DependentStore: ma trận quyền, Guard 2, cache, patch, lỗi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(storage.uninstall);

  List<DependentSummary> listOf(DepFixture f) =>
      (f.store.listState as SuccessState<List<DependentSummary>>).data;
  DependentSummary detailOf(DepFixture f) =>
      (f.store.detailState as SuccessState<DependentSummary>).data;
  DependentHealthProfile healthOf(DepFixture f) =>
      (f.store.healthState as SuccessState<DependentHealthProfile>).data;

  group('canEditHealthOf — ma trận quyền 5 ca (Guard 1, 14)', () {
    test('OWNER → true kể cả guardianActive:false / không phải guardian', () async {
      final f = await makeDepFixture(role: 'OWNER');
      expect(f.store.canEditHealthOf(dep('d', guardian: 'a', active: false)), isTrue);
      expect(f.store.canEditHealthOf(dep('d', guardian: 'a')), isTrue);
    });

    test('MEMBER là guardian, active → true', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      expect(f.store.canEditHealthOf(dep('d', guardian: 'me')), isTrue);
    });

    test('MEMBER là guardian, !guardianActive → false', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      expect(f.store.canEditHealthOf(dep('d', guardian: 'me', active: false)), isFalse);
    });

    test('MEMBER không phải guardian → false', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      expect(f.store.canEditHealthOf(dep('d', guardian: 'a')), isFalse);
    });

    test('REMOTE_VIEWER vẫn là guardianUserId, active → false (OD-60/OD-84)', () async {
      final f = await makeDepFixture(role: 'REMOTE_VIEWER');
      expect(f.store.canEditHealthOf(dep('d', guardian: 'me')), isFalse);
      expect(f.store.canManageDependents, isFalse);
      expect(f.store.canAdd, isFalse);
    });

    test('canAdminister chỉ OWNER', () async {
      expect((await makeDepFixture(role: 'OWNER')).store.canAdminister, isTrue);
      expect((await makeDepFixture(role: 'MEMBER')).store.canAdminister, isFalse);
    });
  });

  group('loadDependentDetail (Guard 2)', () {
    test('không quyền → KHÔNG gọi getHealthProfile', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      f.api.items = <DependentSummary>[dep('d1', guardian: 'a'), dep('d2', guardian: 'me', active: false)];
      await f.store.loadDependentDetail('d1');
      await f.store.loadDependentDetail('d2');
      expect(f.api.count('health:'), 0);
      expect(f.store.healthState, isA<LoadingState<DependentHealthProfile>>());
      // Gọi thẳng cũng bị chặn ngay tại store.
      await f.store.loadHealthProfile('d2');
      expect(f.api.count('health:'), 0);
    });

    test('có quyền → gọi getHealthProfile một lần', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      f.api.items = <DependentSummary>[dep('d1', guardian: 'me')];
      f.api.health['d1'] = depHealth('d1');
      await f.store.loadDependentDetail('d1');
      expect(f.api.count('health:d1'), 1);
      expect(healthOf(f).targetDailyCalories, 1400);
    });

    test('roster chưa tải → nạp song song (role tươi)', () async {
      final f = await makeDepFixture(role: 'OWNER', loadRoster: false);
      f.api.items = <DependentSummary>[dep('d1')];
      await f.store.loadDependentDetail('d1');
      expect(f.familyApi.rosterCalls, 1);
      expect(f.store.isRosterLoaded, isTrue);
    });

    test('_detailSeq: mở A rồi B, response A về sau KHÔNG ghi đè', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('A', name: 'An'), dep('B', name: 'Bình')];
      final gate = Completer<void>();
      f.api.getGates['A'] = gate;
      final a = f.store.loadDependentDetail('A');
      await f.store.loadDependentDetail('B');
      gate.complete();
      await a;
      expect(detailOf(f).id, 'B');
    });

    test('404 → ErrorState ERR_DEP_001', () async {
      final f = await makeDepFixture();
      await f.store.loadDependentDetail('nope');
      final s = f.store.detailState;
      expect(s, isA<ErrorState<DependentSummary>>());
      expect((s as ErrorState<DependentSummary>).error.code, 'ERR_DEP_001');
    });

    test('L3: detail Success patch item cùng id trong list', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1', guardian: 'a', active: false)];
      await f.store.loadDependents();
      f.api.items = <DependentSummary>[dep('d1', guardian: 'a')];
      await f.store.loadDependentDetail('d1');
      expect(listOf(f).single.guardianActive, isTrue);
    });
  });

  group('loadDependents — cache-fallback 3 nhánh', () {
    test('online → Success + ghi cache camelCase', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      await f.store.loadDependents();
      expect(listOf(f).single.id, 'd1');
      expect(f.store.listFromCache, isFalse);
      final items = f.cache.entries['dependents:h1']!.payload['items'] as List<dynamic>;
      expect((items.single as Map<String, dynamic>)['guardianUserId'], 'me');
    });

    test('mất mạng + có cache → cache + listFromCache, ẩn "+ Thêm"', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      await f.store.loadDependents();
      f.api.listError = NetworkException();
      await f.store.loadDependents();
      expect(listOf(f).single.id, 'd1');
      expect(f.store.listFromCache, isTrue);
      expect(f.store.canAdd, isFalse);
    });

    test('mất mạng + không cache → ErrorState; lỗi BE không đọc cache', () async {
      final f = await makeDepFixture();
      f.api.listError = NetworkException();
      await f.store.loadDependents();
      expect(f.store.listState, isA<ErrorState<List<DependentSummary>>>());

      f.api.listError = null;
      f.api.items = <DependentSummary>[dep('d1')];
      await f.store.loadDependents();
      f.api.listError = BusinessException('ERR_DEP_005', 'no household');
      await f.store.loadDependents();
      expect(f.store.listState, isA<ErrorState<List<DependentSummary>>>());
    });
  });

  group('createDependent', () {
    test('trim tên, chèn item mới, success sau khi nạp lại', () async {
      final f = await makeDepFixture();
      await f.store.loadDependents();
      final ok = await f.store.createDependent(displayName: '  Bé Na  ');
      expect(ok, isTrue);
      expect(f.api.creates.single.$1, 'Bé Na');
      expect(listOf(f).single.displayName, 'Bé Na');
      expect(f.store.createStatus, FormStatus.success);
    });

    test('L2: tạo OK + nạp lại lỗi mạng → list (cache) vẫn chứa item mới', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      await f.store.loadDependents();
      final gate = Completer<void>();
      f.api.createGate = gate;
      final future = f.store.createDependent(displayName: 'Bé Na');
      f.api.listError = NetworkException(); // reload sau create sẽ lỗi mạng
      gate.complete();
      expect(await future, isTrue);
      expect(f.store.listFromCache, isTrue);
      expect(listOf(f).map((d) => d.displayName), contains('Bé Na'));
    });

    test('double-submit: lần 2 trong lúc đang gửi bị bỏ qua', () async {
      final f = await makeDepFixture();
      await f.store.loadDependents();
      final gate = Completer<void>();
      f.api.createGate = gate;
      final first = f.store.createDependent(displayName: 'A');
      expect(await f.store.createDependent(displayName: 'B'), isFalse);
      gate.complete();
      await first;
      expect(f.api.count('create'), 1);
    });

    test('403 ERR_DEP_003 → failure + nạp lại roster', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      f.api.createError = BusinessException('ERR_DEP_003', 'rv');
      final before = f.familyApi.rosterCalls;
      expect(await f.store.createDependent(displayName: 'A'), isFalse);
      expect(f.store.createStatus, FormStatus.failure);
      expect(f.store.createError?.code, 'ERR_DEP_003');
      expect(f.familyApi.rosterCalls, before + 1);
    });

    test('REMOTE_VIEWER bị chặn tại store, API không được gọi', () async {
      final f = await makeDepFixture(role: 'REMOTE_VIEWER');
      expect(await f.store.createDependent(displayName: 'A'), isFalse);
      expect(f.api.count('create'), 0);
    });
  });

  group('delete / changeGuardian (OWNER only)', () {
    test('MEMBER bị chặn, API không được gọi', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      expect(await f.store.deleteDependent('d1'), isFalse);
      expect(await f.store.changeGuardian('d1', 'a'), isFalse);
      expect(f.api.calls, isEmpty);
    });

    test('xoá OK → bỏ khỏi list + cache', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1'), dep('d2')];
      await f.store.loadDependents();
      expect(await f.store.deleteDependent('d1'), isTrue);
      expect(listOf(f).map((d) => d.id), <String>['d2']);
      await Future<void>.delayed(Duration.zero);
      final cached = f.cache.entries['dependents:h1']!.payload['items'] as List<dynamic>;
      expect(cached, hasLength(1));
    });

    test('xoá 404 ERR_DEP_001 → nạp lại list', () async {
      final f = await makeDepFixture();
      f.api.deleteError = BusinessException('ERR_DEP_001', 'gone');
      expect(await f.store.deleteDependent('d1'), isFalse);
      expect(f.store.deleteError?.code, 'ERR_DEP_001');
      expect(f.api.count('list'), 1);
    });

    test('đổi guardian → patch detail + list bằng object BE trả (guardianActive:true)', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1', guardian: 'x', active: false)];
      await f.store.loadDependents();
      await f.store.loadDependentDetail('d1');
      expect(await f.store.changeGuardian('d1', 'a'), isTrue);
      expect(detailOf(f).guardianUserId, 'a');
      expect(detailOf(f).guardianActive, isTrue);
      expect(listOf(f).single.guardianActive, isTrue);
    });

    test('đổi guardian 400 ERR_DEP_004 → failure + nạp lại roster', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      f.api.guardianError = BusinessException('ERR_DEP_004', 'invalid');
      final before = f.familyApi.rosterCalls;
      expect(await f.store.changeGuardian('d1', 'v'), isFalse);
      expect(f.store.guardianError?.code, 'ERR_DEP_004');
      expect(f.familyApi.rosterCalls, before + 1);
    });

    test('guardianCandidates: chỉ OWNER/MEMBER, loại guardian đang active', () async {
      final f = await makeDepFixture();
      final active = f.store.guardianCandidates(dep('d1', guardian: 'a'));
      expect(active.map((m) => m.userId), <String>['me']);
      // guardian đã inactive (rời rồi join lại) được chọn lại.
      final inactive = f.store.guardianCandidates(dep('d1', guardian: 'a', active: false));
      expect(inactive.map((m) => m.userId), <String>['me', 'a']);
    });
  });

  group('saveHealthProfile', () {
    Future<DepFixture> loaded({String? dietRaw = 'VEGETARIAN'}) async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1', diet: DietType.vegetarian)];
      await f.store.loadDependents();
      f.api.health['d1'] = depHealth('d1', dietRaw: dietRaw);
      await f.store.loadDependentDetail('d1');
      return f;
    }

    test('gửi đủ 6 key (null tường minh, #201) + patch detail/list bằng dietType của RESPONSE', () async {
      final f = await loaded();
      final ok = await f.store.saveHealthProfile('d1',
          targetDailyCalories: null, dietTypeWire: 'KETO', heightCm: 112, weightKg: null);
      expect(ok, isTrue);
      final payload = f.api.healthWrites.single;
      expect(payload.keys, unorderedEquals(<String>['targetDailyCalories', 'dietType', 'heightCm', 'weightKg', 'gender', 'activityLevel']));
      expect(payload['weightKg'], isNull);
      expect(payload['gender'], isNull);
      expect(payload['activityLevel'], isNull);
      expect(healthOf(f).dietType, DietType.keto);
      expect(detailOf(f).dietType, DietType.keto);
      expect(listOf(f).single.dietType, DietType.keto);
    });

    test('health chưa Success → bị chặn, API không gọi', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      f.api.healthReadError = NetworkException();
      await f.store.loadDependentDetail('d1');
      expect(await f.store.saveHealthProfile('d1',
          targetDailyCalories: 1, dietTypeWire: null, heightCm: null, weightKg: null), isFalse);
      expect(await f.store.saveAllergens('d1', <int>[]), isFalse);
      expect(f.api.count('putHealth'), 0);
      expect(f.api.count('allergens'), 0);
    });

    test('HIGH-1: dietType lạ → canSaveHealthFor false, PUT health KHÔNG gọi; allergens vẫn chạy', () async {
      final f = await loaded(dietRaw: 'PALEO');
      expect(f.store.canSaveAllergensFor('d1'), isTrue);
      expect(f.store.canSaveHealthFor('d1'), isFalse);
      expect(await f.store.saveHealthProfile('d1',
          targetDailyCalories: 1400, dietTypeWire: null, heightCm: 110, weightKg: 19.5), isFalse);
      expect(f.api.count('putHealth'), 0);
      expect(await f.store.saveAllergens('d1', <int>[2, 1]), isTrue);
      expect(f.api.allergenWrites.single, <int>[1, 2]);
    });

    test('403 ERR_DEP_002 → nạp lại detail (guardianActive mới) + roster', () async {
      final f = await loaded();
      f.api.healthWriteError = BusinessException('ERR_DEP_002', 'forbidden');
      final gets = f.api.count('get:d1');
      final rosters = f.familyApi.rosterCalls;
      expect(await f.store.saveHealthProfile('d1',
          targetDailyCalories: null, dietTypeWire: null, heightCm: null, weightKg: null), isFalse);
      expect(f.api.count('get:d1'), gets + 1);
      expect(f.familyApi.rosterCalls, rosters + 1);
    });

    test('mất mạng → failure, KHÔNG reload', () async {
      final f = await loaded();
      f.api.healthWriteError = NetworkException();
      final calls = f.api.calls.length;
      expect(await f.store.saveHealthProfile('d1',
          targetDailyCalories: null, dietTypeWire: null, heightCm: null, weightKg: null), isFalse);
      expect(f.store.healthSaveError, isA<NetworkException>());
      expect(f.api.calls.length, calls + 1); // chỉ có lệnh PUT
    });
  });

  group('saveAllergens', () {
    test('patch 3 nơi: health + detail + list (Guard 4)', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      await f.store.loadDependents();
      f.api.health['d1'] = depHealth('d1');
      await f.store.loadDependentDetail('d1');
      expect(await f.store.saveAllergens('d1', <int>[3, 1]), isTrue);
      expect(f.api.allergenWrites.single, <int>[1, 3]);
      expect(healthOf(f).allergens.map((a) => a.id), <int>[1, 3]);
      expect(detailOf(f).allergens.map((a) => a.id), <int>[1, 3]);
      expect(listOf(f).single.allergens.map((a) => a.id), <int>[1, 3]);
    });

    test('400 ERR_ALLERGEN_NOT_FOUND → nạp lại catalog', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      f.api.health['d1'] = depHealth('d1', allergens: const <Allergen>[Allergen(id: 1, name: 'Gluten')]);
      await f.store.loadDependentDetail('d1');
      f.api.allergensError = BusinessException('ERR_ALLERGEN_NOT_FOUND', 'x');
      final before = f.healthApi.catalogReads;
      expect(await f.store.saveAllergens('d1', <int>[99]), isFalse);
      expect(f.healthApi.catalogReads, before + 1);
      // health giữ nguyên dữ liệu server.
      expect(healthOf(f).allergens.single.id, 1);
    });
  });

  test('guardianOf tra an toàn — roster thiếu không throw (Guard 18)', () async {
    final f = await makeDepFixture(members: <HouseholdMember>[ff.member('me', 'OWNER')]);
    expect(f.store.guardianOf(dep('d1', guardian: 'gone')), isNull);
    expect(f.store.guardianOf(dep('d1', guardian: 'me'))?.userId, 'me');
  });

  group('Review #125 v1 — L1/L2/L3/L7', () {
    test('L2: loadDependents về không theo thứ tự → kết quả cũ KHÔNG ghi đè list/cache', () async {
      final f = await makeDepFixture();
      final g1 = Completer<void>();
      final g2 = Completer<void>();
      f.api.listGates.addAll(<Completer<void>>[g1, g2]);
      f.api.items = <DependentSummary>[dep('old')];
      final a = f.store.loadDependents();
      f.api.items = <DependentSummary>[dep('old'), dep('new')];
      final b = f.store.loadDependents(keepCurrent: true);
      g2.complete();
      await b;
      g1.complete();
      await a;
      expect(listOf(f).map((d) => d.id), <String>['old', 'new']);
      await Future<void>.delayed(Duration.zero);
      final cached = f.cache.entries['dependents:h1']!.payload['items'] as List<dynamic>;
      expect(cached, hasLength(2));
    });

    test('L1: loadDependentDetail(keepCurrent) giữ detail + health Success trong lúc chờ', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      f.api.health['d1'] = depHealth('d1');
      await f.store.loadDependentDetail('d1');
      final gate = Completer<void>();
      f.api.getGates['d1'] = gate;
      final refresh = f.store.loadDependentDetail('d1', keepCurrent: true);
      expect(f.store.detailState, isA<SuccessState<DependentSummary>>());
      expect(f.store.healthState, isA<SuccessState<DependentHealthProfile>>());
      gate.complete();
      await refresh;
      expect(f.api.count('health:d1'), 2);
      expect(f.store.healthState, isA<SuccessState<DependentHealthProfile>>());
    });

    test('L3: ensureHealthLoaded không GET trùng khi health đang bay', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      final gate = Completer<void>();
      f.api.healthReadGate = gate;
      final load = f.store.loadDependentDetail('d1');
      await Future<void>.delayed(Duration.zero);
      expect(f.store.isHealthInFlight('d1'), isTrue);
      final again = f.store.ensureHealthLoaded('d1');
      gate.complete();
      await Future.wait(<Future<void>>[load, again]);
      expect(f.api.count('health:d1'), 1);
      await f.store.ensureHealthLoaded('d1'); // đã Success → không gọi nữa
      expect(f.api.count('health:d1'), 1);
    });

    test('L3: GET đang bay về SAU PUT thành công KHÔNG ghi đè dữ liệu vừa lưu', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      f.api.health['d1'] = depHealth('d1', height: 110);
      await f.store.loadDependentDetail('d1');
      final gate = Completer<void>();
      f.api.healthReadGate = gate;
      final stale = f.store.loadHealthProfile('d1', keepCurrent: true); // snapshot 110
      f.api.healthReadGate = null;
      expect(await f.store.saveHealthProfile('d1',
          targetDailyCalories: 1400, dietTypeWire: 'VEGETARIAN', heightCm: 120, weightKg: 19.5), isTrue);
      gate.complete();
      await stale;
      expect(healthOf(f).heightCm, 120);
    });

    test('L7: 403 ERR_DEP_002 + BE báo guardianActive:false → quyền tính lại = false', () async {
      final f = await makeDepFixture(role: 'MEMBER');
      f.api.items = <DependentSummary>[dep('d1', guardian: 'me')];
      f.api.health['d1'] = depHealth('d1');
      await f.store.loadDependentDetail('d1');
      expect(f.store.canEditHealthOf(detailOf(f)), isTrue);
      f.api.items = <DependentSummary>[dep('d1', guardian: 'me', active: false)];
      f.api.healthWriteError = BusinessException('ERR_DEP_002', 'forbidden');
      expect(await f.store.saveHealthProfile('d1',
          targetDailyCalories: null, dietTypeWire: null, heightCm: null, weightKg: null), isFalse);
      expect(detailOf(f).guardianActive, isFalse);
      expect(f.store.canEditHealthOf(detailOf(f)), isFalse);
      expect(f.store.canSaveHealthFor('d1'), isFalse);
    });

    test('L7: 403 ERR_DEP_006 (xoá / đổi guardian) → nạp lại roster', () async {
      final f = await makeDepFixture();
      f.api.items = <DependentSummary>[dep('d1')];
      f.api.deleteError = BusinessException('ERR_DEP_006', 'owner only');
      f.api.guardianError = BusinessException('ERR_DEP_006', 'owner only');
      final before = f.familyApi.rosterCalls;
      expect(await f.store.deleteDependent('d1'), isFalse);
      expect(f.familyApi.rosterCalls, before + 1);
      expect(await f.store.changeGuardian('d1', 'a'), isFalse);
      expect(f.familyApi.rosterCalls, before + 2);
      expect(f.store.deleteError?.code, 'ERR_DEP_006');
    });
  });
}
