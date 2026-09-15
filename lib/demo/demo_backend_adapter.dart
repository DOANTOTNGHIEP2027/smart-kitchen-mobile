import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Backend giả lập cho bản demo — **chỉ bật khi `DEMO_MODE=true`**.
///
/// Thay tầng transport của Dio, không đụng bất kỳ dòng nào trong repository,
/// use case hay store: mọi thứ phía trên vẫn chạy đúng code production, đi qua
/// đủ pipeline interceptor và envelope thật. Nhờ vậy demo chứng minh được
/// luồng thật chứ không phải một UI rỗng.
///
/// Response bám đúng `docs/contracts/openapi/{auth-jwt,household-invite-role}.yaml`.
///
/// Kịch bản demo:
/// - OTP đúng là `123456`; mã khác trả `ERR_AUTH_OTP_INVALID`.
/// - Đăng nhập: mật khẩu `password` là đúng; sai 3 lần liên tiếp → khoá 429.
/// - `taken@demo.local` đã tồn tại → `ERR_AUTH_003`.
/// - Mã mời hợp lệ: `DEMO1234`. `EXPIRED1` → hết hạn. `RACED123` → bị dùng mất.
/// - Mã mời do chính demo tạo ra khi tạo Nhà cũng dùng được ngay.
class DemoBackendAdapter implements HttpClientAdapter {
  DemoBackendAdapter();

  static const String validInviteCode = 'DEMO1234';
  static const String expiredInviteCode = 'EXPIRED1';
  static const String racedInviteCode = 'RACED123';
  static const String correctOtp = '123456';
  static const String correctPassword = 'password';
  static const String takenEmail = 'taken@demo.local';

  static const Duration _latency = Duration(milliseconds: 450);

  /// State phiên demo — quyết định claim mà `/auth/refresh` trả về.
  String? _householdId;
  String _role = 'OWNER';
  String _provider = 'EMAIL';
  String _userId = 'demo-user-0001';
  String _fullName = 'Người dùng demo';
  String? _email;
  int _failedLogins = 0;
  int _otpSends = 0;
  final Set<String> _issuedInviteCodes = <String>{};
  final Set<String> _usedInviteCodes = <String>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(_latency); // để spinner thật sự nhìn thấy được
    final body = options.data is Map<String, dynamic>
        ? options.data as Map<String, dynamic>
        : const <String, dynamic>{};
    return _route(options, body);
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _route(RequestOptions options, Map<String, dynamic> body) {
    final path = options.path;

    if (path.startsWith('/api/v1/households/invites/')) {
      return _previewInvite(
        path.substring('/api/v1/households/invites/'.length),
      );
    }

    return switch (path) {
      '/api/v1/auth/google' => _googleLogin(),
      '/api/v1/auth/email/register' => _register(body),
      '/api/v1/auth/email/send-otp' => _sendOtp(),
      '/api/v1/auth/email/verify-otp' => _verifyOtp(body),
      '/api/v1/auth/email/login' => _login(body),
      '/api/v1/auth/refresh' => _refresh(),
      '/api/v1/auth/qr-join' => _qrJoin(body),
      '/api/v1/auth/upgrade-profile' => _upgradeProfile(body),
      '/api/v1/households' => _createHousehold(body),
      '/api/v1/households/join' => _joinHousehold(body),
      _ => _error(404, 'ERR_NOT_FOUND', 'Demo chưa mô phỏng endpoint này'),
    };
  }

  // ── Auth ─────────────────────────────────────────────────────────

  ResponseBody _googleLogin() {
    _provider = 'GOOGLE';
    _email = 'demo@gmail.com';
    _fullName = 'Demo Google';
    return _ok(200, <String, dynamic>{
      ..._sessionPayload(),
      'accountLinked': false,
    });
  }

  ResponseBody _register(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase();
    if (email == takenEmail) {
      return _error(409, 'ERR_AUTH_003', 'Email already registered');
    }
    _email = email;
    _fullName = body['fullName'] as String? ?? _fullName;
    _provider = 'EMAIL';
    _otpSends = 1;
    return _ok(201, <String, dynamic>{
      'requiresOtpVerification': true,
      'message': 'OTP đã được gửi đến email của bạn',
      'email': email,
    });
  }

  /// Luôn 200 kể cả email không tồn tại (chống dò email) — trừ khi chạm giới
  /// hạn 3 OTP đang active.
  ResponseBody _sendOtp() {
    _otpSends++;
    if (_otpSends > 3) {
      return _error(429, 'ERR_AUTH_OTP_LIMIT', 'Too many OTP requests');
    }
    return _ok(200, <String, dynamic>{
      'message': 'Nếu email này đã đăng ký, OTP đã được gửi',
    });
  }

  ResponseBody _verifyOtp(Map<String, dynamic> body) {
    if ((body['otp'] as String? ?? '') != correctOtp) {
      return _error(400, 'ERR_AUTH_OTP_INVALID', 'OTP invalid or expired');
    }
    _otpSends = 0;
    _email = body['email'] as String? ?? _email;
    return _ok(200, _sessionPayload());
  }

  ResponseBody _login(Map<String, dynamic> body) {
    if (_failedLogins >= 3) {
      return _error(429, 'ERR_AUTH_RATE_LIMIT', 'Too many attempts');
    }
    if ((body['password'] as String? ?? '') != correctPassword) {
      _failedLogins++;
      return _error(401, 'ERR_AUTH_004', 'Invalid credentials');
    }
    _failedLogins = 0;
    _email = body['email'] as String? ?? _email;
    _provider = 'EMAIL';
    return _ok(200, _sessionPayload());
  }

