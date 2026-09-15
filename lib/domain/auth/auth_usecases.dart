import '../../data/auth/auth_repository.dart';
import '../../data/auth/google_auth_gateway.dart';
import '../../data/auth/token_storage.dart';
import '../../stores/session_store.dart';
import 'auth_session.dart';

/// Ghi một phiên đã xác thực vào [TokenStorage] + [SessionStore].
///
/// Dùng chung cho mọi lối vào (Google, OTP verify, email login, QR-join) để
/// chỉ có **một** chỗ quyết định "đăng nhập thành công nghĩa là gì".
class PersistSessionUseCase {
  const PersistSessionUseCase(this._sessionStore);

  final SessionStore _sessionStore;

  Future<void> call(AuthSession session) => _sessionStore.setSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: session.user,
      );
}

/// Flow 2 — Google Sign-In.
///
/// Trả `null` khi user đóng popup Firebase: đó là một lượt **hủy**, không phải
/// lỗi, và caller phải quay về landing âm thầm, không hiện error banner
/// (fe-onboarding.md Flow 2, fe-app-shell.md §14).
class GoogleLoginUseCase {
  const GoogleLoginUseCase(this._gateway, this._repository, this._persist);

  final GoogleAuthGateway _gateway;
  final AuthRepository _repository;
  final PersistSessionUseCase _persist;

  Future<AuthSession?> call() async {
    final idToken = await _gateway.signInWithGoogle();
    if (idToken == null) return null; // user hủy
    final session = await _repository.loginWithGoogle(idToken);
    await _persist(session);
    return session;
  }
}

/// Flow 3 — đăng ký email. Chưa phát hành token; user phải verify OTP.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<RegisterResult> call({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _repository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
}

/// Flow 4 — gửi lại OTP.
class SendOtpUseCase {
  const SendOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) => _repository.sendOtp(email);
}

/// Flow 4 — verify OTP. Thành công là lúc phiên thật sự bắt đầu.
class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository, this._persist);

  final AuthRepository _repository;
  final PersistSessionUseCase _persist;

  Future<AuthSession> call({
    required String email,
    required String otp,
  }) async {
    final session = await _repository.verifyOtp(email: email, otp: otp);
    await _persist(session);
    return session;
  }
}

/// Flow 5 — đăng nhập email.
class EmailLoginUseCase {
  const EmailLoginUseCase(this._repository, this._persist);

  final AuthRepository _repository;
  final PersistSessionUseCase _persist;

  Future<AuthSession> call({
    required String email,
    required String password,
  }) async {
    final session = await _repository.loginWithEmail(
      email: email,
      password: password,
    );
    await _persist(session);
    return session;
  }
}

/// Flow 8 — join khi **chưa có JWT**. JWT trả về đã mang sẵn
/// `household_id`/`role` nên không cần refresh (S8.10).
class QrJoinUseCase {
  const QrJoinUseCase(this._repository, this._persist);

  final AuthRepository _repository;
  final PersistSessionUseCase _persist;

  Future<QrJoinResult> call({
    required String inviteCode,
    String? displayName,
  }) async {
    final result = await _repository.qrJoin(
      inviteCode: inviteCode,
      displayName: displayName,
    );
    await _persist(result.session);
    return result;
  }
}

/// Flow 9 — nâng cấp GUEST thành tài khoản email. Token mới được lưu ngay,
/// nhưng email chỉ được coi là đã xác minh sau bước OTP.
class UpgradeProfileUseCase {
  const UpgradeProfileUseCase(
    this._repository,
    this._tokenStorage,
    this._sessionStore,
  );

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final SessionStore _sessionStore;

  Future<UpgradeProfileResult> call({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final result = await _repository.upgradeProfile(
      email: email,
      password: password,
      fullName: fullName,
    );
    await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
    _sessionStore.applyRefreshedClaims(result.accessToken);
    return result;
  }
}
