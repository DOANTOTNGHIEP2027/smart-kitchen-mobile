import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/db/read_cache_dao.dart';
import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../api/dependent_api.dart';
import '../api/health_api.dart';
import '../domain/allergen.dart';
import '../domain/dependent_health_profile.dart';
import '../domain/dependent_summary.dart';
import '../domain/household_member.dart';
import '../domain/household_roster.dart';
import 'family_store.dart';
import 'form_status.dart';
import 'store_error.dart';

/// State hồ sơ phụ thuộc (dependent-profile-screens.md §16.5) — MobX thủ
/// công giống [FamilyStore]. Dùng chung cho card trong FamilyScreen và 4 route
/// `/dependents/**`.
///
/// Role/currentUserId/roster đọc DUY NHẤT từ [FamilyStore] (Guard 3) — không
/// tự decode `SessionStore.role`. [SessionStore] chỉ dùng cho cache key.
class DependentStore {
  DependentStore(
      this._api, this._healthApi, this._family, this._cache, this._session);

  final DependentApi _api;
  final HealthApi _healthApi; // CHỈ getAllergenCatalog()
  final FamilyStore _family;
  final ReadCacheDao _cache;
  final SessionStore _session;

  final Observable<ViewState<List<DependentSummary>>> _listState =
      Observable<ViewState<List<DependentSummary>>>(
          const LoadingState<List<DependentSummary>>());
  final Observable<bool> _listFromCache = Observable<bool>(false);

  /// KHÔNG cache (D5) — luôn fetch mới khi mở chi tiết.
  final Observable<ViewState<DependentSummary>> _detailState =
      Observable<ViewState<DependentSummary>>(
          const LoadingState<DependentSummary>());
  final Observable<ViewState<DependentHealthProfile>> _healthState =
      Observable<ViewState<DependentHealthProfile>>(
          const LoadingState<DependentHealthProfile>());
  final Observable<ViewState<List<Allergen>>> _catalogState =
      Observable<ViewState<List<Allergen>>>(
          const LoadingState<List<Allergen>>());

  // Một cặp status/error RIÊNG cho mỗi mutation — lỗi sheet này không lộ
  // sang màn khác.
  final Observable<FormStatus> _createStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _createError =
      Observable<ApiException?>(null);
  final Observable<FormStatus> _deleteStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _deleteError =
      Observable<ApiException?>(null);
  final Observable<FormStatus> _guardianStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _guardianError =
      Observable<ApiException?>(null);
  final Observable<FormStatus> _healthSaveStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _healthSaveError =
      Observable<ApiException?>(null);
  final Observable<FormStatus> _allergensSaveStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _allergensSaveError =
      Observable<ApiException?>(null);

  /// Id đang mở ở detail/health/allergens — KHÔNG reactive.
  String? _detailId;

  /// Response cũ (đã rời sang dependent khác) không được ghi đè.
  int _detailSeq = 0;
  int _healthSeq = 0;

  /// L2 (review #125): lần nạp list cũ về sau không ghi đè list/cache mới.
  int _listSeq = 0;

  /// Id dependent đang có `GET .../health-profile` bay — chống gọi trùng (L3).
  String? _healthInFlightId;
  Future<void>? _healthFuture;

  ViewState<List<DependentSummary>> get listState => _listState.value;
  bool get listFromCache => _listFromCache.value;
  ViewState<DependentSummary> get detailState => _detailState.value;
  ViewState<DependentHealthProfile> get healthState => _healthState.value;
  ViewState<List<Allergen>> get catalogState => _catalogState.value;
  FormStatus get createStatus => _createStatus.value;
  ApiException? get createError => _createError.value;
  FormStatus get deleteStatus => _deleteStatus.value;
  ApiException? get deleteError => _deleteError.value;
  FormStatus get guardianStatus => _guardianStatus.value;
  ApiException? get guardianError => _guardianError.value;
  FormStatus get healthSaveStatus => _healthSaveStatus.value;
  ApiException? get healthSaveError => _healthSaveError.value;
  FormStatus get allergensSaveStatus => _allergensSaveStatus.value;
  ApiException? get allergensSaveError => _allergensSaveError.value;

