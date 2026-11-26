import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/dependent_api.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// #125 §16.14 — DependentApi: đúng method/path/body camelCase; DioException
/// được convert sang ApiException BÊN TRONG API (Guard 9).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  setUpAll(storageChannel.install);
  tearDownAll(storageChannel.uninstall);

  late FakeHttpAdapter adapter;

  DependentApi build(Future<ResponseBody> Function(RequestOptions o) handler) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    return DependentApiImpl(
        DioClient.build(tokenStorage: TokenStorage(), dio: dio));
  }

  Map<String, dynamic> summary(String id) => <String, dynamic>{
        'id': id,
        'guardianUserId': 'u1',
        'guardianActive': true,
        'displayName': 'Bé Bo',
        'dateOfBirth': null,
        'dietType': null,
        'allergens': <dynamic>[],
      };

  Map<String, dynamic> health(String id) => <String, dynamic>{
        'dependentId': id,
        'targetDailyCalories': null,
        'dietType': null,
        'heightCm': null,
        'weightKg': null,
        'updatedAt': null,
        'allergens': <dynamic>[],
      };

  RequestOptions last() => adapter.requests.last;
  Map<String, dynamic> body() => last().data is String
      ? jsonDecode(last().data as String) as Map<String, dynamic>
      : Map<String, dynamic>.from(last().data as Map);

  test('listDependents: GET /api/v1/dependents', () async {
    final api = build((_) async =>
        jsonResponse(200, successEnvelope(<dynamic>[summary('d1'), summary('d2')])));
    final items = await api.listDependents();
    expect(items.map((d) => d.id), <String>['d1', 'd2']);
    expect(last().method, 'GET');
    expect(last().path, '/api/v1/dependents');
  });

  test('getDependent 404 ERR_DEP_001 → BusinessException (không DioException)', () async {
    final api = build((_) async =>
        jsonResponse(404, errorEnvelope('ERR_DEP_001', 'Dependent not found')));
    await expectLater(
      api.getDependent('d9'),
      throwsA(isA<BusinessException>()
          .having((ApiException e) => e.code, 'code', 'ERR_DEP_001')),
    );
    expect(last().path, '/api/v1/dependents/d9');
  });

  test('createDependent: POST camelCase, OMIT dateOfBirth khi null', () async {
    final api = build((_) async => jsonResponse(
        201,
        successEnvelope(<String, dynamic>{
          'id': 'd3',
          'householdId': 'h1',
          'guardianUserId': 'me',
          'displayName': 'Bé Na',
          'dateOfBirth': null,
          'createdAt': '2026-11-25T10:00:00Z',
        })));
    final d = await api.createDependent(displayName: 'Bé Na');
    expect(last().method, 'POST');
    expect(last().path, '/api/v1/dependents');
    expect(body(), <String, dynamic>{'displayName': 'Bé Na'});
    expect(d.guardianActive, isTrue);

    await api.createDependent(displayName: 'Bé Na', dateOfBirth: DateTime(2020, 5, 1));
    expect(body(), <String, dynamic>{'displayName': 'Bé Na', 'dateOfBirth': '2020-05-01'});
  });

  test('createDependent 403 ERR_DEP_003 → BusinessException', () async {
    final api = build((_) async =>
        jsonResponse(403, errorEnvelope('ERR_DEP_003', 'Remote viewer')));
    await expectLater(
      api.createDependent(displayName: 'x'),
      throwsA(isA<BusinessException>()
          .having((ApiException e) => e.code, 'code', 'ERR_DEP_003')),
    );
  });

  test('deleteDependent: DELETE, data null OK; 403 ERR_DEP_006 → BusinessException', () async {
    var fail = false;
    final api = build((_) async => fail
        ? jsonResponse(403, errorEnvelope('ERR_DEP_006', 'Owner only'))
        : jsonResponse(200, successEnvelope(null)));
    await api.deleteDependent('d1');
    expect(last().method, 'DELETE');
    expect(last().path, '/api/v1/dependents/d1');
    fail = true;
    await expectLater(
      api.deleteDependent('d1'),
      throwsA(isA<BusinessException>()
          .having((ApiException e) => e.code, 'code', 'ERR_DEP_006')),
    );
  });

  test('changeGuardian: PATCH .../guardian body {guardianUserId}', () async {
    final api = build((_) async => jsonResponse(200, successEnvelope(summary('d1'))));
    await api.changeGuardian('d1', 'u2');
    expect(last().method, 'PATCH');
    expect(last().path, '/api/v1/dependents/d1/guardian');
    expect(body(), <String, dynamic>{'guardianUserId': 'u2'});
  });

  test('getHealthProfile: GET .../health-profile; 403 ERR_DEP_002 → BusinessException', () async {
    var fail = false;
    final api = build((_) async => fail
        ? jsonResponse(403, errorEnvelope('ERR_DEP_002', 'Forbidden'))
        : jsonResponse(200, successEnvelope(health('d1'))));
    final h = await api.getHealthProfile('d1');
    expect(h.isEmpty, isTrue);
    expect(last().path, '/api/v1/dependents/d1/health-profile');
    fail = true;
    await expectLater(
      api.getHealthProfile('d1'),
      throwsA(isA<BusinessException>()
          .having((ApiException e) => e.code, 'code', 'ERR_DEP_002')),
    );
  });

  test('updateHealthProfile: PUT đủ 4 key kể cả null', () async {
    final api = build((_) async => jsonResponse(200, successEnvelope(health('d1'))));
    await api.updateHealthProfile('d1', <String, dynamic>{
      'targetDailyCalories': null,
      'dietType': 'KETO',
      'heightCm': null,
      'weightKg': 20.5,
    });
    expect(last().method, 'PUT');
    expect(last().path, '/api/v1/dependents/d1/health-profile');
    final b = body();
    expect(b.keys, unorderedEquals(<String>['targetDailyCalories', 'dietType', 'heightCm', 'weightKg']));
    expect(b['targetDailyCalories'], isNull);
  });

  test('updateHealthProfile 400 fieldErrors → ValidationException', () async {
    final api = build((_) async => jsonResponse(
        400,
        errorEnvelope('ERR_VALIDATION_FAILED', 'Invalid',
            fieldErrors: <String, String>{'heightCm': 'max 300'})));
    await expectLater(
      api.updateHealthProfile('d1', <String, dynamic>{}),
      throwsA(isA<ValidationException>()
          .having((ApiException e) => e.fieldErrors?['heightCm'], 'field', 'max 300')),
    );
  });

  test('updateAllergens: PUT .../allergens {allergenIds}; 400 ERR_ALLERGEN_NOT_FOUND', () async {
    var fail = false;
    final api = build((_) async => fail
        ? jsonResponse(400, errorEnvelope('ERR_ALLERGEN_NOT_FOUND', 'Unknown'))
        : jsonResponse(200, successEnvelope(<dynamic>[
            <String, dynamic>{'id': 1, 'name': 'Gluten'},
          ])));
    final list = await api.updateAllergens('d1', <int>[1]);
    expect(list.single.id, 1);
    expect(last().path, '/api/v1/dependents/d1/allergens');
    expect(body(), <String, dynamic>{'allergenIds': <dynamic>[1]});
    fail = true;
    await expectLater(
      api.updateAllergens('d1', <int>[99]),
      throwsA(isA<BusinessException>()
          .having((ApiException e) => e.code, 'code', 'ERR_ALLERGEN_NOT_FOUND')),
    );
  });

  test('mất mạng → NetworkException', () async {
    final api = build((RequestOptions o) async => throw DioException(
        requestOptions: o, type: DioExceptionType.connectionError));
    await expectLater(api.listDependents(), throwsA(isA<NetworkException>()));
  });
}
