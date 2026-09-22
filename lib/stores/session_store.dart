import 'package:mobx/mobx.dart';

import '../data/auth/jwt_claims.dart';
import '../data/auth/token_storage.dart';
import '../domain/auth/auth_refresh_usecase.dart';
import '../domain/auth/auth_revoke_usecase.dart';
import '../domain/auth/user_summary.dart';

part 'session_store.g.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// State auth/session ở cấp toàn app (fe-app-shell.md §4).
/// Đăng ký một lần bằng `Get.put(..., permanent: true)` trong `bootstrap()`.
// ignore: library_private_types_in_public_api — mixin application chuẩn của MobX
class SessionStore = _SessionStore with _$SessionStore;

abstract class _SessionStore with Store {
  _SessionStore(this._tokenStorage, this._refreshUseCase,
      {AuthRevokeUseCase? revokeUseCase})
      : _revokeUseCase = revokeUseCase;

  final TokenStorage _tokenStorage;
  final AuthRefreshUseCase _refreshUseCase;

  /// Tuỳ chọn — chỉ `bootstrap()` truyền vào. Test/guard-boot cũ dựng store
  /// không có use case này; khi đó [logout] chỉ xoá token cục bộ (không gọi BE).
  final AuthRevokeUseCase? _revokeUseCase;

  @observable
  AuthStatus status = AuthStatus.unknown;

  @observable
  UserSummary? currentUser;

  // Ba field dưới được decode từ payload JWT của access token hiện tại (claim
  // `household_id`, `role`, `provider`). Không response body nào mang trực
  // tiếp chúng, nên JWT là nguồn duy nhất.
  //
  // Đây là gợi ý routing/UX phía client, CHỈ ĐỌC — KHÔNG BAO GIỜ được dùng làm
  // quyết định phân quyền. BE re-validate token đã ký trên mọi request.
  @observable
  String? householdId;

  @observable
  String? role;

  @observable
  String? provider;

  @computed
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// `true` khi user đã đăng nhập nhưng chưa thuộc Nhà nào — `fe-onboarding`
  /// dùng để route sang luồng tạo/join household.
  @computed
  bool get needsHousehold => isAuthenticated && householdId == null;

