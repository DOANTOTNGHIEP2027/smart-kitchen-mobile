import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu trữ token + hồ sơ user tối thiểu (fe-app-shell.md §8, quyết định D6).
///
/// Access token **chỉ** nằm in-memory — không bao giờ chạm disk. Refresh token
/// và `UserSummary` (tên/email/avatar để hiển thị) được ghi vào secure storage.
/// BE không có `GET /users/me`, nên hồ sơ này là nguồn duy nhất để
/// `SessionStore.bootstrap()` khôi phục `currentUser` sau cold start.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  static const String _refreshTokenKey = 'refresh_token';
  static const String _userProfileKey = 'user_profile';

  final FlutterSecureStorage _secure;
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    await _secure.write(key: _refreshTokenKey, value: refresh);
  }

  Future<String?> readRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<void> saveUser(Map<String, dynamic> json) =>
      _secure.write(key: _userProfileKey, value: jsonEncode(json));

  /// Trả `null` khi chưa có hồ sơ hoặc dữ liệu hỏng — không bao giờ ném ra
  /// ngoài, vì hàm này chạy trong `bootstrap()` trước `runApp()`.
  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _secure.read(key: _userProfileKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    await _secure.delete(key: _refreshTokenKey);
    await _secure.delete(key: _userProfileKey);
  }
}
