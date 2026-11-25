import 'dart:async';
import 'dart:typed_data';

import 'package:mobx/mobx.dart';

import '../../../data/db/read_cache_dao.dart';
import '../../../data/network/api_exception.dart';
import '../../../domain/auth/user_summary.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../api/avatar_image_processor.dart';
import '../api/health_api.dart';
import '../api/profile_api.dart';
import '../domain/allergen.dart';
import '../domain/edit_profile_phase.dart';
import '../domain/health_profile.dart';
import 'form_status.dart';
import 'store_error.dart';

/// State + actions cho ProfileScreen + EditProfileScreen + HealthProfileScreen
/// + AllergenSelectScreen. Bám pattern thủ công hiện có (Observable + runInAction)
/// — không codegen.
class ProfileStore {
  ProfileStore(this._healthApi, this._profileApi, this._cache, this._session,
      [AvatarImageProcessor? avatarProcessor])
      : _avatarProcessor =
            avatarProcessor ?? const FlutterAvatarImageProcessor();

  final HealthApi _healthApi;
  final ProfileApi _profileApi;
  final ReadCacheDao _cache;
  final SessionStore _session;
  final AvatarImageProcessor _avatarProcessor;

  final Observable<ViewState<HealthProfile>> _healthProfileState =
      Observable<ViewState<HealthProfile>>(const LoadingState<HealthProfile>());
  final Observable<bool> _healthProfileIsFromCache = Observable<bool>(false);
  final Observable<ViewState<List<Allergen>>> _allergenCatalogState =
      Observable<ViewState<List<Allergen>>>(
          const LoadingState<List<Allergen>>());
  final Observable<FormStatus> _healthSaveStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<FormStatus> _allergensSaveStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<EditProfilePhase> _editProfilePhase =
      Observable<EditProfilePhase>(const EditIdle());
  final Observable<String?> _pendingAvatarUrl = Observable<String?>(null);

  /// Thế hệ phiên sửa hồ sơ — KHÔNG reactive (chỉ dùng so sánh trong store).
  int _editSessionSeq = 0;
  final Observable<ApiException?> _mutationError =
      Observable<ApiException?>(null);

  ViewState<HealthProfile> get healthProfileState => _healthProfileState.value;
  bool get healthProfileIsFromCache => _healthProfileIsFromCache.value;
  ViewState<List<Allergen>> get allergenCatalogState =>
      _allergenCatalogState.value;
  FormStatus get healthSaveStatus => _healthSaveStatus.value;
  FormStatus get allergensSaveStatus => _allergensSaveStatus.value;

  /// Luồng 2 bước của EditProfileScreen (D11, §10.2).
  EditProfilePhase get editProfilePhase => _editProfilePhase.value;

  /// URL avatar đã upload thành công nhưng PUT chưa thành công. Còn giá trị ⇒
  /// "Thử lại" KHÔNG upload lại (Guard 1). Bị xoá khi PUT thành công, user
  /// chọn ảnh khác, hoặc rời màn ([discardEditSession]).
  String? get pendingAvatarUrl => _pendingAvatarUrl.value;
  ApiException? get mutationError => _mutationError.value;

  UserSummary? get currentUser => _session.currentUser;

  /// Điều kiện DUY NHẤT để được ghi allergens (Guard 12, invariant I-ALG):
  /// health đã tải THÀNH CÔNG từ server (không phải cache, không phải
  /// loading/lỗi). API là full-replace — `[]` từ trạng thái chưa biết = xoá
  /// sạch dị ứng. UI disable nút Lưu theo getter này; [saveAllergens] tự kiểm
  /// lại (phòng thủ 2 lớp).
  bool get canSaveAllergens =>
      healthProfileState is SuccessState<HealthProfile> &&
      !healthProfileIsFromCache;

  /// Cùng điều kiện cho [saveHealthProfile] (Guard 13 — dữ liệu cache chỉ đọc).
  bool get canEditHealth => canSaveAllergens;

  String get _healthProfileCacheKey =>
      'health_profile:${_session.currentUser?.id}';
  static const String _allergenCatalogCacheKey = 'allergen_catalog';

  Future<void> loadHealthProfile() async {
    runInAction(() {
      _healthProfileState.value = const LoadingState<HealthProfile>();
      _healthProfileIsFromCache.value = false;
    });
    try {
      final profile = await _healthApi.getMyHealthProfile();
      runInAction(() {
        _healthProfileState.value = SuccessState<HealthProfile>(profile);
        _healthProfileIsFromCache.value = false;
      });
      unawaited(_cache.put(_healthProfileCacheKey, profile.toJson()));
    } catch (raw) {
      final error = storeApiException(raw);
      // Chỉ lỗi mạng mới rơi về cache; 5xx/lỗi khác → ErrorState (§8).
      final cached = error is NetworkException
          ? await _cache.get(_healthProfileCacheKey)
          : null;
      if (cached != null) {
        runInAction(() {
          _healthProfileState.value = SuccessState<HealthProfile>(
              HealthProfile.fromJson(cached.payload));
          _healthProfileIsFromCache.value = true;
        });
      } else {
        runInAction(
            () => _healthProfileState.value = ErrorState<HealthProfile>(error));
      }
    }
  }

