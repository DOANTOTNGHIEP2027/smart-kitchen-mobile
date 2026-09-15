import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu trữ token (fe-app-shell.md §8, quyết định D6).
///
/// Access token **chỉ** nằm in-memory — không bao giờ chạm disk. Chỉ refresh
/// token được ghi vào secure storage.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _secure;
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    await _secure.write(key: _refreshTokenKey, value: refresh);
  }

  Future<String?> readRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<void> clear() async {
    _accessToken = null;
    await _secure.delete(key: _refreshTokenKey);
  }
}
