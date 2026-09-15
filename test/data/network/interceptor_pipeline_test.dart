import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/utils/dio_exception_x.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// Pipeline interceptor là phần mọi feature sau này phụ thuộc vào việc làm
/// đúng — fe-app-shell.md §15 xếp nó ưu tiên cao nhất.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String protectedPath = '/api/v1/protected';
  const String refreshPath = '/api/v1/auth/refresh';
  const String loginPath = '/api/v1/auth/email/login';

  final storageChannel = FakeSecureStorageChannel();
  late TokenStorage tokenStorage;

  setUp(() async {
    storageChannel.install();
    tokenStorage = TokenStorage();
    await tokenStorage.saveTokens('access-old', 'refresh-1');
  });

  tearDown(() {
    storageChannel.uninstall();
    Get.reset();
  });

  DioClient buildClient(FakeHttpAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    final client = DioClient.build(tokenStorage: tokenStorage, dio: dio);
    client.dio.httpClientAdapter = adapter;
    return client;
  }

  /// Adapter trả 401 cho [protectedPath] khi header còn mang token cũ, 200 khi
  /// đã mang token mới; `/auth/refresh` luôn thành công.
  FakeHttpAdapter refreshableAdapter({
    required bool protectedEverSucceeds,
    Duration refreshDelay = Duration.zero,
  }) {
    return FakeHttpAdapter((RequestOptions options) async {
      if (options.path == refreshPath) {
        await Future<void>.delayed(refreshDelay);
        return jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            'accessToken': fakeJwt(<String, dynamic>{
              'sub': 'u1',
              'household_id': 'h1',
              'role': 'OWNER',
              'provider': 'EMAIL',
            }),
            'refreshToken': 'refresh-2',
            'expiresIn': 900,
          }),
        );
      }
      final auth = options.headers['Authorization'] as String?;
      final hasNewToken = auth != null && auth != 'Bearer access-old';
      if (protectedEverSucceeds && hasNewToken) {
        return jsonResponse(200, successEnvelope(<String, dynamic>{'ok': true}));
      }
      return jsonResponse(
        401,
        errorEnvelope('ERR_AUTH_003', 'Access token expired'),
      );
    });
  }

  group('AuthHeaderInterceptor', () {
    test('gắn Bearer token vào request không-public', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(200, successEnvelope(null)),
      );
      final client = buildClient(adapter);

      await client.dio.get<dynamic>(protectedPath);

      expect(adapter.requests.single.headers['Authorization'],
          'Bearer access-old');
    });

    test('KHÔNG gắn Bearer token vào endpoint public', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(200, successEnvelope(null)),
      );
      final client = buildClient(adapter);

      await client.dio.post<dynamic>(loginPath, data: <String, dynamic>{});

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('KHÔNG gắn Bearer token vào GET invite theo prefix path-templated',
        () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(200, successEnvelope(null)),
      );
      final client = buildClient(adapter);

      await client.dio.get<dynamic>('/api/v1/households/invites/ABC12345');

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('Thứ tự interceptor — regression (review Finding 1, D9)', () {
    test(
        '401 trên request có Authorization → đúng 1 lần refresh + retry trong '
        'suốt, caller KHÔNG thấy AuthExpiredException', () async {
      final adapter = refreshableAdapter(protectedEverSucceeds: true);
      final client = buildClient(adapter);

      final response = await client.dio.get<dynamic>(protectedPath);

      expect(response.statusCode, 200);
      expect(adapter.countPath(refreshPath), 1);
      expect(tokenStorage.accessToken, isNot('access-old'));
      // Refresh token cũ BẮT BUỘC bị ghi đè — token cũ đã revoke.
      expect(await tokenStorage.readRefreshToken(), 'refresh-2');
    });
  });

  group('Bounded retry (review Finding 4)', () {
    test(
        'vẫn 401 sau một lần refresh thành công → refresh đúng 1 lần, caller '
        'nhận AuthExpiredException', () async {
      final adapter = refreshableAdapter(protectedEverSucceeds: false);
      final client = buildClient(adapter);

      ApiException? caught;
      try {
        await client.dio.get<dynamic>(protectedPath);
      } on DioException catch (e) {
        caught = e.apiException;
      }

      expect(caught, isA<AuthExpiredException>());
      expect(caught!.code, 'ERR_AUTH_003');
      expect(adapter.countPath(refreshPath), 1, reason: 'không được refresh lần 2');
    });
  });

  group('Single-flight refresh (D5)', () {
    test('3 request cùng nhận 401 → chỉ 1 lệnh gọi /auth/refresh', () async {
      final adapter = refreshableAdapter(
        protectedEverSucceeds: true,
        refreshDelay: const Duration(milliseconds: 50),
      );
      final client = buildClient(adapter);

      final responses = await Future.wait<Response<dynamic>>(<Future<Response<dynamic>>>[
        client.dio.get<dynamic>(protectedPath),
        client.dio.get<dynamic>('$protectedPath/2'),
        client.dio.get<dynamic>('$protectedPath/3'),
      ]);

      expect(responses.every((Response<dynamic> r) => r.statusCode == 200), isTrue);
      expect(adapter.countPath(refreshPath), 1);
    });
  });

  group('ErrorMappingInterceptor', () {
    Future<ApiException?> captureError(FakeHttpAdapter adapter) async {
      final client = buildClient(adapter);
      try {
        await client.dio.get<dynamic>(protectedPath);
        return null;
      } on DioException catch (e) {
        return e.apiException;
      }
    }

    test('400 có fieldErrors → ValidationException', () async {
      final error = await captureError(FakeHttpAdapter(
        (_) async => jsonResponse(
          400,
          errorEnvelope('ERR_VALIDATION', 'Invalid',
              fieldErrors: <String, String>{'fullName': 'must not be blank'}),
        ),
      ));

      expect(error, isA<ValidationException>());
      expect(error!.fieldErrors, <String, String>{'fullName': 'must not be blank'});
    });

    test('5xx → ServerException', () async {
      final error = await captureError(FakeHttpAdapter(
        (_) async => jsonResponse(500, errorEnvelope('ERR_INTERNAL', 'boom')),
      ));

      expect(error, isA<ServerException>());
    });

    test('409 có envelope → BusinessException giữ nguyên code gốc', () async {
      final error = await captureError(FakeHttpAdapter(
        (_) async => jsonResponse(
          409,
          errorEnvelope('ERR_INVENTORY_012', 'Item already consumed'),
        ),
      ));

      expect(error, isA<BusinessException>());
      expect(error!.code, 'ERR_INVENTORY_012');
    });

    test('body không có envelope (raw proxy 502) → fallback theo status, không crash',
        () async {
      final error = await captureError(FakeHttpAdapter(
        (_) async => ResponseBody.fromString('<html>502 Bad Gateway</html>', 502),
      ));

      expect(error, isA<ServerException>());
      expect(error!.code, 'ERR_INTERNAL');
    });

    test('không có response (offline/timeout) → NetworkException', () async {
      final error = await captureError(FakeHttpAdapter(
        (RequestOptions options) async =>
            throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        ),
      ));

      expect(error, isA<NetworkException>());
      expect(error!.code, 'ERR_NETWORK');
    });

    test('401 trên endpoint public KHÔNG trigger refresh', () async {
      final adapter = FakeHttpAdapter(
        (_) async => jsonResponse(
          401,
          errorEnvelope('ERR_AUTH_004', 'Bad credentials'),
        ),
      );
      final client = buildClient(adapter);

      ApiException? caught;
      try {
        await client.dio.post<dynamic>(loginPath, data: <String, dynamic>{});
      } on DioException catch (e) {
        caught = e.apiException;
      }

      expect(caught, isA<AuthExpiredException>());
      expect(adapter.countPath(refreshPath), 0);
    });
  });
}
