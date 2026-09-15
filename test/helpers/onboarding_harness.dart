import 'package:dio/dio.dart';
import 'package:smart_kitchen_mobile/data/auth/auth_repository.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/household/household_repository.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_usecases.dart';
import 'package:smart_kitchen_mobile/domain/household/household_usecases.dart';
import 'package:smart_kitchen_mobile/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/stores/household_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import 'fake_http_adapter.dart';

/// Gateway Google giả — tách được hai kết cục mà Flow 2 bắt buộc phân biệt:
/// user **hủy** popup (trả null, không phải lỗi) và SDK **ném lỗi**.
class FakeGoogleAuthGateway implements GoogleAuthGateway {
  FakeGoogleAuthGateway({this.idToken = 'google-id-token', this.throwOnSignIn});

  final String? idToken;
  final Object? throwOnSignIn;
  int signInCount = 0;

  @override
  Future<String?> signInWithGoogle() async {
    signInCount++;
    final error = throwOnSignIn;
    if (error != null) throw error;
    return idToken;
  }

  @override
  Future<void> signOut() async {}
}

/// Dựng store thật trên repository + use case thật, chỉ thay tầng transport —
/// giống cách demo mode chạy, nên test đi đúng code production.
class OnboardingHarness {
  OnboardingHarness(this.adapter, {FakeGoogleAuthGateway? googleGateway})
      : googleGateway = googleGateway ?? FakeGoogleAuthGateway() {
    tokenStorage = TokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    dioClient = DioClient.build(tokenStorage: tokenStorage, dio: dio);
    dioClient.dio.httpClientAdapter = adapter;

    final refreshUseCase = AuthRefreshUseCase(dioClient.dio);
    sessionStore = SessionStore(tokenStorage, refreshUseCase);

    final authRepository = AuthRepository(dioClient.dio);
    final householdRepository = HouseholdRepository(dioClient.dio);
    final persist = PersistSessionUseCase(sessionStore);
    final refreshClaims = RefreshSessionClaimsUseCase(
      refreshUseCase,
      tokenStorage,
      sessionStore,
    );

    authStore = AuthStore(
      googleLogin: GoogleLoginUseCase(
        this.googleGateway,
        authRepository,
        persist,
      ),
      register: RegisterUseCase(authRepository),
      sendOtp: SendOtpUseCase(authRepository),
      verifyOtp: VerifyOtpUseCase(authRepository, persist),
      emailLogin: EmailLoginUseCase(authRepository, persist),
      upgradeProfile: UpgradeProfileUseCase(
        authRepository,
        tokenStorage,
        sessionStore,
      ),
    );

    householdStore = HouseholdStore(
      createHousehold: CreateHouseholdUseCase(
        householdRepository,
        refreshClaims,
      ),
      previewInvite: PreviewInviteUseCase(householdRepository),
      joinHousehold: JoinHouseholdUseCase(householdRepository, refreshClaims),
      qrJoin: QrJoinUseCase(authRepository, persist),
      sessionStore: sessionStore,
    );
  }

  final FakeHttpAdapter adapter;
  final FakeGoogleAuthGateway googleGateway;

  late final TokenStorage tokenStorage;
  late final DioClient dioClient;
  late final SessionStore sessionStore;
  late final AuthStore authStore;
  late final HouseholdStore householdStore;
}

/// Payload phiên đúng shape `EmailAuthSessionResponse`/`GoogleLoginResponse`.
Map<String, dynamic> sessionData({
  String? householdId,
  String role = 'OWNER',
  String provider = 'EMAIL',
  bool accountLinked = false,
}) =>
    <String, dynamic>{
      'accessToken': fakeJwt(<String, dynamic>{
        'sub': 'u1',
        'household_id': householdId,
        'role': role,
        'provider': provider,
      }),
      'refreshToken': 'refresh-1',
      'expiresIn': 900,
      'user': <String, dynamic>{
        'id': 'u1',
        'email': 'demo@test.local',
        'fullName': 'Demo',
        'avatarUrl': null,
      },
      'accountLinked': accountLinked,
    };