  // ── Ma trận quyền (§16.6) ─────────────────────────────────────────

  bool get isOwner => _family.isOwner;
  bool get isRemoteViewer => _family.isRemoteViewer;
  String? get currentUserId => _family.currentUserId;

  /// Thấy nút "+ Thêm" (403 ERR_DEP_003 là backstop BE).
  bool get canManageDependents => !isRemoteViewer;

  /// List từ cache = chỉ đọc (mirror Guard 13 #29).
  bool get canAdd => canManageDependents && !_listFromCache.value;

  /// Đổi guardian + xoá — OWNER only (Guard 10, 403 ERR_DEP_006).
  bool get canAdminister => isOwner;

  /// PHẢI gồm cả `guardianActive` lẫn `!isRemoteViewer` (Guard 1, 14).
  bool canEditHealthOf(DependentSummary d) =>
      isOwner ||
      (!isRemoteViewer &&
          d.guardianActive &&
          d.guardianUserId == _family.currentUserId);

  /// Full-replace an toàn: chỉ ghi khi health của ĐÚNG dependent này đã tải
  /// thành công từ server, và quyền (tính trên detail đang mở) vẫn còn.
  bool canSaveAllergensFor(String id) {
    final h = _healthState.value;
    final d = detailFor(id);
    return d != null &&
        canEditHealthOf(d) &&
        h is SuccessState<DependentHealthProfile> &&
        h.data.dependentId == id;
  }

  /// [v1.2 review-125] HIGH-1: thêm điều kiện "không có dietType lạ" — PUT
  /// health gửi đủ 4 key, seed `null` rồi lưu = xoá chế độ ăn thật (Guard 19).
  bool canSaveHealthFor(String id) {
    final h = _healthState.value;
    return canSaveAllergensFor(id) &&
        !(h is SuccessState<DependentHealthProfile> && h.data.hasUnknownDiet);
  }

  /// Detail đang `SuccessState` cho đúng [id] — `null` nếu chưa.
  DependentSummary? detailFor(String id) {
    final d = _detailState.value;
    return d is SuccessState<DependentSummary> && d.data.id == id
        ? d.data
        : null;
  }

  bool isDetailLoadedFor(String id) => detailFor(id) != null;

  /// Tra guardian trong roster — KHÔNG `.firstWhere` thiếu `orElse` (Guard 18).
  HouseholdMember? guardianOf(DependentSummary d) {
    final r = _family.rosterState;
    if (r is! SuccessState<HouseholdRoster>) return null;
    return r.data.members.where((m) => m.userId == d.guardianUserId).firstOrNull;
  }

  /// Candidate guardian mới (§16.6): chỉ OWNER/MEMBER; loại guardian hiện tại
  /// khi họ còn active. Roster chưa tải → rỗng.
  List<HouseholdMember> guardianCandidates(DependentSummary d) {
    final r = _family.rosterState;
    if (r is! SuccessState<HouseholdRoster>) return const <HouseholdMember>[];
    return r.data.members
        .where((m) =>
            (m.role == 'OWNER' || m.role == 'MEMBER') &&
            !(d.guardianActive && m.userId == d.guardianUserId))
        .toList(growable: false);
  }

  bool get isRosterLoaded => _family.rosterState is SuccessState<HouseholdRoster>;

  /// Lỗi roster gần nhất (null nếu không phải ErrorState) — M1 review #125.
  ApiException? get rosterError {
    final r = _family.rosterState;
    return r is ErrorState<HouseholdRoster> ? r.error : null;
  }

  /// Đang có request health cho [id] chưa về.
  bool isHealthInFlight(String id) => _healthInFlightId == id;

  /// Nạp health cho [id] chỉ khi cần: chưa Success cho id này và không có
  /// request nào đang bay (L3 — không GET trùng). Quyền vẫn do
  /// [loadHealthProfile] kiểm.
  Future<void> ensureHealthLoaded(String id) async {
    final h = _healthState.value;
    if (h is SuccessState<DependentHealthProfile> && h.data.dependentId == id) {
      return;
    }
    if (isHealthInFlight(id)) return _healthFuture;
    await loadHealthProfile(id);
  }

