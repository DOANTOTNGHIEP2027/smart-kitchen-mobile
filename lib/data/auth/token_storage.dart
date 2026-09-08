abstract interface class TokenStorage {
  String? get accessToken;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> readRefreshToken();

  Future<void> clear();
}
