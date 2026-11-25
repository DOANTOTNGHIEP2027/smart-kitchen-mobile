import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/demo/demo_backend_adapter.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/dependent_api.dart';

import '../helpers/secure_storage_channel.dart';

/// #125 §16.2 bảng demo (Slice 0) — demo adapter khớp contract
/// `dependent-profile-tiering.yaml`, parse bằng CHÍNH `DependentApiImpl`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late DependentApi api;

  setUp(() {
    storageChannel.install();
    final client = DioClient.build(
      tokenStorage: TokenStorage(),
      dio: Dio(BaseOptions(baseUrl: 'https://demo.local')),
    )..dio.httpClientAdapter = DemoBackendAdapter();
    api = DependentApiImpl(client);
  });
  tearDown(storageChannel.uninstall);

  Matcher code(String c) =>
      isA<ApiException>().having((ApiException e) => e.code, 'code', c);

  test('fixture: dietType null (chưa thiết lập); health trống → isEmpty', () async {
    final list = await api.listDependents();
    expect(list, isNotEmpty);
    expect(list.first.dietType, isNull);
    final h = await api.getHealthProfile(list.first.id);
    expect(h.isEmpty, isTrue);
    expect(h.targetDailyCalories, isNull);
  });

  test('POST: DOB thiếu → null; GET detail đúng shape summary', () async {
    final created = await api.createDependent(displayName: 'Bé Na');
    expect(created.dateOfBirth, isNull);
    final d = await api.getDependent(created.id);
    expect(d.guardianActive, isTrue);
    expect(d.dietType, isNull);
    expect(d.allergens, isEmpty);
  });

  test('PUT health ghi đúng 4 field (null là null) + updatedAt; PUT {} reset', () async {
    final id = (await api.listDependents()).first.id;
    final h = await api.updateHealthProfile(id, <String, dynamic>{
      'targetDailyCalories': 1400,
      'dietType': 'KETO',
      'heightCm': null,
      'weightKg': 20.0,
    });
    expect(h.isEmpty, isFalse);
    expect(h.heightCm, isNull);
    expect((await api.getDependent(id)).dietType?.name, 'keto');
    final reset = await api.updateHealthProfile(id, <String, dynamic>{});
    expect(reset.targetDailyCalories, isNull);
    expect(reset.dietType, isNull);
  });

  test('DELETE → 200; sau đó GET → 404 ERR_DEP_001', () async {
    final id = (await api.listDependents()).first.id;
    await api.deleteDependent(id);
    await expectLater(api.getDependent(id), throwsA(code('ERR_DEP_001')));
    await expectLater(api.getDependent('nope'), throwsA(code('ERR_DEP_001')));
  });

  test('PATCH guardian: target lạ → 400 ERR_DEP_004; hợp lệ → guardianActive true', () async {
    final id = (await api.listDependents()).first.id;
    await expectLater(api.changeGuardian(id, 'stranger'), throwsA(code('ERR_DEP_004')));
    final d = await api.changeGuardian(id, 'demo-member-0002');
    expect(d.guardianUserId, 'demo-member-0002');
    expect(d.guardianActive, isTrue);
  });

  test('PUT allergens id lạ → 400 ERR_ALLERGEN_NOT_FOUND', () async {
    final id = (await api.listDependents()).first.id;
    await expectLater(api.updateAllergens(id, <int>[9999]), throwsA(code('ERR_ALLERGEN_NOT_FOUND')));
    final ok = await api.updateAllergens(id, <int>[1]);
    expect(ok.single.id, 1);
  });
}
