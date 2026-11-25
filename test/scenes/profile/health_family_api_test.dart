import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/family_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// HealthApi/FamilyApi phải convert DioException → ApiException BÊN TRONG API
/// (Guard 5, AGENTS.md) — fix review #29 M1. Envelope hỏng → ServerException,
/// không lọt FormatException/DioException ra Store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();

  setUpAll(storageChannel.install);
  tearDownAll(storageChannel.uninstall);

  late FakeHttpAdapter adapter;

  DioClient buildClient(
      Future<ResponseBody> Function(RequestOptions options) handler) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    return DioClient.build(tokenStorage: TokenStorage(), dio: dio);
  }

  Future<ResponseBody> offline(RequestOptions options) async =>
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );

  group('FamilyApi', () {
    test('removeMember 400 ERR_HH_007 → BusinessException (không DioException)',
        () async {
      final api = FamilyApiImpl(buildClient((_) async => jsonResponse(
            400,
            errorEnvelope('ERR_HH_007', 'Cannot remove owner'),
          )));

      await expectLater(
        api.removeMember('u2'),
        throwsA(isA<BusinessException>()
            .having((ApiException e) => e.code, 'code', 'ERR_HH_007')),
      );
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/api/v1/households/members/u2');
    });

    test('removeMember 204 → hoàn tất không lỗi', () async {
      final api = FamilyApiImpl(
          buildClient((_) async => ResponseBody.fromString('', 204)));

      await api.removeMember('u2');
      expect(adapter.requests, hasLength(1));
    });

    test('changeRole 403 ERR_TIER_SEAT_LIMIT → BusinessException', () async {
      final api = FamilyApiImpl(buildClient((_) async => jsonResponse(
            403,
            errorEnvelope('ERR_TIER_SEAT_LIMIT', 'Seat limit'),
          )));

      await expectLater(
        api.changeRole('u2', 'MEMBER'),
        throwsA(isA<BusinessException>()
            .having((ApiException e) => e.code, 'code', 'ERR_TIER_SEAT_LIMIT')),
      );
    });

    test('getMyHousehold mất mạng → NetworkException', () async {
      final api = FamilyApiImpl(buildClient(offline));

      await expectLater(api.getMyHousehold(), throwsA(isA<NetworkException>()));
    });

    test('createInvite envelope hỏng → ServerException (không FormatException)',
        () async {
      final api = FamilyApiImpl(
          buildClient((_) async => jsonResponse(200, successEnvelope(null))));

      await expectLater(api.createInvite(), throwsA(isA<ServerException>()));
    });
  });

  group('HealthApi', () {
    test('getMyHealthProfile mất mạng → NetworkException', () async {
      final api = HealthApiImpl(buildClient(offline));

      await expectLater(
          api.getMyHealthProfile(), throwsA(isA<NetworkException>()));
    });

    test('updateMyHealthProfile 400 → ValidationException giữ fieldErrors',
        () async {
      final api = HealthApiImpl(buildClient((_) async => jsonResponse(
            400,
            errorEnvelope('ERR_VALIDATION_FAILED', 'Validation failed',
                fieldErrors: <String, String>{'heightCm': 'must be <= 300'}),
          )));

      await expectLater(
        api.updateMyHealthProfile(<String, dynamic>{'heightCm': 999}),
        throwsA(isA<ValidationException>().having(
            (ValidationException e) => e.fieldErrors?['heightCm'],
            'fieldErrors.heightCm',
            'must be <= 300')),
      );
    });

    test('getMemberHealthSummary 403 → BusinessException', () async {
      final api = HealthApiImpl(buildClient((_) async => jsonResponse(
            403,
            errorEnvelope('ERR_HEALTH_FORBIDDEN', 'Forbidden'),
          )));

      await expectLater(
        api.getMemberHealthSummary('u2'),
        throwsA(isA<BusinessException>().having(
            (ApiException e) => e.code, 'code', 'ERR_HEALTH_FORBIDDEN')),
      );
    });

    test('updateMyAllergens mất mạng → NetworkException', () async {
      final api = HealthApiImpl(buildClient(offline));

      await expectLater(
          api.updateMyAllergens(<int>[1]), throwsA(isA<NetworkException>()));
    });

    test('getAllergenCatalog envelope hỏng → ServerException', () async {
      final api = HealthApiImpl(
          buildClient((_) async => jsonResponse(200, successEnvelope(null))));

      await expectLater(
          api.getAllergenCatalog(), throwsA(isA<ServerException>()));
    });

    test('getMyHealthProfile envelope hỏng → ServerException', () async {
      final api = HealthApiImpl(
          buildClient((_) async => jsonResponse(200, successEnvelope(null))));

      await expectLater(
          api.getMyHealthProfile(), throwsA(isA<ServerException>()));
    });
  });
}
