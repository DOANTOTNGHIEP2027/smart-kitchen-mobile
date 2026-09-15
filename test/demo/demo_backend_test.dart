import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/jwt_claims.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/demo/demo_backend_adapter.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/household/api/household_api.dart';
import 'package:smart_kitchen_mobile/utils/dio_exception_x.dart';

import '../helpers/secure_storage_channel.dart';

/// `DemoBackendAdapter` chỉ hữu ích nếu payload nó trả về parse được bằng
/// **chính** model production. Nếu một model đổi tên field mà demo không đổi
/// theo, bản demo sẽ vỡ lúc trình diễn chứ không phải lúc chạy test — nên
/// khoá lại ở đây.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late AuthApi authApi;
  late HouseholdApi householdApi;

  setUp(() {
    storageChannel.install();
    final client = DioClient.build(
      tokenStorage: TokenStorage(),
      dio: Dio(BaseOptions(baseUrl: 'https://demo.local')),
    )..dio.httpClientAdapter = DemoBackendAdapter();
    authApi = AuthApiImpl(client);
    householdApi = HouseholdApiImpl(client);
  });

  tearDown(storageChannel.uninstall);

  test('đăng ký → OTP đúng trả session parse được', () async {
    final registered = await authApi.register(
      email: 'a@demo.local',
      password: 'password123',
      fullName: 'Demo',
    );
    expect(registered.requiresOtp, isTrue);

    final session = await authApi.verifyOtp(
      email: 'a@demo.local',
      otp: DemoBackendAdapter.correctOtp,
    );

    expect(session.accessToken, isNotEmpty);
    expect(session.user.id, isNotEmpty);
    // JWT giả phải decode được, nếu không thì điều hướng household sẽ sai.
    expect(decodeJwtPayload(session.accessToken), isNotEmpty);
  });

  test('email đã tồn tại trả ERR_AUTH_003 có kiểu', () async {
    ApiException? caught;
    try {
      await authApi.register(
        email: DemoBackendAdapter.takenEmail,
        password: 'password123',
        fullName: 'Demo',
      );
    } on DioException catch (e) {
      caught = e.apiException;
    }

    expect(caught?.code, 'ERR_AUTH_003');
  });

  test('OTP sai trả ERR_AUTH_OTP_INVALID', () async {
    ApiException? caught;
    try {
      await authApi.verifyOtp(email: 'a@demo.local', otp: '000000');
    } on DioException catch (e) {
      caught = e.apiException;
    }

    expect(caught?.code, 'ERR_AUTH_OTP_INVALID');
  });

  test('sai mật khẩu 3 lần → khoá 429', () async {
    Future<String?> attempt() async {
      try {
        await authApi.login(email: 'a@demo.local', password: 'sai');
        return null;
      } on DioException catch (e) {
        return e.apiException?.code;
      }
    }

    expect(await attempt(), 'ERR_AUTH_004');
    expect(await attempt(), 'ERR_AUTH_004');
    expect(await attempt(), 'ERR_AUTH_004');
    expect(await attempt(), 'ERR_AUTH_RATE_LIMIT');
  });

  test('tạo Nhà trả inviteCode, và mã đó preview được ngay', () async {
    final created = await householdApi.create('Nhà demo');

    expect(created.inviteCode.length, 8);

    final preview = await householdApi.preview(created.inviteCode);

    expect(preview.isValid, isTrue);
    expect(preview.householdName, isNotEmpty);
  });

  test('mã mời có sẵn: hợp lệ, hết hạn, bị dùng mất', () async {
    final valid =
        await householdApi.preview(DemoBackendAdapter.validInviteCode);
    expect(valid.isValid, isTrue);

    Future<String?> previewCode(String code) async {
      try {
        await householdApi.preview(code);
        return null;
      } on DioException catch (e) {
        return e.apiException?.code;
      }
    }

    expect(await previewCode(DemoBackendAdapter.expiredInviteCode), 'ERR_HH_002');

    String? joinCode;
    try {
      await householdApi.join(DemoBackendAdapter.racedInviteCode);
    } on DioException catch (e) {
      joinCode = e.apiException?.code;
    }
    expect(joinCode, 'ERR_HH_005');
  });

  test('guest join trả session kèm cờ hoàn tất hồ sơ', () async {
    final result = await authApi.joinAsGuest(
      inviteCode: DemoBackendAdapter.validInviteCode,
      displayName: 'Bé Na',
    );

    expect(result.requiresProfileCompletion, isTrue);
    // JWT của qr-join phải mang sẵn household_id (S8.10 — không cần refresh).
    final claims = decodeJwtPayload(result.session.accessToken);
    expect(claims['household_id'], isNotNull);
  });
}