  /// Roster chưa Success → nạp (role/tên tươi). Lỗi bị bỏ qua — role rơi về
  /// JWT (Fix MODERATE-2).
  Future<void> ensureRoster() async {
    if (isRosterLoaded) return;
    await _family.loadRoster(keepCurrent: true);
  }

  String get _listCacheKey => 'dependents:${_session.householdId}';

  /// CHIA SẺ với ProfileStore — danh mục toàn cục (Guard 5).
  static const String _catalogCacheKey = 'allergen_catalog';

  // ── Đọc ──────────────────────────────────────────────────────────

  /// [keepCurrent] = nạp nền, không nháy Loading khi đang có list.
  Future<void> loadDependents({bool keepCurrent = false}) async {
    final seq = ++_listSeq;
    if (!keepCurrent ||
        _listState.value is! SuccessState<List<DependentSummary>>) {
      runInAction(() {
        _listState.value = const LoadingState<List<DependentSummary>>();
        _listFromCache.value = false;
      });
    }
    try {
      final items = await _api.listDependents();
      if (seq != _listSeq) return;
      runInAction(() {
        _listState.value = SuccessState<List<DependentSummary>>(items);
        _listFromCache.value = false;
      });
      unawaited(_writeListCache(items));
    } catch (raw) {
      final error = storeApiException(raw);
      // CHỈ mất mạng mới rơi về cache; lỗi BE → ErrorState.
      if (seq != _listSeq) return;
      final cached = error is NetworkException ? await _readListCache() : null;
      if (seq != _listSeq) return;
      runInAction(() {
        if (cached != null) {
          _listState.value = SuccessState<List<DependentSummary>>(cached);
          _listFromCache.value = true;
        } else {
          _listState.value = ErrorState<List<DependentSummary>>(error);
          _listFromCache.value = false;
        }
      });
    }
  }

  /// Song song: `getDependent(id)` + roster (nếu chưa Success). Chỉ gọi
  /// `getHealthProfile` khi [canEditHealthOf] đã `true` (Guard 2) — nếu không
  /// thì health giữ `LoadingState` và UI KHÔNG đọc nó.
  ///
  /// [keepCurrent] (L1 — pull-to-refresh): đang có detail Success cùng [id]
  /// thì GIỮ detail + health tới khi có kết quả mới, không nháy Loading.
  Future<void> loadDependentDetail(String id, {bool keepCurrent = false}) async {
    final seq = ++_detailSeq;
    final keep = keepCurrent && isDetailLoadedFor(id);
    _detailId = id;
    if (!keep) {
      _healthSeq++; // health của dependent trước không được ghi đè nữa
      _healthInFlightId = null;
      runInAction(() {
        _detailState.value = const LoadingState<DependentSummary>();
        _healthState.value = const LoadingState<DependentHealthProfile>();
      });
    }
    final roster = isRosterLoaded
        ? Future<void>.value()
        : _family.loadRoster(keepCurrent: true).catchError((Object _) {});
    DependentSummary detail;
    try {
      detail = await _api.getDependent(id);
      await roster;
    } catch (raw) {
      final error = storeApiException(raw);
      if (seq != _detailSeq) return;
      runInAction(() {
        _detailState.value = ErrorState<DependentSummary>(error);
        if (keep) {
          _healthState.value = const LoadingState<DependentHealthProfile>();
        }
      });
      return;
    }
    if (seq != _detailSeq) return;
    runInAction(() {
      _detailState.value = SuccessState<DependentSummary>(detail);
      _patchListItem(detail.id, (_) => detail); // L3 — badge list đổi theo
    });
    if (canEditHealthOf(detail)) {
      // ensureHealthLoaded: reaction của màn chi tiết (L4) có thể đã bắt đầu
      // GET — không gọi trùng (L3).
      await (keep
          ? loadHealthProfile(id, keepCurrent: true)
          : ensureHealthLoaded(id));
    } else if (keep) {
      // Mất quyền → không giữ health cũ (UI không đọc nó, Guard 2).
      _healthSeq++;
      runInAction(() =>
          _healthState.value = const LoadingState<DependentHealthProfile>());
    }
  }

