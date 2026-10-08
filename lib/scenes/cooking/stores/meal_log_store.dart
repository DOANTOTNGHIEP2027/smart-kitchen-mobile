import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../profile/api/health_api.dart';
import '../../profile/stores/form_status.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/states/view_state.dart';
import '../data/meal_log_api.dart';
import '../domain/meal_log_entry.dart';
import '../domain/meal_type.dart';

/// State + actions cho màn hình nhật ký bữa ăn (#82, meal-log-screen §7).
///
/// MobX thủ công (Observable + runInAction), cùng pattern `CookingSessionStore`
/// — không dùng codegen để giữ code phẳng, không kéo theo `ProfileStore`
/// (Decision D3 — chỉ dùng `HealthApi` trực tiếp).
class MealLogStore {
  MealLogStore(
    this._api,
    this._healthApi,
    this._sessionStore, {
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final MealLogApi _api;
  final HealthApi _healthApi;
  final SessionStore _sessionStore;

  /// 1 nguồn sự thật cho "hôm nay" — injectable để test theo ngày mà không
  /// phụ thuộc đồng hồ thật (Fix review Task 1). Best-effort theo local device.
  final DateTime Function() now;

  int _tempIdCounter = 0;
  int _loadGeneration = 0;

  final Observable<ViewState<List<MealLogEntry>>> _todayLogsState =
      Observable<ViewState<List<MealLogEntry>>>(const LoadingState());
  final Observable<FormStatus> _confirmStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _confirmError =
      Observable<ApiException?>(null);

  /// Lưu payload gốc của chaque submit để `retrySubmit()` dùng lại đúng
  /// description/image (Guard #8).
  final Map<String, _PendingSubmit> _pendingPayloads =
      <String, _PendingSubmit>{};

  final Observable<int?> _targetDailyCalories = Observable<int?>(null);
  final Observable<bool> _targetLoaded = Observable<bool>(false);

  /// Entry vừa submit thành công VÀ `requiresConfirmation == true` — UI
  /// (MealLogScene) lắng nghe qua `reaction` để tự mở CalorieConfirmSheet
  /// đúng 1 lần (Guard #6).
  final Observable<MealLogEntry?> _autoConfirmTarget =
      Observable<MealLogEntry?>(null);

  // ── Getters ──────────────────────────────────────────────────────────────

  ViewState<List<MealLogEntry>> get todayLogsState => _todayLogsState.value;
  FormStatus get confirmStatus => _confirmStatus.value;
  ApiException? get confirmError => _confirmError.value;
  MealLogEntry? get autoConfirmTarget => _autoConfirmTarget.value;

  String get _selfId => _sessionStore.currentUser?.id ?? '';

  /// Calo còn lại hôm nay = target − tổng calo đã log thoả `countsTowardDailyTotal`.
  ///
  /// `null` khi target chưa tải xong hoặc chưa setup (best-effort — không chặn
  /// màn hình, xem failure modes).
  int? get calorieGoalRemaining {
    if (!_targetLoaded.value) return null;
    final target = _targetDailyCalories.value;
    if (target == null) return null;
    final state = _todayLogsState.value;
    final consumed = state is SuccessState<List<MealLogEntry>>
        ? state.data
            .where((e) =>
                e.status == MealEntryStatus.saved && e.countsTowardDailyTotal)
            .fold<double>(0, (sum, e) => sum + e.caloriesKcal!)
        : 0.0;
    return (target - consumed).round();
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  /// Load log hôm nay + calo target.
  ///
  /// Reconciliation an toàn: (Fix HIGH-1) khi GET lỗi giữ NGUYÊN VẸN
  /// `previous.data` (kể cả entry saved) nếu đã từng tải thành công; (Guard
  /// #7) không làm mất entry pending/failed chưa reconcile; (Guard #14) dedupe
  /// theo `id`, ưu tiên bản ghi từ GET khi trùng.
  Future<void> loadToday() async {
    final previous = _todayLogsState.value;
    final inFlight = previous is SuccessState<List<MealLogEntry>>
        ? previous.data
            .where((e) => e.status != MealEntryStatus.saved)
            .toList()
        : <MealLogEntry>[];

    // Guard generation chống race: 2 lần gọi chồng nhau, chỉ lần gần nhất
    // được ghi kết quả (Fix review Task 1).
    final requestTs = ++_loadGeneration;

    _todayLogsState.value = const LoadingState();

    final today = now();
    final results = await Future.wait(<Future<Object?>>[
      _api
          .listLogs(from: today, to: today)
          .then<Object>((List<MealLogEntry> v) => v)
          .catchError((Object e) => e),
      _loadCalorieGoal(),
    ]);

    if (requestTs != _loadGeneration) return;

    final logsResult = results[0];
    if (logsResult is ApiException) {
      // Fix HIGH-1: giữ toàn bộ previous.data — ko biến 1 lỗi refetch thành
      // mất mát entry saved đã hiển thị. Chỉ rơi về ErrorState khi chưa từng
      // tải thành công lần nào.
      _todayLogsState.value =
          previous is SuccessState<List<MealLogEntry>>
              ? SuccessState<List<MealLogEntry>>(previous.data)
              : ErrorState<List<MealLogEntry>>(logsResult);
      return;
    }

    // Fix MEDIUM-1: dedupe theo id, ưu tiên GET khi trùng (Guard #14).
    final authoritative = <String, MealLogEntry>{
      for (final e in inFlight) e.id: e,
    };
    for (final e in logsResult as List<MealLogEntry>) {
      authoritative[e.id] = e;
    }
    final logs = authoritative.values.toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _todayLogsState.value = SuccessState<List<MealLogEntry>>(logs);
  }

  /// Best-effort — không chặn màn hình. `_targetLoaded = true` sau khi thử kể
  /// cả khi thất bại để `calorieGoalRemaining` không kẹt "đang tải" vô hạn.
  Future<void> _loadCalorieGoal() async {
    try {
      final profile = await _healthApi.getMyHealthProfile();
      _targetDailyCalories.value = profile.targetDailyCalories;
    } on ApiException {
      _targetDailyCalories.value = null;
    } on DioException {
      // HealthApi chưa `_unwrap` — ném DioException (not ApiException). Bắt ở
      // đây để `loadToday` không throw giữa chừng (Fix review Task 1).
      _targetDailyCalories.value = null;
    } finally {
      runInAction(() => _targetLoaded.value = true);
    }
  }

  // ── Submit (optimistic) ──────────────────────────────────────────────────

  /// Optimistic insert NGAY trước await (Decision D4 — endpoint có thể mất
  /// ~32s vì AI relay đồng bộ). Không throw; lỗi phản ánh qua `status=failed`
  /// trên chính entry.
  Future<void> submitLog({
    required MealType mealType,
    String? userDescription,
    Uint8List? imageBytes,
  }) async {
    final tempId = 'local-${_tempIdCounter++}';
    final description = mealType.composeDescription(userDescription);
    final nowUtc = now().toUtc();

    _pendingPayloads[tempId] =
        _PendingSubmit(description: description, imageBytes: imageBytes);

    runInAction(() {
      final state = _todayLogsState.value;
      final list = state is SuccessState<List<MealLogEntry>>
          ? List<MealLogEntry>.of(state.data)
          : <MealLogEntry>[];
      list.insert(
        0,
        MealLogEntry(
          id: tempId,
          householdId: _sessionStore.householdId ?? '',
          memberId: _selfId,
          loggedBy: _selfId,
          description: description,
          caloriesKcal: null,
          nutrition: null,
          foodItemsDetected: null,
          requiresConfirmation: false,
          confirmedByUser: false,
          loggedAt: nowUtc,
          confirmedAt: null,
          status: MealEntryStatus.pending,
        ),
      );
      _todayLogsState.value = SuccessState<List<MealLogEntry>>(list);
    });

    await _doSubmit(tempId);
  }

  /// Thử lại 1 entry `failed` — dùng lại ĐÚNG payload gốc (Guard #8).
  Future<void> retrySubmit(String id) async {
    if (!_pendingPayloads.containsKey(id)) return;
    final entry = _entryById(id);
    if (entry != null) {
      _replaceToday(id, entry.copyWith(status: MealEntryStatus.pending));
    }
    await _doSubmit(id);
  }

  Future<void> _doSubmit(String tempId) async {
    final payload = _pendingPayloads[tempId];
    if (payload == null) return;
    try {
      final saved = await _api.logMeal(
        description: payload.description,
        imageBase64: payload.imageBytes == null
            ? null
            : base64Encode(payload.imageBytes!),
      );
      _pendingPayloads.remove(tempId);
      runInAction(() {
        _replaceToday(tempId, saved.copyWith(status: MealEntryStatus.saved));
        // Lỗi ở đây KHÔNG BAO GIỜ là "AI fail" (Guard #5) — chỉ set auto-confirm
        // khi BE báo requiresConfirmation.
        if (saved.requiresConfirmation) {
          _autoConfirmTarget.value = saved;
        }
      });
    } on ApiException {
      final current = _entryById(tempId);
      if (current != null) {
        _replaceToday(tempId, current.copyWith(status: MealEntryStatus.failed));
      }
    }
  }

  void discardFailed(String id) {
    _pendingPayloads.remove(id);
    _removeToday(id);
  }

  void clearAutoConfirmTarget() {
    runInAction(() => _autoConfirmTarget.value = null);
  }

  // ── Confirm calo ─────────────────────────────────────────────────────────

  /// `caloriesKcal == null` chỉ hợp lệ khi entry hiện tại KHÔNG null (chấp
  /// nhận đúng như AI) — UI validate trước khi gọi (Guard #10).
  Future<bool> confirmCalories(String id, {double? caloriesKcal}) async {
    _confirmStatus.value = FormStatus.submitting;
    _confirmError.value = null;
    try {
      final updated = await _api.confirm(id: id, caloriesKcal: caloriesKcal);
      runInAction(() {
        _replaceToday(id, updated.copyWith(status: MealEntryStatus.saved));
        _confirmStatus.value = FormStatus.success;
      });
      return true;
    } on ApiException catch (e) {
      runInAction(() {
        _confirmStatus.value = FormStatus.failure;
        _confirmError.value = e;
      });
      return false;
    }
  }

  void clearConfirmError() {
    runInAction(() {
      _confirmStatus.value = FormStatus.idle;
      _confirmError.value = null;
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  MealLogEntry? _entryById(String id) {
    final s = _todayLogsState.value;
    if (s is! SuccessState<List<MealLogEntry>>) return null;
    for (final e in s.data) {
      if (e.id == id) return e;
    }
    return null;
  }

  void _replaceToday(String id, MealLogEntry updated) {
    final s = _todayLogsState.value;
    if (s is! SuccessState<List<MealLogEntry>>) return;
    _todayLogsState.value = SuccessState<List<MealLogEntry>>(s.data
        .map((e) => e.id == id ? updated : e)
        .toList());
  }

  void _removeToday(String id) {
    final s = _todayLogsState.value;
    if (s is! SuccessState<List<MealLogEntry>>) return;
    _todayLogsState.value =
        SuccessState<List<MealLogEntry>>(s.data.where((e) => e.id != id).toList());
  }
}

/// Payload gốc giữ lại cho retry (Guard #8).
class _PendingSubmit {
  const _PendingSubmit({required this.description, this.imageBytes});
  final String description;
  final Uint8List? imageBytes;
}