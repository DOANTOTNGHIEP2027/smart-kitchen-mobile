import 'package:mobx/mobx.dart';

import '../data/auth/jwt_claims.dart';
import '../data/auth/token_storage.dart';
import '../data/network/interceptors/token_refresh_interceptor.dart';
import '../domain/user_summary.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

typedef RefreshTokens = Future<TokenPair> Function(String refreshToken);

class SessionStore {
  SessionStore(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final Observable<AuthStatus> _status = Observable(AuthStatus.unknown);
  final Observable<UserSummary?> _currentUser = Observable(null);
  final Observable<String?> _householdId = Observable(null);
  final Observable<String?> _role = Observable(null);
  final Observable<String?> _provider = Observable(null);
  RefreshTokens? _refreshTokens;

  AuthStatus get status => _status.value;
  UserSummary? get currentUser => _currentUser.value;
  String? get householdId => _householdId.value;
  String? get role => _role.value;
  String? get provider => _provider.value;

  void configureRefresh(RefreshTokens refreshTokens) {
    _refreshTokens = refreshTokens;
  }

  Future<void> bootstrap() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || _refreshTokens == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    try {
      final tokens = await _refreshTokens!(refreshToken);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      applyRefreshedClaims(tokens.accessToken);
      _setStatus(AuthStatus.authenticated);
    } catch (_) {
      await clear();
    }
  }

  Future<void> setSession({
    required String accessToken,
    required String refreshToken,
    required UserSummary user,
  }) async {
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    runInAction(() {
      _currentUser.value = user;
      _applyClaims(accessToken);
      _status.value = AuthStatus.authenticated;
    });
  }

  void applyRefreshedClaims(String accessToken) {
    runInAction(() => _applyClaims(accessToken));
  }

  Future<void> clear() async {
    await _tokenStorage.clear();
    runInAction(() {
      _currentUser.value = null;
      _householdId.value = null;
      _role.value = null;
      _provider.value = null;
      _status.value = AuthStatus.unauthenticated;
    });
  }

  void _applyClaims(String accessToken) {
    final claims = decodeJwtPayload(accessToken);
    _householdId.value = claims['household_id'] as String?;
    _role.value = claims['role'] as String?;
    _provider.value = claims['provider'] as String?;
  }

  void _setStatus(AuthStatus status) {
    runInAction(() => _status.value = status);
  }

}