  /// Không cache. Bỏ qua nếu [id] không phải dependent đang mở hoặc caller
  /// không có quyền (Guard 2 — phòng thủ ngay tại store).
  Future<void> loadHealthProfile(String id, {bool keepCurrent = false}) =>
      _healthFuture = _loadHealth(id, keepCurrent);

  Future<void> _loadHealth(String id, bool keepCurrent) async {
    final d = detailFor(id);
    if (_detailId != id || d == null || !canEditHealthOf(d)) return;
    final seq = ++_healthSeq;
    final current = _healthState.value;
    final keep = keepCurrent &&
        current is SuccessState<DependentHealthProfile> &&
        current.data.dependentId == id;
    if (!keep) {
      runInAction(() =>
          _healthState.value = const LoadingState<DependentHealthProfile>());
    }
    _healthInFlightId = id;
    try {
      final h = await _api.getHealthProfile(id);
      if (seq == _healthSeq) _healthInFlightId = null;
      if (seq != _healthSeq || _detailId != id) return;
      runInAction(() =>
          _healthState.value = SuccessState<DependentHealthProfile>(h));
    } catch (raw) {
      final error = storeApiException(raw);
      if (seq == _healthSeq) _healthInFlightId = null;
      if (seq != _healthSeq || _detailId != id) return;
      runInAction(() =>
          _healthState.value = ErrorState<DependentHealthProfile>(error));
      // Quyền ở client đã cũ: tải lại guardianActive + role. KHÔNG gọi lại
      // loadDependentDetail (sẽ lặp vô hạn nếu client vẫn tính ra có quyền).
      if (error.code == 'ERR_DEP_002') await _refreshPermissions(id);
    }
  }

  /// Chép `ProfileStore.loadAllergenCatalog` — cache key chung (Guard 5).
  Future<void> loadAllergenCatalog() async {
    runInAction(
        () => _catalogState.value = const LoadingState<List<Allergen>>());
    try {
      final catalog = await _healthApi.getAllergenCatalog();
      runInAction(
          () => _catalogState.value = SuccessState<List<Allergen>>(catalog));
      unawaited(_cache.put(_catalogCacheKey, <String, dynamic>{
        'items':
            catalog.map((Allergen a) => a.toJson()).toList(growable: false),
      }));
    } catch (raw) {
      final error = storeApiException(raw);
      final cached =
          error is NetworkException ? await _cache.get(_catalogCacheKey) : null;
      if (cached != null) {
        runInAction(() {
          _catalogState.value = SuccessState<List<Allergen>>(
            (cached.payload['items'] as List<dynamic>)
                .map(
                    (Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
                .toList(growable: false),
          );
        });
      } else {
        runInAction(
            () => _catalogState.value = ErrorState<List<Allergen>>(error));
      }
    }
  }

  // ── Mutation (không optimistic — §1) ─────────────────────────────

  Future<bool> createDependent({
    required String displayName,
    DateTime? dateOfBirth,
  }) async {
    if (!canManageDependents) return false;
    if (_createStatus.value == FormStatus.submitting) return false;
    final name = displayName.trim();
    if (name.isEmpty) return false;
    runInAction(() {
      _createStatus.value = FormStatus.submitting;
      _createError.value = null;
    });
    final DependentSummary created;
    try {
      created = await _api.createDependent(
          displayName: name, dateOfBirth: dateOfBirth);
    } catch (raw) {
      await _fail(_createStatus, _createError, raw, null);
      return false;
    }
    // BE đã xác nhận (không phải optimistic) → chèn ngay vào list + cache để
    // lần nạp lại lỗi mạng (rơi về cache) vẫn còn item mới (L2).
    final current = _listState.value;
    if (current is SuccessState<List<DependentSummary>> &&
        current.data.every((d) => d.id != created.id)) {
      final items = <DependentSummary>[...current.data, created];
      runInAction(() =>
          _listState.value = SuccessState<List<DependentSummary>>(items));
      await _writeListCache(items);
    }
    // Giữ `submitting` tới khi nạp lại xong (mirror changeRole).
    await loadDependents(keepCurrent: true);
    runInAction(() => _createStatus.value = FormStatus.success);
    return true;
  }

  Future<bool> deleteDependent(String id) async {
    if (!canAdminister) return false;
    if (_deleteStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _deleteStatus.value = FormStatus.submitting;
      _deleteError.value = null;
    });
    try {
      await _api.deleteDependent(id);
    } catch (raw) {
      await _fail(_deleteStatus, _deleteError, raw, id);
      return false;
    }
    final current = _listState.value;
    if (current is SuccessState<List<DependentSummary>>) {
      final items =
          current.data.where((d) => d.id != id).toList(growable: false);
      runInAction(() =>
          _listState.value = SuccessState<List<DependentSummary>>(items));
      unawaited(_writeListCache(items));
    }
    runInAction(() => _deleteStatus.value = FormStatus.success);
    return true;
  }

  Future<bool> changeGuardian(String id, String guardianUserId) async {
    if (!canAdminister) return false;
    if (_guardianStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _guardianStatus.value = FormStatus.submitting;
      _guardianError.value = null;
    });
    final DependentSummary updated;
    try {
      updated = await _api.changeGuardian(id, guardianUserId);
    } catch (raw) {
      await _fail(_guardianStatus, _guardianError, raw, id);
      return false;
    }
    runInAction(() {
      if (isDetailLoadedFor(id)) {
        _detailState.value = SuccessState<DependentSummary>(updated);
      }
      _patchListItem(id, (_) => updated);
      _guardianStatus.value = FormStatus.success;
    });
    return true;
  }