  /// KHÔNG BAO GIỜ được phép throw. `bootstrap()` ở `app/bootstrap.dart` await
  /// hàm này *trước* `runApp()`, nên một exception thoát ra đây đồng nghĩa app
  /// không bao giờ vẽ frame nào — màn hình trắng, không log, người dùng chỉ
  /// thoát được bằng cách xoá app data.
  ///
  /// Vì vậy catch trần là có chủ đích, không phải cẩu thả: ngoài
  /// `DioException`, đường này còn có thể ném `TypeError`/`FormatException` từ
  /// các cast trong `ApiResponse.fromJson`/`AuthRefreshResult` khi BE trả body
  /// lệch shape, và `PlatformException` từ secure storage (đặc biệt trên web).
  /// Mọi kiểu lỗi đều quy về cùng một kết luận an toàn: coi như chưa đăng nhập.
  @action
  Future<void> bootstrap() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        status = AuthStatus.unauthenticated;
        return;
      }
      final result = await _refreshUseCase.call(refreshToken);
      await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
      final claims = _applyClaimsFromAccessToken(result.accessToken);
      currentUser = await _restoreUser() ?? _userFromClaims(claims);
      status = AuthStatus.authenticated;
    } catch (_) {
      // Catch trần là bắt buộc, không phải `on Exception`: các cast lỗi ném
      // `TypeError`, vốn là `Error` chứ không phải `Exception`.
      await _clearTokensQuietly();
      status = AuthStatus.unauthenticated;
    }
  }

  /// Đọc lại `UserSummary` đã lưu từ phiên trước. BE không có `GET /users/me`,
  /// nên đây là cách duy nhất để `currentUser` không null sau cold start (nếu
  /// null, `ProfileScreen` sẽ hiện màn lỗi dù đã đăng nhập).
  Future<UserSummary?> _restoreUser() async {
    try {
      final json = await _tokenStorage.readUser();
      return json == null ? null : UserSummary.fromJson(json);
    } catch (_) {
      // Hồ sơ hỏng không được phép làm mất phiên đăng nhập.
      return null;
    }
  }

  /// Xoá token mà không để lỗi storage lan ra ngoài — nếu chính secure storage
  /// là thứ đang hỏng thì `clear()` cũng sẽ ném, và app vẫn phải boot được.
  Future<void> _clearTokensQuietly() async {
    try {
      await _tokenStorage.clear();
    } catch (_) {
      // Không còn gì để làm; access token vốn chỉ nằm in-memory.
    }
  }

  @action
  Future<void> setSession({
    required String accessToken,
    required String refreshToken,
    required UserSummary user,
  }) async {
    await _tokenStorage.saveTokens(accessToken, refreshToken);
    await _tokenStorage.saveUser(user.toJson());
    currentUser = user;
    _applyClaimsFromAccessToken(accessToken);
    status = AuthStatus.authenticated;
  }

  /// Thay token sau một mutation auth (ví dụ nâng cấp guest). User và claim
  /// hiện có được giữ lại cho tới khi endpoint OTP/refresh trả session mới.
  @action
  Future<void> replaceTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _tokenStorage.saveTokens(accessToken, refreshToken);
    _applyClaimsFromAccessToken(accessToken);
    status = AuthStatus.authenticated;
  }

  /// Refresh tường minh để đồng bộ claim household sau create/join.
  @action
  Future<void> refreshSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) throw StateError('No refresh token');
    final result = await _refreshUseCase.call(refreshToken);
    await _tokenStorage.saveTokens(result.accessToken, result.refreshToken);
    _applyClaimsFromAccessToken(result.accessToken);
    status = AuthStatus.authenticated;
  }

  /// Áp dụng context trả trực tiếp từ API khi không cần refresh JWT.
  @action
  void applyHouseholdContext({required String householdId, required String role}) {
    this.householdId = householdId;
    this.role = role;
  }

  /// Được [TokenRefreshInterceptor] gọi sau mỗi lần silent refresh thành công,
  /// để thay đổi claim chỉ xảy ra qua refresh (ví dụ `household_id` chuyển từ
  /// null sang có giá trị sau khi join Nhà) được phản ánh mà không cần gọi lại
  /// [setSession].
  @action
  void applyRefreshedClaims(String accessToken) =>
      _applyClaimsFromAccessToken(accessToken);

  Map<String, dynamic> _applyClaimsFromAccessToken(String accessToken) {
    final claims = decodeJwtPayload(accessToken);
    householdId = claims['household_id'] as String?;
    role = claims['role'] as String?;
    provider = claims['provider'] as String?;
    return claims;
  }

  /// Người dùng đang đăng nhập luôn phải có một `UserSummary`, kể cả khi
  /// storage chưa có hồ sơ (phiên tạo bởi bản cũ) — nếu null, `ProfileScreen`
  /// sẽ hiện màn lỗi. JWT chỉ có `sub`, nên đây là danh tính tối thiểu; hồ sơ
  /// đầy đủ (tên/email) được ghi lại ở lần đăng nhập kế tiếp.
  UserSummary? _userFromClaims(Map<String, dynamic> claims) {
    final sub = claims['sub'];
    return sub is String && sub.isNotEmpty ? UserSummary(id: sub) : null;
  }

  @action
  Future<void> clear() async {
    await _tokenStorage.clear();
    currentUser = null;
    householdId = null;
    role = null;
    provider = null;
    status = AuthStatus.unauthenticated;
  }

  /// Đăng xuất: thu hồi refresh token phía BE (best-effort) rồi xoá sạch phiên
  /// cục bộ.
  ///
  /// Thu hồi ở BE là **best-effort có chủ đích**: mất mạng/token đã hết hạn
  /// KHÔNG được chặn người dùng thoát khỏi app. Token cục bộ luôn bị xoá, kể cả
  /// khi call revoke thất bại — nếu không, logout hỏng mạng sẽ để lại refresh
  /// token còn dùng được trong secure storage (đúng vector mà `revoke` sinh ra
  /// để bịt).
  ///
  /// [allDevices] = true gọi `revoke-all` (mọi thiết bị); mặc định chỉ thu hồi
  /// refresh token hiện tại. Khi store được dựng không kèm [AuthRevokeUseCase]
  /// (test/bootstrap tối giản), bỏ qua bước gọi BE.
  @action
  Future<void> logout({bool allDevices = false}) async {
    try {
      await _revokeRemote(allDevices: allDevices);
    } catch (_) {
      // Cố ý nuốt: logout phải thành công ở phía client bất kể BE.
    } finally {
      await clear();
    }
  }

  Future<void> _revokeRemote({required bool allDevices}) async {
    final revoke = _revokeUseCase;
    if (revoke == null) return;
    if (allDevices) {
      await revoke.revokeAll();
      return;
    }
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) await revoke.revoke(refreshToken);
  }
}
