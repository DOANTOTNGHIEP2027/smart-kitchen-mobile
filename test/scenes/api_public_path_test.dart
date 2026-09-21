import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_revoke_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/household/api/household_api.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/secure_storage_channel.dart';

/// Các test store hiện có mock thẳng `AuthApi`/`HouseholdApi`, nên chúng không
/// bao giờ nhìn thấy path thật mà Dio gửi đi. File này đi qua `DioClient` thật
/// để khoá lại hai thứ chỉ lộ ra ở tầng đó:
///
/// 1. Path phải mang đủ tiền tố `/api` (OAS: `servers: - url: /api`).
/// 2. Endpoint public phải khớp `DioClient.publicPaths` để
///    `AuthHeaderInterceptor` KHÔNG gắn `Authorization` vào.
///
/// Điểm 2 mới là cái nguy hiểm: nếu login/register mang theo auth header, một
/// 401 "sai mật khẩu" bình thường sẽ thoả guard `hadAuthHeader` và kích hoạt
/// refresh — đúng vòng lặp mà fe-app-shell.md §7.5 dựng guard để chặn.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late TokenStorage tokenStorage;
  late FakeHttpAdapter adapter;
  late DioClient client;

  setUp(() async {
    storageChannel.install();
    tokenStorage = TokenStorage();
    // Có sẵn access token: chính trạng thái này làm lộ lỗi. Không có token thì
    // interceptor chẳng có gì để gắn và test sẽ xanh giả.
    await tokenStorage.saveTokens('access-old', 'refresh-1');
    adapter = FakeHttpAdapter(
      (_) async => jsonResponse(200, successEnvelope(<String, dynamic>{})),
    );
    client = DioClient.build(
      tokenStorage: tokenStorage,
      dio: Dio(BaseOptions(baseUrl: 'https://test.local')),
    )..dio.httpClientAdapter = adapter;
  });

  tearDown(storageChannel.uninstall);

  /// Chỉ quan tâm request đã gửi đi; lỗi parse response giả là không liên quan.
  Future<RequestOptions> capture(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {
      // bỏ qua có chủ đích
    }
    return adapter.requests.last;
  }

  void expectPublic(RequestOptions request, String path) {
    expect(request.path, path);
    expect(
      DioClient.publicPaths,
      contains(path),
      reason: 'path phải khớp CHÍNH XÁC chuỗi trong DioClient.publicPaths',
    );
    expect(request.headers.containsKey('Authorization'), isFalse);
  }

  void expectAuthenticated(RequestOptions request, String path) {
    expect(request.path, path);
    expect(request.headers['Authorization'], 'Bearer access-old');
  }

  group('AuthApi — endpoint public không được mang Authorization', () {
    test('POST /auth/email/login', () async {
      final request = await capture(
        () => AuthApiImpl(client).login(email: 'a@b.com', password: 'x'),
      );

      expectPublic(request, '/api/v1/auth/email/login');
    });

    test('POST /auth/email/register', () async {
      final request = await capture(
        () => AuthApiImpl(client)
            .register(email: 'a@b.com', password: 'x', fullName: 'A'),
      );

      expectPublic(request, '/api/v1/auth/email/register');
    });

    test('POST /auth/email/send-otp', () async {
      final request =
          await capture(() => AuthApiImpl(client).sendOtp('a@b.com'));

      expectPublic(request, '/api/v1/auth/email/send-otp');
    });

    test('POST /auth/email/verify-otp', () async {
      final request = await capture(
        () => AuthApiImpl(client).verifyOtp(email: 'a@b.com', otp: '123456'),
      );

      expectPublic(request, '/api/v1/auth/email/verify-otp');
    });

    test('POST /auth/email/forgot-password', () async {
      final request = await capture(
        () => AuthApiImpl(client).forgotPassword('a@b.com'),
      );

      expectPublic(request, '/api/v1/auth/email/forgot-password');
    });

    test('POST /auth/email/reset-password', () async {
      final request = await capture(
        () => AuthApiImpl(client).resetPassword(email: 'a@b.com', otp: '123456', newPassword: 'password1'),
      );

      expectPublic(request, '/api/v1/auth/email/reset-password');
    });

    test('POST /auth/google', () async {
      final request = await capture(
        () => AuthApiImpl(client).loginWithGoogle('id-token'),
      );

      expectPublic(request, '/api/v1/auth/google');
    });

    test('POST /auth/qr-join', () async {
      final request = await capture(
        () => AuthApiImpl(client).joinAsGuest(inviteCode: 'DEMO1234'),
      );

      expectPublic(request, '/api/v1/auth/qr-join');
    });
  });

  group('Endpoint cần auth PHẢI mang Authorization', () {
    test('POST /auth/upgrade-profile', () async {
      final request = await capture(
        () => AuthApiImpl(client).upgrade(email: 'a@b.com', password: 'x'),
      );

      expectAuthenticated(request, '/api/v1/auth/upgrade-profile');
    });

    test('POST /households', () async {
      final request =
          await capture(() => HouseholdApiImpl(client).create('Nhà demo'));

      expectAuthenticated(request, '/api/v1/households');
    });

    test('POST /households/join', () async {
      final request =
          await capture(() => HouseholdApiImpl(client).join('DEMO1234'));

      expectAuthenticated(request, '/api/v1/households/join');
    });

    // revoke/revoke-all CẦN access token để BE biết thu hồi token của ai — nếu
    // lọt vào publicPaths, AuthHeaderInterceptor sẽ bỏ Authorization và BE trả
    // 401, khiến logout không bao giờ thu hồi được token server-side.
    test('POST /auth/revoke', () async {
      final request = await capture(
        () => AuthRevokeUseCase(client.dio).revoke('refresh-1'),
      );

      expectAuthenticated(request, '/api/v1/auth/revoke');
      expect(DioClient.publicPaths, isNot(contains('/api/v1/auth/revoke')));
    });

    test('POST /auth/revoke-all', () async {
      final request =
          await capture(() => AuthRevokeUseCase(client.dio).revokeAll());

      expectAuthenticated(request, '/api/v1/auth/revoke-all');
      expect(DioClient.publicPaths, isNot(contains('/api/v1/auth/revoke-all')));
    });
  });

  test('GET invites/{code} là public, khớp prefix path-templated', () async {
    final request =
        await capture(() => HouseholdApiImpl(client).preview('DEMO1234'));

    expect(request.path, '/api/v1/households/invites/DEMO1234');
    expect(request.headers.containsKey('Authorization'), isFalse);
  });
}
