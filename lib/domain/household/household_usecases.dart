import '../../data/auth/token_storage.dart';
import '../../data/household/household_repository.dart';
import '../../stores/session_store.dart';
import '../auth/auth_refresh_usecase.dart';
import 'household_models.dart';

/// Flow 7 — tạo household.
class CreateHouseholdUseCase {
  const CreateHouseholdUseCase(this._repository, this._refreshClaims);

  final HouseholdRepository _repository;
  final RefreshSessionClaimsUseCase _refreshClaims;

  Future<HouseholdCreated> call(String name) async {
    final created = await _repository.create(name: name);
    // JWT hiện tại vẫn mang `household_id: null`; phải refresh để guard và
    // mọi request sau đó nhìn thấy household mới (cùng lý do với S8.11).
    await _refreshClaims();
    return created;
  }
}

/// Flow 8 — preview mã mời. Public, không cần JWT.
class PreviewInviteUseCase {
  const PreviewInviteUseCase(this._repository);

  final HouseholdRepository _repository;

  Future<InvitePreview> call(String code) => _repository.previewInvite(code);
}

/// Flow 8 — join khi **đã có JWT nhưng chưa có household** (S8.11).
///
/// `requiresTokenRefresh` gần như luôn `true`; refresh chạy âm thầm, user
/// không thấy bước nào.
class JoinHouseholdUseCase {
  const JoinHouseholdUseCase(this._repository, this._refreshClaims);

  final HouseholdRepository _repository;
  final RefreshSessionClaimsUseCase _refreshClaims;

  Future<JoinHouseholdResult> call(String code) async {
    final result = await _repository.join(code);
    if (result.requiresTokenRefresh) {
      await _refreshClaims();
    }
    return result;
  }
}

/// Gọi `POST /auth/refresh` rồi đồng bộ token mới + claim vào session.
///
/// Tách riêng vì cả tạo household lẫn join đều cần đúng chuỗi này: BE đổi
/// `household_id` ở phía server, nhưng JWT đang giữ trong máy vẫn là bản cũ
/// cho tới khi refresh.
class RefreshSessionClaimsUseCase {
  const RefreshSessionClaimsUseCase(
    this._refreshUseCase,
    this._tokenStorage,
    this._sessionStore,
  );

  final AuthRefreshUseCase _refreshUseCase;
  final TokenStorage _tokenStorage;
  final SessionStore _sessionStore;

  Future<void> call() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return;
    final result = await _refreshUseCase.call(refreshToken);
    await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
    _sessionStore.applyRefreshedClaims(result.accessToken);
  }
}
