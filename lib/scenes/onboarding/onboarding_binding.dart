import 'package:get/get.dart';

import '../../data/auth/auth_repository.dart';
import '../../data/auth/google_auth_gateway.dart';
import '../../data/auth/token_storage.dart';
import '../../data/household/household_repository.dart';
import '../../data/network/dio_client.dart';
import '../../domain/auth/auth_refresh_usecase.dart';
import '../../domain/auth/auth_usecases.dart';
import '../../domain/household/household_usecases.dart';
import '../../stores/auth_store.dart';
import '../../stores/household_store.dart';
import '../../stores/session_store.dart';

/// DI cho toàn bộ feature onboarding.
///
/// [AuthStore] và [HouseholdStore] được đăng ký **permanent** vì state của
/// chúng phải sống xuyên nhiều route: `pendingEmail` đặt ở màn đăng ký nhưng
/// đọc ở màn OTP, `pendingCode` đặt ở màn nhập mã nhưng đọc ở màn preview.
/// Một binding theo-route sẽ tạo instance mới ở mỗi lần điều hướng và làm mất
/// đúng những giá trị đó.
///
/// Binding được gắn cho mọi route onboarding nên phải idempotent — đăng ký lại
/// sẽ thay instance và xoá sạch state đang dở.
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AuthStore>() && Get.isRegistered<HouseholdStore>()) {
      return;
    }

    final dio = Get.find<DioClient>().dio;
    final tokenStorage = Get.find<TokenStorage>();
    final sessionStore = Get.find<SessionStore>();

    final authRepository = AuthRepository(dio);
    final householdRepository = HouseholdRepository(dio);
    final persistSession = PersistSessionUseCase(sessionStore);
    final refreshClaims = RefreshSessionClaimsUseCase(
      AuthRefreshUseCase(dio),
      tokenStorage,
      sessionStore,
    );

    // Gateway Google đăng ký ở đây (không phải bootstrap) theo fe-app-shell.md
    // §13: shell cố tình chưa đăng ký vì tới FE-2 mới có consumer.
    if (!Get.isRegistered<GoogleAuthGateway>()) {
      Get.put<GoogleAuthGateway>(GoogleAuthGatewayImpl(), permanent: true);
    }

    final qrJoin = QrJoinUseCase(authRepository, persistSession);

    Get.put<AuthStore>(
      AuthStore(
        googleLogin: GoogleLoginUseCase(
          Get.find<GoogleAuthGateway>(),
          authRepository,
          persistSession,
        ),
        register: RegisterUseCase(authRepository),
        sendOtp: SendOtpUseCase(authRepository),
        verifyOtp: VerifyOtpUseCase(authRepository, persistSession),
        emailLogin: EmailLoginUseCase(authRepository, persistSession),
        upgradeProfile: UpgradeProfileUseCase(
          authRepository,
          tokenStorage,
          sessionStore,
        ),
      ),
      permanent: true,
    );

    Get.put<HouseholdStore>(
      HouseholdStore(
        createHousehold: CreateHouseholdUseCase(
          householdRepository,
          refreshClaims,
        ),
        previewInvite: PreviewInviteUseCase(householdRepository),
        joinHousehold: JoinHouseholdUseCase(householdRepository, refreshClaims),
        qrJoin: qrJoin,
        sessionStore: sessionStore,
      ),
      permanent: true,
    );

    // Hai store trên sống lâu hơn một phiên. Khi phiên kết thúc — đăng xuất,
    // hoặc `TokenRefreshInterceptor` clear session sau khi refresh cạn — phải
    // dọn, nếu không state của user trước sẽ hiện ra cho user sau.
    // Đăng ký đúng một lần, cùng chỗ với việc tạo store.
    sessionStore.addOnClearedListener(() {
      Get.find<AuthStore>().reset();
      Get.find<HouseholdStore>().reset();
    });
  }
}
