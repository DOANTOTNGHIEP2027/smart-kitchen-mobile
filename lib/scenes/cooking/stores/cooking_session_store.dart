import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../cooking/data/cooking_session_api.dart';
import '../../cooking/data/recipe_api.dart';
import '../../cooking/domain/cooking_session.dart';
import '../../cooking/domain/cooking_session_step.dart';
import '../../cooking/domain/ingredient_deduction.dart';

/// Phase của màn hình cooking (FE-6 §6.1 — state machine 5 nhánh).
///
/// Khác `ViewState<T>` của shell (model loading/empty/error/success):
/// `phase` mang ngữ nghĩa nghiệp vụ riêng và KHÔNG có `empty` — màn hình
/// lúc nào cũng cần có 1 session hoặc 1 lỗi để hiển thị.
enum CookingScreenPhase { loading, error, active, completed, abandoned }

/// Điểm vào của màn hình (FE-6 §10 CookingArgs).
/// `start` tạo session mới qua `POST /cooking/sessions`. `resume` lấy session
/// đã có qua `GET /cooking/sessions/{id}`.
enum CookingEntryMode { start, resume }

/// State + actions cho màn hình nấu ăn (FE-6 §6).
///
/// MobX thủ công (Observable + runInAction), cùng pattern `InventoryStore` —
/// không dùng codegen để giữ code phẳng trong scope 2,5 ngày công.
class CookingSessionStore {
  CookingSessionStore({
    required CookingSessionApi cookingApi,
    required RecipeApi recipeApi,
    required this.entryMode,
    this.recipeId,
    String? sessionId,
  })  : _cookingApi = cookingApi,
        _recipeApi = recipeApi,
        _sessionId = sessionId;

  final CookingSessionApi _cookingApi;
  final RecipeApi _recipeApi;
  final CookingEntryMode entryMode;

  /// Bắt buộc khi `entryMode == start`. `null` khi `entryMode == resume`.
  final String? recipeId;

  /// Biết sau `start()` (mode start) HOẶC truyền sẵn khi `entryMode == resume`.
  String? _sessionId;

  Timer? _ticker;

  final Observable<CookingScreenPhase> _phase =
      Observable<CookingScreenPhase>(CookingScreenPhase.loading);
  final Observable<CookingSession?> _session =
      Observable<CookingSession?>(null);
  final Observable<List<CookingSessionStep>> _steps =
      Observable<List<CookingSessionStep>>(const <CookingSessionStep>[]);
  final Observable<List<IngredientDeduction>> _deductions =
      Observable<List<IngredientDeduction>>(const <IngredientDeduction>[]);
  final Observable<int> _viewedStep = Observable<int>(1);
  final Observable<int?> _remainingSeconds = Observable<int?>(null);
  final Observable<bool> _timerRunning = Observable<bool>(false);
  final Observable<bool> _isAdvancing = Observable<bool>(false);
  final Observable<bool> _isCompleting = Observable<bool>(false);
  final Observable<bool> _isAbandoning = Observable<bool>(false);
  final Observable<ApiException?> _loadError =
      Observable<ApiException?>(null);
  final Observable<ApiException?> _actionError =
      Observable<ApiException?>(null);

  // Mã lỗi ở `phase=error` KHÔNG tự sửa được bằng cách gọi lại đúng request
  // vừa lỗi (id/recipe sai vẫn sẽ sai lần nữa).
  static const Set<String> _nonRetryableLoadErrorCodes = <String>{
    'ERR_SESSION_NOT_FOUND',
    'ERR_SESSION_NO_HOUSEHOLD',
    'ERR_SESSION_RECIPE_NOT_FOUND',
    'ERR_SESSION_RECIPE_NO_STEPS',
  };

  // ── Getters ──────────────────────────────────────────────────────────────

