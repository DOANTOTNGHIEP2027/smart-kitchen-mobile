import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/domain/auth_models.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/form_status.dart';
import 'package:smart_kitchen_mobile/scenes/auth/widgets/auth_frame.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockGateway extends Mock implements GoogleAuthGateway {}

/// #16 / OD-38 — AC "AuthStore.isLoggedIn update đúng" map sang
/// `SessionStore.isAuthenticated`; `isLoading` → `AuthStore.isSubmitting`.
void main() {
  late _MockAuthApi api;
  late _MockGateway gateway;
  late _MemoryTokenStorage storage;
  late SessionStore session;
  late AuthStore store;

  AuthSession googleSession({bool accountLinked = false}) => AuthSession(
        accessToken: _jwt(<String, dynamic>{
          'household_id': null,
          'role': null,
          'provider': 'GOOGLE',
        }),
        refreshToken: 'refresh',
        user: const UserSummary(
            id: 'u1', fullName: 'An', email: 'an@example.com'),
        accountLinked: accountLinked,
      );

  setUp(() {
    api = _MockAuthApi();
    gateway = _MockGateway();
    storage = _MemoryTokenStorage();
    // Không truyền revokeUseCase → logout không gọi BE.
    session = SessionStore(storage, AuthRefreshUseCase(Dio()));
    store = AuthStore(api, session, gateway);
  });
  tearDown(() => store.dispose());

  test('thành công → gửi đúng Firebase ID token, session đăng nhập', () async {
    when(() => gateway.signInWithGoogle())
        .thenAnswer((_) async => 'firebase-id-token');
    when(() => api.loginWithGoogle(any()))
        .thenAnswer((_) async => googleSession(accountLinked: true));

    expect(session.isAuthenticated, isFalse);
    final ok = await store.googleSignIn();

    expect(ok, isTrue);
    verify(() => api.loginWithGoogle('firebase-id-token')).called(1);
    expect(session.isAuthenticated, isTrue);
    expect(session.currentUser?.email, 'an@example.com');
    expect(store.status, FormStatus.success);
    expect(store.isSubmitting, isFalse);
    expect(store.error, isNull);
    expect(store.accountLinked, isTrue);
    expect(storage.refreshToken, 'refresh');
  });

  test('đang chờ → isSubmitting = true (AC isLoading)', () async {
    when(() => gateway.signInWithGoogle())
        .thenAnswer((_) async => 'firebase-id-token');
    when(() => api.loginWithGoogle(any()))
        .thenAnswer((_) async => googleSession());

    final pending = store.googleSignIn();
    expect(store.isSubmitting, isTrue);
    await pending;
    expect(store.isSubmitting, isFalse);
  });

  test('huỷ picker → không lỗi, không gọi BE, vẫn chưa đăng nhập', () async {
    when(() => gateway.signInWithGoogle()).thenAnswer((_) async => null);

    final ok = await store.googleSignIn();

    expect(ok, isFalse);
    verifyNever(() => api.loginWithGoogle(any()));
    expect(store.status, FormStatus.idle);
    expect(store.error, isNull);
    expect(session.isAuthenticated, isFalse);
  });

  test('Firebase chưa cấu hình → ERR_AUTH_FIREBASE_UNAVAILABLE', () async {
    when(() => gateway.signInWithGoogle())
        .thenThrow(const GoogleAuthUnavailableException());

    expect(await store.googleSignIn(), isFalse);
    expect(store.status, FormStatus.failure);
    expect(store.error?.code, 'ERR_AUTH_FIREBASE_UNAVAILABLE');
    expect(errorCopyKey(store.error!.code), 'google_unavailable');
    expect(session.isAuthenticated, isFalse);
  });

  test('Firebase không trả token → báo lỗi, không im lặng như huỷ', () async {
    when(() => gateway.signInWithGoogle())
        .thenThrow(const GoogleAuthTokenMissingException());

    expect(await store.googleSignIn(), isFalse);
    expect(store.error?.code, 'ERR_AUTH_GOOGLE_TOKEN_MISSING');
    expect(errorCopyKey(store.error!.code), 'google_token_invalid');
    verifyNever(() => api.loginWithGoogle(any()));
  });

  test('gateway báo mất mạng (đã đổi lỗi SDK) → ERR_NETWORK', () async {
    when(() => gateway.signInWithGoogle()).thenThrow(NetworkException());
    expect(await store.googleSignIn(), isFalse);
    expect(store.error?.code, 'ERR_NETWORK');
    verifyNever(() => api.loginWithGoogle(any()));
  });

  test('mất mạng khi gọi BE → ERR_NETWORK, không đăng nhập', () async {
    when(() => gateway.signInWithGoogle())
        .thenAnswer((_) async => 'firebase-id-token');
    when(() => api.loginWithGoogle(any())).thenThrow(NetworkException());

    expect(await store.googleSignIn(), isFalse);
    expect(store.error?.code, 'ERR_NETWORK');
    expect(session.isAuthenticated, isFalse);
  });

  test('BE từ chối token (ERR_AUTH_001) → lỗi đúng mã', () async {
    when(() => gateway.signInWithGoogle())
        .thenAnswer((_) async => 'firebase-id-token');
    when(() => api.loginWithGoogle(any()))
        .thenThrow(AuthExpiredException('ERR_AUTH_001', 'invalid'));

    expect(await store.googleSignIn(), isFalse);
    expect(store.error?.code, 'ERR_AUTH_001');
  });

  test('bấm 2 lần khi đang chờ → chỉ 1 lần gọi gateway', () async {
    when(() => gateway.signInWithGoogle())
        .thenAnswer((_) async => 'firebase-id-token');
    when(() => api.loginWithGoogle(any()))
        .thenAnswer((_) async => googleSession());

    final first = store.googleSignIn();
    final second = await store.googleSignIn();
    await first;

    expect(second, isFalse);
    verify(() => gateway.signInWithGoogle()).called(1);
  });

  test('logout → xoá phiên + signOut Google/Firebase', () async {
    when(() => gateway.signInWithGoogle())
        .thenAnswer((_) async => 'firebase-id-token');
    when(() => api.loginWithGoogle(any()))
        .thenAnswer((_) async => googleSession());
    when(() => gateway.signOut()).thenAnswer((_) async {});
    await store.googleSignIn();

    await store.logout();

    expect(session.isAuthenticated, isFalse);
    expect(session.currentUser, isNull);
    expect(storage.refreshToken, isNull);
    verify(() => gateway.signOut()).called(1);
  });

  test('logout khi signOut native lỗi → vẫn đăng xuất cục bộ', () async {
    when(() => gateway.signInWithGoogle())
        .thenAnswer((_) async => 'firebase-id-token');
    when(() => api.loginWithGoogle(any()))
        .thenAnswer((_) async => googleSession());
    when(() => gateway.signOut()).thenThrow(Exception('native'));
    await store.googleSignIn();

    await store.logout();

    expect(session.isAuthenticated, isFalse);
    expect(store.status, FormStatus.idle);
  });
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? user;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    user = null;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<Map<String, dynamic>?> readUser() async => user;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveUser(Map<String, dynamic> json) async => user = json;
}

String _jwt(Map<String, dynamic> claims) {
  final payload =
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return 'header.$payload.signature';
}
