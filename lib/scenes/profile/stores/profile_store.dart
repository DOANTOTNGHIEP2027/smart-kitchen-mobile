import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/db/read_cache_dao.dart';
import '../../../data/network/api_exception.dart';
import '../../../domain/auth/user_summary.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../api/health_api.dart';
import '../api/profile_api.dart';
import '../domain/allergen.dart';
import '../domain/health_profile.dart';
import 'form_status.dart';
import 'store_error.dart';

/// State + actions cho ProfileScreen + EditProfileScreen + HealthProfileScreen
/// + AllergenSelectScreen. Bám pattern thủ công hiện có (Observable + runInAction)
/// — không codegen.
class ProfileStore {
  ProfileStore(this._healthApi, this._profileApi, this._cache, this._session);

  final HealthApi _healthApi;
  final ProfileApi _profileApi;
  final ReadCacheDao _cache;
  final SessionStore _session;

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
  final Observable<FormStatus> _editProfileStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _mutationError =
      Observable<ApiException?>(null);

  ViewState<HealthProfile> get healthProfileState => _healthProfileState.value;
  bool get healthProfileIsFromCache => _healthProfileIsFromCache.value;
  ViewState<List<Allergen>> get allergenCatalogState =>
      _allergenCatalogState.value;
  FormStatus get healthSaveStatus => _healthSaveStatus.value;
  FormStatus get allergensSaveStatus => _allergensSaveStatus.value;
  FormStatus get editProfileStatus => _editProfileStatus.value;
  ApiException? get mutationError => _mutationError.value;

  UserSummary? get currentUser => _session.currentUser;

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
      unawaited(
          _cache.put(_healthProfileCacheKey, profile.toJson()));
    } catch (raw) {
      final cached = await _cache.get(_healthProfileCacheKey);
      if (cached != null) {
        runInAction(() {
          _healthProfileState.value =
              SuccessState<HealthProfile>(HealthProfile.fromJson(cached.payload));
          _healthProfileIsFromCache.value = true;
        });
      } else {
        runInAction(() => _healthProfileState.value =
            ErrorState<HealthProfile>(storeApiException(raw)));
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
        'items': catalog.map((Allergen a) => a.toJson()).toList(growable: false),
      }));
    } catch (raw) {
      final cached = await _cache.get(_allergenCatalogCacheKey);
      if (cached != null) {
        runInAction(() {
          _allergenCatalogState.value = SuccessState<List<Allergen>>(
            (cached.payload['items'] as List<dynamic>)
                .map((Object? e) =>
                    Allergen.fromJson(e as Map<String, dynamic>))
                .toList(growable: false),
          );
        });
      } else {
        runInAction(() => _allergenCatalogState.value =
            ErrorState<List<Allergen>>(storeApiException(raw)));
      }
    }
  }

  Future<bool> saveHealthProfile({
    int? targetDailyCalories,
    String? dietTypeWire,
    double? heightCm,
    double? weightKg,
  }) async {
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
  Future<bool> saveAllergens(List<int> allergenIds) async {
    if (_allergensSaveStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _allergensSaveStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      final updated = await _healthApi.updateMyAllergens(allergenIds);
      final current = _healthProfileState.value;
      if (current is SuccessState<HealthProfile>) {
        final patched = current.data.copyWith(allergens: updated);
        runInAction(() {
          _healthProfileState.value = SuccessState<HealthProfile>(patched);
          _healthProfileIsFromCache.value = false;
          _allergensSaveStatus.value = FormStatus.success;
        });
        unawaited(_cache.put(_healthProfileCacheKey, patched.toJson()));
      } else {
        runInAction(() => _allergensSaveStatus.value = FormStatus.success);
      }
      return true;
    } catch (raw) {
      _failMutation(raw, _allergensSaveStatus);
      return false;
    }
  }

  /// ⚠️ BLOCKED trong production (Guard 1). Viết đầy đủ để test với mock.
  Future<bool> saveProfile({required String fullName}) async {
    if (_editProfileStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _editProfileStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      final updated = await _profileApi.updateMe(fullName: fullName);
      _session.currentUser = updated;
      runInAction(() => _editProfileStatus.value = FormStatus.success);
      return true;
    } catch (raw) {
      _failMutation(raw, _editProfileStatus);
      return false;
    }
  }

  void clearHealthSaveError() =>
      runInAction(() => _healthSaveStatus.value = FormStatus.idle);
  void clearAllergensSaveError() =>
      runInAction(() => _allergensSaveStatus.value = FormStatus.idle);
  void clearEditProfileError() =>
      runInAction(() => _editProfileStatus.value = FormStatus.idle);

  void _failMutation(Object raw, Observable<FormStatus> target) {
    final exception = storeApiException(raw);
    runInAction(() {
      _mutationError.value = exception;
      target.value = FormStatus.failure;
    });
  }
}