  Future<void> loadAllergenCatalog() async {
    runInAction(() =>
        _allergenCatalogState.value = const LoadingState<List<Allergen>>());
    try {
      final catalog = await _healthApi.getAllergenCatalog();
      runInAction(() =>
          _allergenCatalogState.value = SuccessState<List<Allergen>>(catalog));
      unawaited(_cache.put(_allergenCatalogCacheKey, <String, dynamic>{
        'items':
            catalog.map((Allergen a) => a.toJson()).toList(growable: false),
      }));
    } catch (raw) {
      final error = storeApiException(raw);
      final cached = error is NetworkException
          ? await _cache.get(_allergenCatalogCacheKey)
          : null;
      if (cached != null) {
        runInAction(() {
          _allergenCatalogState.value = SuccessState<List<Allergen>>(
            (cached.payload['items'] as List<dynamic>)
                .map(
                    (Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
                .toList(growable: false),
          );
        });
      } else {
        runInAction(() =>
            _allergenCatalogState.value = ErrorState<List<Allergen>>(error));
      }
    }
  }

  /// Luôn gửi đủ 4 field, kể cả `null` tường minh (Guard 9 — `PUT {}` = reset
  /// toàn bộ). `targetDailyCalories` do UI tính bằng
  /// `CalorieTarget.resolveForSave` (Guard 14) — Store không tự kẹp giá trị.
  Future<bool> saveHealthProfile({
    int? targetDailyCalories,
    String? dietTypeWire,
    double? heightCm,
    double? weightKg,
  }) async {
    // Guard 13 — không ghi đè server bằng dữ liệu cache/chưa biết.
    if (!canEditHealth) return false;
    if (_healthSaveStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _healthSaveStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      final updated = await _healthApi.updateMyHealthProfile(<String, dynamic>{
        'targetDailyCalories': targetDailyCalories,
        'dietType': dietTypeWire,
        'heightCm': heightCm,
        'weightKg': weightKg,
      });
      runInAction(() {
        _healthProfileState.value = SuccessState<HealthProfile>(updated);
        _healthProfileIsFromCache.value = false;
        _healthSaveStatus.value = FormStatus.success;
      });
      unawaited(_cache.put(_healthProfileCacheKey, updated.toJson()));
      return true;
    } catch (raw) {
      _failMutation(raw, _healthSaveStatus);
      return false;
    }
  }

  /// Full-replace + patch `healthProfileState` tại chỗ (Fix HIGH-1 — regression
  /// test phải verify patch này, không cần load lại).
  /// CHỈ gọi API khi [canSaveAllergens] (Guard 12) — mọi trạng thái khác trả
  /// `false`, KHÔNG gọi API.
  Future<bool> saveAllergens(List<int> allergenIds) async {
    final current = _healthProfileState.value;
    if (!canSaveAllergens || current is! SuccessState<HealthProfile>) {
      return false;
    }
    if (_allergensSaveStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _allergensSaveStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      final updated = await _healthApi.updateMyAllergens(allergenIds);
      // Vá vào bản MỚI NHẤT (có thể đã đổi trong lúc chờ), fallback snapshot.
      final latest = _healthProfileState.value;
      final base =
          latest is SuccessState<HealthProfile> ? latest.data : current.data;
      final patched = base.copyWith(allergens: updated);
      runInAction(() {
        _healthProfileState.value = SuccessState<HealthProfile>(patched);
        // KHÔNG đụng healthProfileIsFromCache: nhánh cache đã bị chặn ở đầu
        // hàm; gỡ cờ ở đây sẽ xoá nhãn "cũ" khỏi các field vẫn cũ.
        _allergensSaveStatus.value = FormStatus.success;
      });
      unawaited(_cache.put(_healthProfileCacheKey, patched.toJson()));
      return true;
    } catch (raw) {
      _failMutation(raw, _allergensSaveStatus);
      return false;
    }
  }

  /// Luồng 2 bước (D11): [nén + upload ảnh nếu có ảnh mới và CHƯA có
  /// [pendingAvatarUrl]] → `PUT /users/me` → `SessionStore.updateCurrentUser`.
  /// - [newFullName]: `null` nếu tên không đổi; được trim trước khi gửi.
  /// - [rawAvatar]: bytes ảnh vừa chọn (chưa nén), `null` nếu không đổi ảnh.
  /// "Thử lại" sau [EditSaveError] gọi lại đúng hàm này với cùng tham số: vì
  /// [pendingAvatarUrl] còn giữ, bước upload bị bỏ qua — chỉ PUT (Guard 1).
  ///
  /// Rời màn giữa chừng ([discardEditSession]) tăng [_editSessionSeq]: luồng
  /// cũ dừng ở `await` kế tiếp, KHÔNG ghi phase/[pendingAvatarUrl] và KHÔNG
  /// gọi PUT với ảnh đã bị bỏ (review #29 M2).
  Future<bool> saveProfile({String? newFullName, Uint8List? rawAvatar}) async {
    final phase = _editProfilePhase.value;
    if (phase is EditUploading || phase is EditSaving) return false;
    final seq = _editSessionSeq;
    bool abandoned() => seq != _editSessionSeq;
    final fullName = newFullName?.trim();
    // Phòng thủ lớp 2 — UI đã chặn (Guard 15).
    if (fullName != null && validateFullName(fullName) != null) return false;
    if (fullName == null && rawAvatar == null && pendingAvatarUrl == null) {
      return false;
    }

    if (rawAvatar != null && pendingAvatarUrl == null) {
      runInAction(() => _editProfilePhase.value = const EditUploading());
      try {
        final jpeg = await _avatarProcessor.process(rawAvatar);
        if (abandoned()) return false;
        final uploaded = await _profileApi.uploadAvatar(jpeg);
        // File đã upload thành mồ côi trên storage — chấp nhận (như discard).
        if (abandoned()) return false;
        runInAction(() => _pendingAvatarUrl.value = uploaded.url);
      } on AvatarImageException catch (e) {
        if (abandoned()) return false;
        // Lỗi phía client — không gọi API (E7).
        runInAction(() => _editProfilePhase.value = EditUploadError(e.code));
        return false;
      } catch (raw) {
        if (abandoned()) return false;
        final code = storeApiException(raw).code;
        runInAction(() => _editProfilePhase.value = EditUploadError(code));
        return false;
      }
    }

    runInAction(() => _editProfilePhase.value = const EditSaving());
    try {
      final updated = await _profileApi.updateMe(
        fullName: fullName,
        avatarUrl: pendingAvatarUrl,
      );
      // PUT đã tới BE → vẫn đồng bộ SessionStore cho khớp dữ liệu thật, nhưng
      // luồng đã bị bỏ thì không ghi phase của màn (có thể là màn mới).
      try {
        await _session.updateCurrentUser(updated); // Guard 2 — BẮT BUỘC
      } catch (_) {
        // BE đã lưu; lỗi secure storage không được biến thành "lưu thất bại".
        // Vẫn phản ánh in-memory để ProfileScreen không hiện dữ liệu cũ.
        runInAction(() => _session.currentUser = updated);
      }
      if (abandoned()) return false;
      runInAction(() {
        _pendingAvatarUrl.value = null;
        _editProfilePhase.value = const EditSuccess();
      });
      return true;
    } catch (raw) {
      if (abandoned()) return false;
      final error = storeApiException(raw);
      // pendingAvatarUrl GIỮ NGUYÊN → retry chỉ PUT.
      runInAction(() => _editProfilePhase.value = EditSaveError(error));
      return false;
    }
  }

  /// User chọn ảnh khác sau khi upload trước đó đã xong (PUT lỗi) → bỏ URL
  /// cũ, lần lưu sau upload ảnh mới.
  void onAvatarRepicked() => runInAction(() {
        _pendingAvatarUrl.value = null;
        _editProfilePhase.value = const EditIdle();
      });

  /// Rời EditProfileScreen — file đã upload thành mồ côi trên storage: chấp
  /// nhận (BE không có API xoá).
  /// Tăng [_editSessionSeq] để vô hiệu luồng [saveProfile] còn đang chạy.
  void discardEditSession() => runInAction(() {
        _editSessionSeq++;
        _pendingAvatarUrl.value = null;
        _editProfilePhase.value = const EditIdle();
        _mutationError.value = null;
      });

  // `mutationError` dùng chung giữa các mutation và HealthProfileScreen đọc
  // thẳng nó → mọi clear*Error phải xoá cả nó, nếu không lỗi cũ hiện lại ở
  // lần mở màn sau.
  void clearHealthSaveError() => runInAction(() {
        _healthSaveStatus.value = FormStatus.idle;
        _mutationError.value = null;
      });
  void clearAllergensSaveError() => runInAction(() {
        _allergensSaveStatus.value = FormStatus.idle;
        _mutationError.value = null;
      });

  /// Xoá banner lỗi E7/E8. `pendingAvatarUrl` KHÔNG bị xoá ở đây.
  void clearEditProfileError() => runInAction(() {
        final phase = _editProfilePhase.value;
        if (phase is EditUploadError || phase is EditSaveError) {
          _editProfilePhase.value = const EditIdle();
        }
        _mutationError.value = null;
      });

  void _failMutation(Object raw, Observable<FormStatus> target) {
    final exception = storeApiException(raw);
    runInAction(() {
      _mutationError.value = exception;
      target.value = FormStatus.failure;
    });
  }
}
