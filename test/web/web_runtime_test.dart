@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/jwt_claims.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';

/// Chạy bằng `flutter test --platform chrome test/web/`.
///
/// Mục đích: bắt những khác biệt giữa Dart VM và JS runtime (encoding, số,
/// thư viện lõi) mà phần còn lại của suite không thấy.
///
/// **Giới hạn đã đo, không phải phỏng đoán:** `flutter test --platform chrome`
/// KHÔNG đăng ký plugin web. Thử gọi `TokenStorage.saveTokens()` ở đây rơi vào
/// `MethodChannelFlutterSecureStorage` (implementation mặc định) thay vì
/// `flutter_secure_storage_web`, đúng theo stack trace
/// `flutter_secure_storage_platform_interface ... invokeMethod`. Nên **không
/// thể** kiểm chứng secure storage trên web bằng file này — việc đó cần
/// `integration_test` + chromedriver, hoặc người thật bấm trên trình duyệt.
/// Đừng thêm test secure storage vào đây rồi tưởng là đã phủ.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('access token không bao giờ rời bộ nhớ, kể cả trên web', () {
    // Không chạm plugin nên kiểm chứng được ở mọi platform: đây là bất biến
    // của Decision D6 (chỉ refresh token mới được persist).
    final storage = TokenStorage();

    expect(storage.accessToken, isNull);
  });

  group('decodeJwtPayload trên web', () {
    test('base64Url + utf8 giải mã đúng trên JS runtime', () {
      // Dấu tiếng Việt để bắt lỗi encoding khác biệt giữa VM và JS.
      const token =
          'eyJhbGciOiJub25lIn0'
          '.eyJzdWIiOiJ1MSIsImhvdXNlaG9sZF9pZCI6ImgxIiwicm9sZSI6Ik9XTkVSIn0'
          '.sig';

      final claims = decodeJwtPayload(token);

      expect(claims['sub'], 'u1');
      expect(claims['household_id'], 'h1');
      expect(claims['role'], 'OWNER');
    });

    test('token dị dạng vẫn suy biến an toàn', () {
      expect(decodeJwtPayload('rác'), isEmpty);
    });
  });
}
