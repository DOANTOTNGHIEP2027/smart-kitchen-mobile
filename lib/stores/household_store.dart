import 'package:mobx/mobx.dart';

import '../data/network/api_exception.dart';
import '../domain/auth/auth_usecases.dart';
import '../domain/household/household_models.dart';
import '../domain/household/household_usecases.dart';
import '../utils/error_mapper.dart';
import '../utils/validators.dart';
import 'session_store.dart';
import 'submission_state.dart';

part 'household_store.g.dart';

/// Endpoint join nào sẽ được gọi, theo **bảng định tuyến FE** của Flow 8.
/// Không được gộp ba nhánh lại — hai trong ba sẽ sai (guard §20).
enum JoinRoute {
  /// Chưa từng đăng nhập → `POST /auth/qr-join`.
  qrJoin,

  /// Đã đăng nhập, `household_id: null` → `POST /households/join`.
  householdJoin,

  /// Đã thuộc một household khác → **không gọi BE**, chặn ở client (S8.7).
  blocked,
}

/// State cho Flow 7 (tạo household) và Flow 8 (preview + join).
// ignore: library_private_types_in_public_api — mixin application chuẩn của MobX
class HouseholdStore = _HouseholdStore with _$HouseholdStore;

abstract class _HouseholdStore with Store {
  _HouseholdStore({
    required CreateHouseholdUseCase createHousehold,
    required PreviewInviteUseCase previewInvite,
    required JoinHouseholdUseCase joinHousehold,
    required QrJoinUseCase qrJoin,
    required SessionStore sessionStore,
  })  : _createHousehold = createHousehold,
        _previewInvite = previewInvite,
        _joinHousehold = joinHousehold,
        _qrJoin = qrJoin,
        _sessionStore = sessionStore;

  final CreateHouseholdUseCase _createHousehold;
  final PreviewInviteUseCase _previewInvite;
  final JoinHouseholdUseCase _joinHousehold;
  final QrJoinUseCase _qrJoin;
  final SessionStore _sessionStore;

  // ── Flow 7: tạo household ────────────────────────────────────────
  @observable
  SubmissionState createState = const SubmissionIdle();

  @observable
  String? createNameError;

  @observable
  HouseholdCreated? createdHousehold;

  // ── Flow 8: preview + join ───────────────────────────────────────
  @observable
  SubmissionState previewState = const SubmissionIdle();

  @observable
  InvitePreview? preview;

  @observable
  String? pendingCode;

  @observable
  SubmissionState joinState = const SubmissionIdle();

  /// `true` sau khi join bằng `/auth/qr-join` và BE báo cần hoàn tất profile —
  /// dùng để hiện banner **không chặn** ở Flow 9 (S8.10).
  @observable
  bool requiresProfileCompletion = false;

  /// Nhánh định tuyến join, tính từ state JWT hiện tại (Flow 8).
  @computed
  JoinRoute get joinRoute {
    if (!_sessionStore.isAuthenticated) return JoinRoute.qrJoin;
    if (_sessionStore.householdId == null) return JoinRoute.householdJoin;
    return JoinRoute.blocked; // S8.7 — đã thuộc household khác
  }

  /// Chỉ luồng QR-join (chưa có JWT) mới cho user tự đặt tên hiển thị — với
  /// luồng kia, user đã có `fullName` từ trước (S8.5, Guard G9).
  @computed
  bool get asksForDisplayName => joinRoute == JoinRoute.qrJoin;

  // ── Flow 7 ───────────────────────────────────────────────────────

  @action
  Future<bool> createHousehold(String name) async {
    if (!Validators.isValidHouseholdName(name)) {
      createNameError = 'householdNameRequired';
      createState = const SubmissionIdle();
      return false;
    }
    createNameError = null;
    createState = const SubmissionInProgress();
    try {
      createdHousehold = await _createHousehold(name.trim());
      createState = const SubmissionSuccess();
      return true;
    } catch (error) {
      // ERR_HH_003 (409) = race, user đã có household → S7.3, caller
      // re-resolve lại điều hướng household thay vì hiện lỗi tại chỗ.
      createState = SubmissionFailure(toApiException(error));
      return false;
    }
  }

  // ── Flow 8 ───────────────────────────────────────────────────────

  @action
  Future<bool> loadPreview(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!Validators.isValidInviteCode(normalized)) {
      previewState = SubmissionFailure(
        BusinessException('ERR_HH_002', 'Mã mời không hợp lệ'),
      );
      return false;
    }

    pendingCode = normalized;
    preview = null;
    previewState = const SubmissionInProgress();
    try {
      final result = await _previewInvite(normalized);
      preview = result;
      if (!result.isValid) {
        // `isValid: false` trong body 200 — vẫn là S8.6, không phải success.
        previewState = SubmissionFailure(
          BusinessException('ERR_HH_002', 'Mã mời đã hết hạn'),
        );
        return false;
      }
      previewState = const SubmissionSuccess();
      return true;
    } catch (error) {
      previewState = SubmissionFailure(toApiException(error));
      return false;
    }
  }

  @action
  Future<bool> confirmJoin({String? displayName}) async {
    final code = pendingCode;
    if (code == null) return false;

    final route = joinRoute;
    if (route == JoinRoute.blocked) return false; // S8.7 — không chạm BE

    joinState = const SubmissionInProgress();
    try {
      if (route == JoinRoute.qrJoin) {
        final result = await _qrJoin(
          inviteCode: code,
          displayName: displayName,
        );
        requiresProfileCompletion = result.requiresProfileCompletion;
      } else {
        await _joinHousehold(code);
      }
      joinState = const SubmissionSuccess();
      return true;
    } catch (error) {
      // ERR_HH_005 / ERR_AUTH_INVITE_INVALID / ERR_HH_003 → S8.9 (race)
      joinState = SubmissionFailure(toApiException(error));
      return false;
    }
  }

  @action
  void resetJoin() {
    preview = null;
    pendingCode = null;
    previewState = const SubmissionIdle();
    joinState = const SubmissionIdle();
  }

  /// Xoá sạch state của phiên onboarding.
  ///
  /// Quan trọng nhất là [createdHousehold]: màn tạo Nhà chuyển sang màn thành
  /// công chỉ dựa vào việc field này khác null, nên nếu không dọn, user kế
  /// tiếp sẽ thấy mã mời của Nhà user trước và không bao giờ render được form.
  @action
  void reset() {
    resetJoin();
    createState = const SubmissionIdle();
    createNameError = null;
    createdHousehold = null;
    requiresProfileCompletion = false;
  }
}