  ResponseBody _refresh() => _ok(200, <String, dynamic>{
        'accessToken': _accessToken(),
        'refreshToken': 'demo-refresh-${DateTime.now().microsecondsSinceEpoch}',
        'expiresIn': 900,
      });

  /// Khác mọi response auth khác: JWT được phát hành kèm sẵn claim household,
  /// nên không cần refresh (S8.10).
  ResponseBody _qrJoin(Map<String, dynamic> body) {
    final code = (body['inviteCode'] as String? ?? '').toUpperCase();
    final failure = _inviteFailure(code, invalidCode: 'ERR_AUTH_INVITE_INVALID');
    if (failure != null) return failure;

    _usedInviteCodes.add(code);
    _householdId = 'demo-household-0001';
    _role = 'MEMBER';
    _provider = 'GUEST';
    _userId = 'demo-guest-0002';
    _fullName = body['displayName'] as String? ?? 'Thành viên';
    _email = null;
    return _ok(201, <String, dynamic>{
      ..._sessionPayload(),
      'householdId': _householdId,
      'role': _role,
      'requiresProfileCompletion': true,
    });
  }

  ResponseBody _upgradeProfile(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').toLowerCase();
    if (email == takenEmail) {
      return _error(409, 'ERR_AUTH_003', 'Email already registered');
    }
    _email = email;
    _provider = 'EMAIL';
    _fullName = body['fullName'] as String? ?? _fullName;
    _otpSends = 1;
    return _ok(200, <String, dynamic>{
      'accessToken': _accessToken(),
      'refreshToken': 'demo-refresh-upgrade',
      'expiresIn': 900,
      'requiresOtpVerification': true,
      'message': 'Vui lòng xác minh email để hoàn tất.',
    });
  }

  // ── Household ────────────────────────────────────────────────────

  ResponseBody _createHousehold(Map<String, dynamic> body) {
    if (_householdId != null) {
      return _error(409, 'ERR_HH_003', 'User already belongs to a household');
    }
    _householdId = 'demo-household-0001';
    _role = 'OWNER';
    final code = _generateInviteCode();
    _issuedInviteCodes.add(code);
    return _ok(201, <String, dynamic>{
      'id': _householdId,
      'name': body['name'] as String? ?? 'Gia đình demo',
      'ownerId': _userId,
      'inviteCode': code,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  ResponseBody _previewInvite(String rawCode) {
    final code = rawCode.toUpperCase();
    if (code == expiredInviteCode) {
      return _error(400, 'ERR_HH_002', 'Invite is expired or invalid');
    }
    if (!_isKnownCode(code)) {
      return _error(400, 'ERR_HH_002', 'Invite is expired or invalid');
    }
    return _ok(200, <String, dynamic>{
      'householdName': 'Gia đình Nguyễn',
      'ownerName': 'Nguyễn Đình Phúc',
      'memberCount': 3,
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 72))
          .toIso8601String(),
      'isValid': true,
    });
  }

  ResponseBody _joinHousehold(Map<String, dynamic> body) {
    final code = (body['code'] as String? ?? '').toUpperCase();
    final failure = _inviteFailure(code, invalidCode: 'ERR_HH_002');
    if (failure != null) return failure;

    _usedInviteCodes.add(code);
    _householdId = 'demo-household-0001';
    _role = 'MEMBER';
    return _ok(200, <String, dynamic>{
      'householdId': _householdId,
      'householdName': 'Gia đình Nguyễn',
      'role': _role,
      'requiresTokenRefresh': true,
    });
  }

  ResponseBody? _inviteFailure(String code, {required String invalidCode}) {
    if (code == racedInviteCode || _usedInviteCodes.contains(code)) {
      return _error(400, 'ERR_HH_005', 'Invite has already been used');
    }
    if (code == expiredInviteCode || !_isKnownCode(code)) {
      return _error(400, invalidCode, 'Invite is expired or invalid');
    }
    return null;
  }

  bool _isKnownCode(String code) =>
      code == validInviteCode ||
      code == racedInviteCode ||
      _issuedInviteCodes.contains(code);

  String _generateInviteCode() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    // Không dùng Random: lấy timestamp để mã ổn định trong một phiên demo và
    // dễ đọc lại khi cần thử lại cùng một kịch bản.
    var seed = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(alphabet[seed % alphabet.length]);
      seed ~/= alphabet.length;
    }
    return buffer.toString();
  }

  // ── Dựng response ────────────────────────────────────────────────

  Map<String, dynamic> _sessionPayload() => <String, dynamic>{
        'accessToken': _accessToken(),
        'refreshToken': 'demo-refresh-${DateTime.now().microsecondsSinceEpoch}',
        'expiresIn': 900,
        'user': <String, dynamic>{
          'id': _userId,
          'email': _email,
          'fullName': _fullName,
          'avatarUrl': null,
        },
      };

  /// JWT không ký — chỉ phần payload là thật để `decodeJwtPayload` đọc được
  /// `household_id`/`role`/`provider` (claim giữ snake_case theo
  /// naming-convention.md §4).
  String _accessToken() {
    String encode(Map<String, dynamic> part) =>
        base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');

    final header = encode(<String, dynamic>{'alg': 'none', 'typ': 'JWT'});
    final payload = encode(<String, dynamic>{
      'sub': _userId,
      'household_id': _householdId,
      'role': _role,
      'provider': _provider,
    });
    return '$header.$payload.demo-signature';
  }

  ResponseBody _ok(int status, Map<String, dynamic> data) => _json(status, {
        'success': true,
        'data': data,
        'error': null,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

  ResponseBody _error(int status, String code, String message) =>
      _json(status, {
        'success': false,
        'data': null,
        'error': <String, dynamic>{'code': code, 'message': message},
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

  ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
}