  /// Payload LUÔN đủ 6 key, null tường minh (Guard 6, #201). Chặn khi
  /// `!canSaveHealthFor(id)` — API không được gọi (Guard 15, 19).
  Future<bool> saveHealthProfile(
    String id, {
    required int? targetDailyCalories,
    required String? dietTypeWire,
    required double? heightCm,
    required double? weightKg,
    String? genderWire,
    String? activityLevelWire,
  }) async {
    if (!canSaveHealthFor(id)) return false;
    if (_healthSaveStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _healthSaveStatus.value = FormStatus.submitting;
      _healthSaveError.value = null;
    });
    final payload = <String, dynamic>{
      'targetDailyCalories': targetDailyCalories,
      'dietType': dietTypeWire,
      'heightCm': heightCm,
      'weightKg': weightKg,
      // #201: PUT thay toàn bộ — luôn gửi, `null` khi chưa chọn.
      'gender': genderWire,
      'activityLevel': activityLevelWire,
    };
    final DependentHealthProfile updated;
    try {
      updated = await _api.updateHealthProfile(id, payload);
    } catch (raw) {
      await _fail(_healthSaveStatus, _healthSaveError, raw, id);
      return false;
    }
    // Patch CẢ health, detail, list + cache (Guard 4) — dietType lấy từ
    // RESPONSE, không từ input.
    // L3: GET đang bay (dữ liệu TRƯỚC khi lưu) không được ghi đè response PUT.
    _healthSeq++;
    _healthInFlightId = null;
    runInAction(() {
      if (_detailId == id) {
        _healthState.value = SuccessState<DependentHealthProfile>(updated);
      }
      DependentSummary patch(DependentSummary d) => d.copyWith(
          dietType: updated.dietType, clearDietType: updated.dietType == null);
      _patchDetail(id, patch);
      _patchListItem(id, patch);
      _healthSaveStatus.value = FormStatus.success;
    });
    return true;
  }

  /// Chặn khi health chưa tải từ server — KHÔNG BAO GIỜ gửi `[]` sinh ra từ
  /// trạng thái chưa biết (Guard 15). Gửi id đã sort.
  Future<bool> saveAllergens(String id, List<int> allergenIds) async {
    if (!canSaveAllergensFor(id)) return false;
    if (_allergensSaveStatus.value == FormStatus.submitting) return false;
    runInAction(() {
      _allergensSaveStatus.value = FormStatus.submitting;
      _allergensSaveError.value = null;
    });
    final sorted = <int>[...allergenIds]..sort();
    final List<Allergen> updated;
    try {
      updated = await _api.updateAllergens(id, sorted);
    } catch (raw) {
      await _fail(_allergensSaveStatus, _allergensSaveError, raw, id);
      return false;
    }
    _healthSeq++; // L3 — như saveHealthProfile
    _healthInFlightId = null;
    runInAction(() {
      final h = _healthState.value;
      if (h is SuccessState<DependentHealthProfile> &&
          h.data.dependentId == id) {
        _healthState.value =
            SuccessState<DependentHealthProfile>(h.data.copyWith(allergens: updated));
      }
      DependentSummary patch(DependentSummary d) =>
          d.copyWith(allergens: updated);
      _patchDetail(id, patch);
      _patchListItem(id, patch);
      _allergensSaveStatus.value = FormStatus.success;
    });
    return true;
  }

  void clearCreateStatus() => _clear(_createStatus, _createError);
  void clearDeleteStatus() => _clear(_deleteStatus, _deleteError);
  void clearGuardianStatus() => _clear(_guardianStatus, _guardianError);
  void clearHealthSaveStatus() => _clear(_healthSaveStatus, _healthSaveError);
  void clearAllergensSaveStatus() =>
      _clear(_allergensSaveStatus, _allergensSaveError);

  // ── Nội bộ ───────────────────────────────────────────────────────

  /// Không reset khi đang `submitting` (như FamilyStore).
  void _clear(Observable<FormStatus> status, Observable<ApiException?> error) =>
      runInAction(() {
        if (status.value == FormStatus.submitting) return;
        status.value = FormStatus.idle;
        error.value = null;
      });

  /// Set `failure` + error, rồi phản ứng theo mã (bảng "Phản ứng sau lỗi
  /// mutation" §16.5).
  Future<void> _fail(
    Observable<FormStatus> status,
    Observable<ApiException?> errorObs,
    Object raw,
    String? id,
  ) async {
    final error = storeApiException(raw);
    runInAction(() {
      errorObs.value = error;
      status.value = FormStatus.failure;
    });
    switch (error.code) {
      case 'ERR_NETWORK':
        // Không biết server đã ghi chưa — KHÔNG reload.
        return;
      case 'ERR_DEP_002':
        if (id != null) await _refreshPermissions(id);
      case 'ERR_DEP_003' || 'ERR_DEP_006' || 'ERR_DEP_004':
        await _family.loadRoster(keepCurrent: true);
      case 'ERR_DEP_001':
        await loadDependents(keepCurrent: true);
      case 'ERR_ALLERGEN_NOT_FOUND':
        await loadAllergenCatalog();
    }
  }

  /// 403 ERR_DEP_002: nạp lại `guardianActive` (detail + list) và role —
  /// KHÔNG reset health/form về Loading; UI tự tính lại quyền (Blocked khi
  /// `canEditHealthOf` thành `false`).
  Future<void> _refreshPermissions(String id) async {
    await _family.loadRoster(keepCurrent: true);
    try {
      final d = await _api.getDependent(id);
      runInAction(() {
        _patchDetail(id, (_) => d);
        _patchListItem(id, (_) => d);
      });
    } catch (_) {
      // Giữ nguyên — role đã được làm tươi qua roster.
    }
  }

  void _patchDetail(String id, DependentSummary Function(DependentSummary) f) {
    final d = _detailState.value;
    if (d is SuccessState<DependentSummary> && d.data.id == id) {
      _detailState.value = SuccessState<DependentSummary>(f(d.data));
    }
  }

  /// Patch item cùng [id] trong list (nếu có) + ghi cache.
  void _patchListItem(String id, DependentSummary Function(DependentSummary) f) {
    final current = _listState.value;
    if (current is! SuccessState<List<DependentSummary>>) return;
    if (current.data.every((d) => d.id != id)) return;
    final items = current.data
        .map((d) => d.id == id ? f(d) : d)
        .toList(growable: false);
    _listState.value = SuccessState<List<DependentSummary>>(items);
    unawaited(_writeListCache(items));
  }

  Future<void> _writeListCache(List<DependentSummary> items) =>
      _cache.put(_listCacheKey, <String, dynamic>{
        'items': items.map((d) => d.toJson()).toList(growable: false),
      });

  Future<List<DependentSummary>?> _readListCache() async {
    final cached = await _cache.get(_listCacheKey);
    if (cached == null) return null;
    try {
      return (cached.payload['items'] as List<dynamic>)
          .map((Object? e) =>
              DependentSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (_) {
      return null; // cache hỏng = như không có cache
    }
  }
}