  CookingScreenPhase get phase => _phase.value;
  CookingSession? get session => _session.value;
  List<CookingSessionStep> get steps => _steps.value;
  List<IngredientDeduction> get deductions => _deductions.value;
  int get viewedStep => _viewedStep.value;
  int? get remainingSeconds => _remainingSeconds.value;
  bool get timerRunning => _timerRunning.value;
  bool get isAdvancing => _isAdvancing.value;
  bool get isCompleting => _isCompleting.value;
  bool get isAbandoning => _isAbandoning.value;
  ApiException? get loadError => _loadError.value;
  ApiException? get actionError => _actionError.value;

  bool get isViewingCurrentStep =>
      viewedStep == (session?.currentStep ?? 1);

  CookingSessionStep? get viewedStepDef {
    final idx = viewedStep - 1;
    if (idx < 0 || idx >= _steps.value.length) return null; // Guard #7
    return _steps.value[idx];
  }

  /// `true` nếu nút chính ở `phase=error` nên gọi `retryLoad()` (lỗi mạng/
  /// server, có cơ hội tự sửa); `false` nếu nên điều hướng ra ngoài
  /// (`Get.back()`) — id/recipe sai sẽ luôn sai.
  bool get loadErrorIsRetryable {
    final code = _loadError.value?.code;
    return code == null || !_nonRetryableLoadErrorCodes.contains(code);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> init() async {
    runInAction(() {
      _phase.value = CookingScreenPhase.loading;
      _loadError.value = null;
    });
    try {
      final CookingSession s;
      if (entryMode == CookingEntryMode.start) {
        if (recipeId == null) {
          throw StateError('recipeId required when entryMode == start');
        }
        s = await _cookingApi.start(recipeId!);
        _sessionId = s.id;
        runInAction(() => _deductions.value = const <IngredientDeduction>[]);
      } else {
        final id = _sessionId;
        if (id == null) {
          throw StateError('sessionId required when entryMode == resume');
        }
        final result = await _cookingApi.getById(id);
        s = result.session;
        runInAction(() => _deductions.value = result.deductions);
      }
      final bundle = await _recipeApi.getSteps(s.recipeId);
      runInAction(() {
        _session.value = s;
        _steps.value = bundle;
        _viewedStep.value = s.currentStep;
      });
      _resolvePhaseFromStatus();
      if (_phase.value == CookingScreenPhase.active) {
        _startTimerForCurrentStep();
      }
    } on ApiException catch (e) {
      runInAction(() {
        _loadError.value = e;
        _phase.value = CookingScreenPhase.error;
      });
    }
  }

  /// Retry chỉ gọi lại phần đã lỗi — nếu session đã tồn tại (start() từng
  /// thành công, chỉ recipe fetch lỗi), KHÔNG gọi lại start() Implementation
  /// Guard §9.9 — gọi lại `start()` tạo 1 session THỨ HAI cho cùng 1 lần nấu,
  /// để lại 1 session mồ côi IN_PROGRESS.
  Future<void> retryLoad() async {
    // Các điều kiện:
    // - `_sessionId != null`: `start()` đã chạy thành công ở lần đầu (start()
    //   đặt _sessionId ngay sau khi nhận response, trước khi getSteps).
    // - `_steps.value.isEmpty`: chỉ retry khi phần recipe chưa tải.
    //
    // KHÔNG gọi `start()` lần 2 — Guard §9.9: tạo session mồ côi thứ hai.
    if (_sessionId != null && _steps.value.isEmpty) {
      final knownRecipeId = _session.value?.recipeId ??
          (entryMode == CookingEntryMode.start ? recipeId : null);
      if (knownRecipeId == null) {
        await init();
        return;
      }
      runInAction(() {
        _phase.value = CookingScreenPhase.loading;
        _loadError.value = null;
      });
      try {
        if (_session.value == null) {
          final result = await _cookingApi.getById(_sessionId!);
          runInAction(() {
            _session.value = result.session;
            _deductions.value = result.deductions;
            _viewedStep.value = result.session.currentStep;
          });
        }
        final bundle = await _recipeApi.getSteps(knownRecipeId);
        runInAction(() => _steps.value = bundle);
        _resolvePhaseFromStatus();
        if (_phase.value == CookingScreenPhase.active) {
          _startTimerForCurrentStep();
        }
      } on ApiException catch (e) {
        runInAction(() {
          _loadError.value = e;
          _phase.value = CookingScreenPhase.error;
        });
      }
    } else {
      await init();
    }
  }

  void _resolvePhaseFromStatus() {
    final status = _session.value?.status;
    if (status == null) {
      runInAction(() => _phase.value = CookingScreenPhase.error);
      return;
    }
    switch (status) {
      case CookingSessionStatusWire.inProgress:
        runInAction(() => _phase.value = CookingScreenPhase.active);
      case CookingSessionStatusWire.completed:
        runInAction(() => _phase.value = CookingScreenPhase.completed);
      case CookingSessionStatusWire.abandoned:
        runInAction(() => _phase.value = CookingScreenPhase.abandoned);
    }
  }

  // ── Điều hướng bước cục bộ (KHÔNG gọi API) ──────────────────────────────

  void viewPreviousStep() {
    if (_viewedStep.value <= 1) return;
    _cancelTimer();
    runInAction(() => _viewedStep.value -= 1);
  }

  void returnToCurrentStep() {
    if (isViewingCurrentStep) return;
    _cancelTimer();
    runInAction(() {
      _viewedStep.value = _session.value?.currentStep ?? 1;
    });
    if (_phase.value == CookingScreenPhase.active) {
      _startTimerForCurrentStep();
    }
  }

  // ── Mutation thật (non-optimistic) ──────────────────────────────────────

  /// Nút chính: "Bước tiếp theo" hoặc "Hoàn thành" tuỳ `isLastStep`.
  /// Guard §9.1: không cho phép gọi khi `!isViewingCurrentStep` — tránh advance
  /// từ 1 bước đang xem lại.
  Future<void> advanceOrComplete() async {
    if (!isViewingCurrentStep || _session.value == null) return;
    final s = _session.value!;
    if (s.isLastStep) {
      await complete();
      return;
    }
    runInAction(() {
      _isAdvancing.value = true;
      _actionError.value = null;
    });
    try {
      final updated =
          await _cookingApi.advanceStep(s.id, s.currentStep + 1);
      runInAction(() {
        _session.value = updated;
        _viewedStep.value = updated.currentStep;
      });
      _startTimerForCurrentStep();
    } catch (e) {
      if (e is BusinessException &&
          (e.code == 'ERR_SESSION_ALREADY_ENDED' ||
              e.code == 'ERR_SESSION_STEP_INVALID')) {
        // Local state đã lệch server — resync qua GET (Guard §9.9: không
        // gọi retryLoad()/init() — sẽ tạo session thứ hai).
        await _resyncSessionFromServer();
      } else if (e is ApiException) {
        runInAction(() => _actionError.value = e);
      } else {
        rethrow;
      }
    } finally {
      runInAction(() => _isAdvancing.value = false);
    }
  }

  /// Hoàn thành — trừ kho FIFO nearest-expiry, atomic (#76 D1).
  /// BE luôn trả 200 khi session hợp lệ — shortfall nằm trong deductions, FE
  /// dùng [IngredientDeduction.hasShortfall] để render cảnh báo (OD-04).
  Future<void> complete() async {
    final s = _session.value;
    if (s == null) return;
    runInAction(() {
      _isCompleting.value = true;
      _actionError.value = null;
    });
    try {
      final result = await _cookingApi.complete(s.id);
      runInAction(() {
        _session.value = result.session;
        _deductions.value = result.deductions;
      });
      _cancelTimer();
      runInAction(() => _phase.value = CookingScreenPhase.completed);
    } catch (e) {
      if (e is BusinessException &&
          e.code == 'ERR_SESSION_ALREADY_ENDED') {
        await _resyncSessionFromServer();
      } else if (e is ApiException) {
        // Bao gồm ERR_SESSION_COMPLETE_CONFLICT (deadlock, retry an toàn) và
        // mọi mã khác — UI hiện banner retry.
        runInAction(() => _actionError.value = e);
      } else {
        rethrow;
      }
    } finally {
      runInAction(() => _isCompleting.value = false);
    }
  }

  /// Abandon — đóng session, KHÔNG đụng kho (#76).
  Future<void> abandon() async {
    final s = _session.value;
    if (s == null) return;
    runInAction(() {
      _isAbandoning.value = true;
      _actionError.value = null;
    });
    try {
      final updated = await _cookingApi.abandon(s.id);
      runInAction(() => _session.value = updated);
      _cancelTimer();
      runInAction(() => _phase.value = CookingScreenPhase.abandoned);
    } catch (e) {
      if (e is BusinessException &&
          e.code == 'ERR_SESSION_ALREADY_ENDED') {
        await _resyncSessionFromServer();
      } else if (e is ApiException) {
        runInAction(() => _actionError.value = e);
      } else {
        rethrow;
      }
    } finally {
      runInAction(() => _isAbandoning.value = false);
    }
  }

  /// GET lại session THẬT khi state cục bộ có thể đã lệch server — dùng
  /// chung cho `ERR_SESSION_ALREADY_ENDED` (session đã kết thúc ở nơi khác)
  /// và `ERR_SESSION_STEP_INVALID` (cục bộ đã cũ). KHÔNG BAO GIỜ dùng
  /// `retryLoad()`/`init()` cho 2 tình huống này — Guard §9.9.
  Future<void> _resyncSessionFromServer() async {
    final id = _session.value?.id ?? _sessionId;
    if (id == null) return;
    try {
      final result = await _cookingApi.getById(id);
      runInAction(() {
        _session.value = result.session;
        _deductions.value = result.deductions;
        _viewedStep.value = result.session.currentStep;
      });
      _cancelTimer();
      _resolvePhaseFromStatus();
      if (_phase.value == CookingScreenPhase.active) {
        _startTimerForCurrentStep();
      }
    } on ApiException catch (e) {
      runInAction(() => _actionError.value = e);
    }
  }

  // ── Timer per-step (sống trong Store — yêu cầu #81) ─────────────────────

  void _startTimerForCurrentStep() {
    _cancelTimer();
    final def = viewedStepDef;
    final duration = def?.durationSeconds;
    if (duration == null) {
      runInAction(() {
        _remainingSeconds.value = null;
      });
      return;
    }
    runInAction(() {
      _remainingSeconds.value = duration;
      _timerRunning.value = true;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _remainingSeconds.value;
      if (remaining == null || remaining <= 0) {
        _cancelTimer();
        HapticFeedback.vibrate();
        return;
      }
      runInAction(() => _remainingSeconds.value = remaining - 1);
    });
  }

  void toggleTimer() {
    if (!isViewingCurrentStep) return;
    if (_timerRunning.value) {
      _ticker?.cancel();
      _ticker = null;
      runInAction(() => _timerRunning.value = false);
    } else if (_remainingSeconds.value != null &&
        _remainingSeconds.value! > 0) {
      runInAction(() => _timerRunning.value = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining = _remainingSeconds.value;
        if (remaining == null || remaining <= 0) {
          _cancelTimer();
          HapticFeedback.vibrate();
          return;
        }
        runInAction(() => _remainingSeconds.value = remaining - 1);
      });
    }
  }

  void resetTimer() => _startTimerForCurrentStep();

  void _cancelTimer() {
    _ticker?.cancel();
    _ticker = null;
    runInAction(() => _timerRunning.value = false);
  }

  void clearActionError() =>
      runInAction(() => _actionError.value = null);

  void dispose() => _cancelTimer();
}
