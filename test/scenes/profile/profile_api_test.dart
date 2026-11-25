import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// ProfileApi (profile-family-screens.md §7): path `/api/v1/...`, body JSON
/// camelCase, multipart part `file`, và DioException → ApiException bên trong
/// API (Guard 5).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();

  setUpAll(storageChannel.install);
  tearDownAll(storageChannel.uninstall);

  late FakeHttpAdapter adapter;

  ProfileApi buildApi(
      Future<ResponseBody> Function(RequestOptions options) handler) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    return ProfileApiImpl(
        DioClient.build(tokenStorage: TokenStorage(), dio: dio));
  }

  group('updateMe — PUT /api/v1/users/me', () {
    test('gửi JSON camelCase và parse UserSummary', () async {
      final api = buildApi((_) async => jsonResponse(
            200,
            successEnvelope(<String, dynamic>{
              'id': 'u1',
              'email': 'a@b.c',
              'fullName': 'Nguyễn Văn A',
              'avatarUrl': 'http://x/api/files/k.jpg',
            }),
          ));

      final user = await api.updateMe(
          fullName: 'Nguyễn Văn A', avatarUrl: 'http://x/api/files/k.jpg');

      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/api/v1/users/me');
      expect(request.data, <String, dynamic>{
        'fullName': 'Nguyễn Văn A',
        'avatarUrl': 'http://x/api/files/k.jpg',
      });
      expect(user.fullName, 'Nguyễn Văn A');
      expect(user.avatarUrl, 'http://x/api/files/k.jpg');
    });

    test('chỉ gửi key có giá trị — không có key avatarUrl khi null', () async {
      final api = buildApi((_) async => jsonResponse(
            200,
            successEnvelope(<String, dynamic>{'id': 'u1', 'fullName': 'B'}),
          ));

      await api.updateMe(fullName: 'B');

      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body.keys, <String>['fullName']);
    });

    test('400 ERR_VALIDATION_FAILED → ValidationException giữ fieldErrors',
        () async {
      final api = buildApi((_) async => jsonResponse(
            400,
            errorEnvelope('ERR_VALIDATION_FAILED', 'Validation failed',
                fieldErrors: <String, String>{'fullName': 'too long'}),
          ));

      await expectLater(
        api.updateMe(fullName: 'x'),
        throwsA(isA<ValidationException>().having(
            (ValidationException e) => e.fieldErrors?['fullName'],
            'fieldErrors.fullName',
            'too long')),
      );
    });
  });

  group('uploadAvatar — POST /api/v1/files', () {
    test('multipart part "file" và chấp nhận 201', () async {
      final api = buildApi((_) async => jsonResponse(
            201,
            successEnvelope(<String, dynamic>{
              'key': 'k.jpg',
              'url': 'http://localhost:8080/api/files/k.jpg',
              'contentType': 'image/jpeg',
              'sizeBytes': 3,
            }),
          ));

      final result =
          await api.uploadAvatar(Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF]));

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/v1/files');
      final form = request.data as FormData;
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'avatar.jpg');
      expect(result.url, 'http://localhost:8080/api/files/k.jpg');
      expect(result.key, 'k.jpg');
    });

    test('400 ERR_FILE_TOO_LARGE → ném ApiException (không phải DioException)',
        () async {
      final api = buildApi((_) async => jsonResponse(
            400,
            errorEnvelope('ERR_FILE_TOO_LARGE', 'File exceeds 2MB'),
          ));

      await expectLater(
        api.uploadAvatar(Uint8List.fromList(<int>[1])),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.code, 'code', 'ERR_FILE_TOO_LARGE')),
      );
    });

    test('mất mạng → NetworkException', () async {
      final api = buildApi((RequestOptions options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ));

      await expectLater(
        api.uploadAvatar(Uint8List.fromList(<int>[1])),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
