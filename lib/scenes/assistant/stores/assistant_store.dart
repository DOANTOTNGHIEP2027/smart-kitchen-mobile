import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../utils/uuid.dart';
import '../data/assistant_api.dart';
import '../domain/assistant_models.dart';

enum AssistRequestState { idle, sending, error }

/// Cách UI hiển thị lỗi lần gửi gần nhất.
enum AssistErrorKind {
  /// AI lỗi/bận/hết giờ, mất kết nối giữa chừng — có "Thử lại".
  busy,

  /// `ERR_AI_CONTENT_FILTERED` — KHÔNG có "Thử lại".
  filtered,

  /// `ERR_ASSISTANT_CONTEXT_INVALID` (buổi nấu đã kết thúc, bước không có…)
  /// — tắt trợ lý cho hết ngữ cảnh này.
  unavailable,

  /// `ERR_ASSISTANT_SESSION_NOT_FOUND` / `_CLOSED` — đóng UI, tắt trợ lý.
  ended,

  /// `ERR_ASSISTANT_RATE_LIMIT` — hỏi quá nhanh: khoá ô nhập một lúc (S10).
  rateLimited,

  /// 400/403/khác — câu báo chung.
  generic,
}

/// Ngữ cảnh của phiên PLANNING (ô bữa trong thực đơn + số ngày cần lên).
typedef PlanningArgs = ({String mealPlanId, String slotId, int horizonDays});

/// Trợ lý bếp (#204, FE design `kitchen-assistant.md` v2 §3).
///
/// Một store cho một ngữ cảnh ([contextType] + [contextKey]); phiên BE tạo
/// lười ở câu hỏi đầu tiên và gắn cố định với ngữ cảnh đó. Gửi lượt nhận 202
/// rồi chờ kết quả qua SSE (`turn.progress` → `turn.completed`), stream lỗi
/// hoặc im lặng quá [streamSilence] thì poll `GET …/turns/{turnId}`.
///
/// Màn nấu chỉ được đọc qua callback — lỗi/chờ ở đây không đổi `phase`, không
/// chặn timer/chuyển bước/complete/abandon. MobX thủ công (không codegen).
class AssistantStore {
  AssistantStore({
    required AssistantApi api,
    required this.contextType,
    required String? Function() contextKey,
    required bool Function() isOnline,
    int? Function()? currentStep,
    PlanningArgs? Function()? planning,
    String? Function()? accountScope,
    String Function()? clientTurnIdGenerator,
    this.slowAfter = const Duration(seconds: 5),
    this.pollInterval = const Duration(milliseconds: 1500),
    this.streamSilence = const Duration(seconds: 15),
    this.inFlightRetryDelay = const Duration(seconds: 5),
    this.maxWait = const Duration(seconds: 100),
    this.reuseWithin = const Duration(hours: 2),
    this.rateLimitCooldown = const Duration(minutes: 1),
  })  : _api = api,
        _planningOf = planning,
        _contextKeyOf = contextKey,
        _currentStepOf = currentStep,
        _isOnline = isOnline,
        _newClientTurnId = clientTurnIdGenerator ?? createUuidV4 {
    // Đổi tài khoản/household (logout cũng đổi) → bỏ hội thoại ngay.
    if (accountScope != null) {
      _scopeReaction = reaction<String?>((_) => accountScope(), (_) => reset());
    }
  }

  /// BE nhận tới 1000; giữ 500 như màn nấu cũ để câu hỏi gọn.
  static const int maxMessageLength = 500;

  static const Set<String> _busyCodes = <String>{
    'ERR_AI_TIMEOUT',
    'ERR_AI_SERVICE_DOWN',
    'ERR_AI_INVALID_OUTPUT',
    'ERR_AI_RATE_LIMIT',
    'ERR_NETWORK',
    // 4xx không envelope (vd. 429 từ gateway) — interceptor không biết mã.
    'ERR_UNKNOWN',
  };

  final AssistantApi _api;
  final AssistantContextType contextType;
  final String? Function() _contextKeyOf;
  final int? Function()? _currentStepOf;
  final bool Function() _isOnline;
  final String Function() _newClientTurnId;
  final Duration slowAfter;
  final Duration pollInterval;
  final Duration streamSilence;
  final Duration inFlightRetryDelay;
  final Duration maxWait;

  /// FAB toàn cục mở lại phiên GLOBAL gần nhất nếu còn trong khoảng này.
  final Duration reuseWithin;

  /// Bị `ERR_ASSISTANT_RATE_LIMIT` thì khoá ô nhập trong khoảng này.
  final Duration rateLimitCooldown;
  final PlanningArgs? Function()? _planningOf;
  Timer? _cooldownTimer;
  bool _opened = false;
  final Observable<bool> _loadingHistory = Observable<bool>(false);

  /// Trạng thái đề xuất đổi trong phiên (sau khi bấm), đè trạng thái lúc tải.
  final ObservableMap<String, ActionResult> _actionResults =
      ObservableMap<String, ActionResult>();
  final ObservableSet<String> _actionsInFlight = ObservableSet<String>();
  ReactionDisposer? _scopeReaction;

  /// Token của request đang chờ — kết quả mang token khác bị bỏ.
  int _pendingToken = 0;
  int _tokenSeq = 0;

  /// Ngữ cảnh sở hữu hội thoại + phiên BE hiện tại.
  String? _boundKey;
  String? _sessionId;
  bool _disposed = false;
  Timer? _slowTimer;

  final ObservableList<AssistMessage> messages =
      ObservableList<AssistMessage>();
  final Observable<AssistRequestState> _state =
      Observable<AssistRequestState>(AssistRequestState.idle);
  final Observable<String?> _errorCode = Observable<String?>(null);
  final Observable<AssistErrorKind?> _errorKind =
      Observable<AssistErrorKind?>(null);
  final Observable<ApiException?> _error = Observable<ApiException?>(null);
  final Observable<bool> _slow = Observable<bool>(false);
  final Observable<bool> _disabled = Observable<bool>(false);
  final Observable<String?> _progressTool = Observable<String?>(null);

  /// Lần gửi lỗi — "Thử lại" gửi lại đúng tin, đúng `clientTurnId` (BE không
  /// gọi AI hai lần) và đúng bước lúc bấm gửi.
  AssistMessage? _failedMessage;
  String? _failedClientTurnId;
  int? _failedStep;

  AssistRequestState get state => _state.value;
  String? get errorCode => _errorCode.value;
  AssistErrorKind? get errorKind => _errorKind.value;
  ApiException? get error => _error.value;
  bool get isSending => !_isStale && state == AssistRequestState.sending;

  /// "Trợ lý đang suy nghĩ lâu hơn bình thường" — sau [slowAfter].
  bool get isSlow => _slow.value;

  /// Tool AI đang chạy (từ `turn.progress`); `null` khi chưa biết.
  String? get progressTool => _progressTool.value;

  /// Ẩn lối vào + không gửi nữa cho hết ngữ cảnh này.
  bool get isDisabled => !_isStale && _disabled.value;

  /// Ngữ cảnh hiện tại khác ngữ cảnh sở hữu hội thoại → state cũ thuộc phiên
  /// trước, không được chặn phiên mới.
  bool get _isStale => _boundKey != null && _contextKeyOf() != _boundKey;
  bool get isOffline => !_isOnline();
  bool get _needsStep => contextType == AssistantContextType.cooking;
  bool get canRetry =>
      state == AssistRequestState.error &&
      errorKind == AssistErrorKind.busy &&
      _failedMessage != null &&
      !isDisabled;
  AssistMessage? get failedMessage => _failedMessage;

  /// Nút gửi bật khi câu hỏi hợp lệ và không có gì đang chặn.
  bool canSend(String raw) {
    final text = raw.trim();
    return text.isNotEmpty &&
        text.length <= maxMessageLength &&
        !isSending &&
        !isDisabled &&
        !isLoadingHistory &&
        errorKind != AssistErrorKind.rateLimited &&
        !isOffline &&
        _contextKeyOf() != null &&
        (!_needsStep || _currentStepOf?.call() != null);
  }

  /// Trạng thái hiện tại của một đề xuất: kết quả bấm trong phiên, nếu chưa
  /// bấm thì trạng thái BE; PENDING quá `expiresAt` theo giờ máy ⇒ hết hạn
  /// (không bao giờ hiện nút xác nhận cho đề xuất đã hết hạn — FE design §4).
  ActionStatus actionStatus(AssistantAction action) {
    final local = _actionResults[action.actionId];
    if (local != null) return local.status;
    final expires = action.expiresAt;
    if (action.status == ActionStatus.pending &&
        expires != null &&
        expires.isBefore(DateTime.now())) {
      return ActionStatus.expired;
    }
    return action.status;
  }

  String? actionCode(String actionId) => _actionResults[actionId]?.code;

  bool isActionInFlight(String actionId) =>
      _actionsInFlight.contains(actionId);

  /// Thêm món đề xuất vào thực đơn — đường duy nhất thực thi đề xuất.
  Future<void> confirmAction(String actionId) =>
      _decide(actionId, () => _api.confirmAction(actionId));

  Future<void> rejectAction(String actionId) =>
      _decide(actionId, () => _api.rejectAction(actionId));

  Future<void> _decide(
      String actionId, Future<ActionResult> Function() call) async {
    if (_actionsInFlight.contains(actionId)) return;
    runInAction(() => _actionsInFlight.add(actionId));
    try {
      final result = await call();
      runInAction(() => _actionResults[actionId] = result);
    } on ApiException catch (e) {
      final status = switch (e.code) {
        'ERR_ASSISTANT_ACTION_EXPIRED' => ActionStatus.expired,
        _ => ActionStatus.failed,
      };
      runInAction(() =>
          _actionResults[actionId] = ActionResult(status: status, code: e.code));
    } finally {
      runInAction(() => _actionsInFlight.remove(actionId));
    }
  }

  /// `recipeId` của món trên thẻ; `null` khi không mở được (AI/mạng lỗi).
  Future<String?> resolveRecipe(String kbRecipeId) async {
    try {
      return await _api.resolveRecipe(kbRecipeId);
    } on ApiException catch (e) {
      developer.log('Assistant recipe unavailable: ${e.code}',
          name: 'assistant');
      return null;
    }
  }

  /// Đang nạp lịch sử của phiên mở lại.
  bool get isLoadingHistory => _loadingHistory.value;

  /// Mở màn trợ lý. GLOBAL: dùng lại phiên GLOBAL gần nhất nếu cập nhật trong
  /// [reuseWithin] và nạp lịch sử của nó; ngữ cảnh khác luôn là phiên mới, tạo
  /// lười ở câu hỏi đầu. Lỗi khi nạp chỉ làm mất lịch sử cũ — vẫn hỏi được.
  Future<void> open() async {
    final key = _contextKeyOf();
    if (key == null) return;
    _bind(key);
    if (_opened || contextType != AssistantContextType.global || isOffline) {
      return;
    }
    _opened = true;
    runInAction(() => _loadingHistory.value = true);
    try {
      final sessions = await _api.listSessions();
      final cutoff = DateTime.now().subtract(reuseWithin);
      AssistantSessionSummary? recent;
      for (final s in sessions) {
        if (s.contextType == 'GLOBAL' && s.updatedAt.isAfter(cutoff)) {
          recent = s;
          break;
        }
      }
      if (recent == null || _boundKey != key) return;
      final history = await _api.listMessages(recent.id);
      if (_boundKey != key) return;
      _sessionId = recent.id;
      runInAction(() => messages.addAll(history));
    } on ApiException catch (e) {
      developer.log('Assistant history unavailable: ${e.code}',
          name: 'assistant');
    } finally {
      runInAction(() => _loadingHistory.value = false);
    }
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    final key = _contextKeyOf();
    if (key == null) return;
    // Bind TRƯỚC khi xét canSend: đổi ngữ cảnh giữa lúc chờ thì state cũ
    // thuộc phiên trước, không được chặn phiên mới.
    _bind(key);
    if (!canSend(text)) return;
    final message = AssistMessage(role: AssistRole.user, text: text);
    runInAction(() => messages.add(message));
    await _request(message, _newClientTurnId(), _currentStepOf?.call());
  }

  /// "Thử lại" — cùng tin, cùng `clientTurnId`: lượt đã trả lời ở BE thì nhận
  /// lại kết quả cũ, không hỏi AI lần hai. Chỉ khi người dùng bấm.
  Future<void> retry() async {
    final message = _failedMessage;
    final clientTurnId = _failedClientTurnId;
    if (!canRetry ||
        message == null ||
        clientTurnId == null ||
        _contextKeyOf() != _boundKey ||
        isOffline) {
      return;
    }
    await _request(message, clientTurnId, _failedStep);
  }

  Future<void> _request(
      AssistMessage message, String clientTurnId, int? step) async {
    final token = ++_tokenSeq;
    _pendingToken = token;
    _failedMessage = null;
    _failedClientTurnId = null;
    _failedStep = null;
    runInAction(() {
      _state.value = AssistRequestState.sending;
      _errorCode.value = null;
      _errorKind.value = null;
      _error.value = null;
      _slow.value = false;
      _progressTool.value = null;
    });
    _slowTimer?.cancel();
    _slowTimer = Timer(slowAfter, () {
      if (_isCurrent(token)) runInAction(() => _slow.value = true);
    });
    try {
      final sessionId = await _ensureSession();
      if (!_isCurrent(token)) return;
      var status = await _sendWhileInFlight(
          token, sessionId, message.text, clientTurnId, step);
      if (status == null || !_isCurrent(token)) return;
      if (status.status == TurnStatus.pending) {
        status = await _awaitTurn(token, sessionId, status.turnId);
        if (status == null || !_isCurrent(token)) return;
      }
      _finish();
      if (status.status == TurnStatus.answered && status.reply != null) {
        final reply = status.reply!;
        runInAction(() {
          // Retry: tin USER có thể không còn ở cuối → đặt câu trả lời ngay sau.
          final idx = messages.indexOf(message);
          final item = AssistMessage(
              role: AssistRole.assistant, text: reply.answer, reply: reply);
          if (idx < 0 || idx == messages.length - 1) {
            messages.add(item);
          } else {
            messages.insert(idx + 1, item);
          }
          _state.value = AssistRequestState.idle;
          _progressTool.value = null;
        });
      } else {
        _fail(message, clientTurnId, step, status.errorCode ?? 'ERR_UNKNOWN',
            _classifyTurnCode(status.errorCode), null);
      }
    } on ApiException catch (e) {
      if (!_isCurrent(token)) return;
      _finish();
      final kind = _classify(e);
      if (kind == AssistErrorKind.generic) {
        developer.log('Assistant failed: ${e.code}',
            name: 'assistant', error: e);
      }
      _fail(message, clientTurnId, step, e.code, kind, e);
    }
  }

  Future<String> _ensureSession() async {
    final existing = _sessionId;
    if (existing != null) return existing;
    final key = _contextKeyOf()!;
    final planning = contextType == AssistantContextType.planning
        ? _planningOf?.call()
        : null;
    final id = await _api.createSession(
      contextType,
      cookingSessionId:
          contextType == AssistantContextType.cooking ? key : null,
      mealPlanId: planning?.mealPlanId,
      slotId: planning?.slotId,
      horizonDays: planning?.horizonDays,
    );
    if (_boundKey == key) _sessionId = id;
    return id;
  }

  /// `ERR_ASSISTANT_TURN_IN_FLIGHT`: lần gửi trước còn đang chạy ⇒ đợi rồi gửi
  /// lại cùng `clientTurnId` (nhận 200 khi nó xong), không báo lỗi.
  Future<AssistantTurnStatus?> _sendWhileInFlight(int token, String sessionId,
      String text, String clientTurnId, int? step) async {
    final deadline = DateTime.now().add(maxWait);
    while (true) {
      try {
        return await _api.sendMessage(sessionId,
            text: text, clientTurnId: clientTurnId, currentStep: step);
      } on ApiException catch (e) {
        if (e.code != 'ERR_ASSISTANT_TURN_IN_FLIGHT' ||
            DateTime.now().isAfter(deadline)) {
          rethrow;
        }
      }
      await Future<void>.delayed(inFlightRetryDelay);
      if (!_isCurrent(token)) return null;
    }
  }

  /// SSE trước; stream lỗi, im lặng quá [streamSilence] hoặc đóng mà không
  /// có sự kiện cuối ⇒ poll. Trả `null` khi request đã bị thay/huỷ.
  Future<AssistantTurnStatus?> _awaitTurn(
      int token, String sessionId, String turnId) async {
    final streamed = await _followStream(token, sessionId, turnId);
    if (streamed != null || !_isCurrent(token)) return streamed;
    final deadline = DateTime.now().add(maxWait);
    while (_isCurrent(token)) {
      await Future<void>.delayed(pollInterval);
      if (!_isCurrent(token)) return null;
      try {
        final status = await _api.turnStatus(sessionId, turnId);
        if (status.status != TurnStatus.pending) return status;
      } on NetworkException {
        // Mạng chập chờn: thử lại ở nhịp sau, lượt vẫn chạy ở BE.
      }
      if (DateTime.now().isAfter(deadline)) {
        return AssistantTurnStatus(
            turnId: turnId,
            status: TurnStatus.failed,
            errorCode: 'ERR_AI_TIMEOUT');
      }
    }
    return null;
  }

  /// Đọc SSE tới sự kiện cuối. Không `return` trong `await for`: thoát vòng
  /// lặp phải chờ huỷ subscription, mà việc đó chỉ xong khi server đóng
  /// stream — câu trả lời sẽ hiện muộn. Ở đây huỷ mà không chờ.
  ///
  /// Trả `null` khi stream lỗi/im lặng/đóng sớm (bên gọi chuyển sang poll)
  /// hoặc request đã bị thay.
  Future<AssistantTurnStatus?> _followStream(
      int token, String sessionId, String turnId) async {
    final done = Completer<AssistantTurnStatus?>();
    void finish(AssistantTurnStatus? status) {
      if (!done.isCompleted) done.complete(status);
    }

    final sub = _api.turnEvents(sessionId, turnId).timeout(streamSilence).listen(
      (event) {
        if (!_isCurrent(token)) return finish(null);
        switch (event) {
          case TurnProgress(:final tool):
            runInAction(() => _progressTool.value = tool);
          case TurnFinished(:final status):
            finish(status);
        }
      },
      onError: (Object e) {
        developer.log('Assistant stream fell back to polling: $e',
            name: 'assistant');
        finish(null);
      },
      onDone: () => finish(null),
      cancelOnError: true,
    );
    final status = await done.future;
    unawaited(sub.cancel());
    return status;
  }

  void _fail(AssistMessage message, String clientTurnId, int? step, String code,
      AssistErrorKind kind, ApiException? error) {
    _failedMessage = message;
    _failedClientTurnId = clientTurnId;
    _failedStep = step;
    runInAction(() {
      _state.value = AssistRequestState.error;
      _errorCode.value = code;
      _errorKind.value = kind;
      _error.value = error;
      _progressTool.value = null;
      if (kind == AssistErrorKind.unavailable ||
          kind == AssistErrorKind.ended) {
        _disabled.value = true;
      }
    });
    if (kind == AssistErrorKind.rateLimited) {
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(rateLimitCooldown, () {
        if (_disposed || errorKind != AssistErrorKind.rateLimited) return;
        runInAction(() {
          _state.value = AssistRequestState.idle;
          _errorKind.value = null;
          _errorCode.value = null;
        });
      });
    }
  }

  /// Lượt FAILED ở BE: mọi mã đều gửi lại được, trừ hai mã dưới.
  static AssistErrorKind _classifyTurnCode(String? code) => switch (code) {
        'ERR_AI_CONTENT_FILTERED' => AssistErrorKind.filtered,
        'ERR_ASSISTANT_CONTEXT_INVALID' => AssistErrorKind.unavailable,
        'ERR_ASSISTANT_RATE_LIMIT' => AssistErrorKind.rateLimited,
        _ => AssistErrorKind.busy,
      };

  static AssistErrorKind _classify(ApiException e) {
    if (e.code == 'ERR_AI_CONTENT_FILTERED') return AssistErrorKind.filtered;
    if (e.code == 'ERR_ASSISTANT_RATE_LIMIT') return AssistErrorKind.rateLimited;
    if (e.code == 'ERR_ASSISTANT_CONTEXT_INVALID') {
      return AssistErrorKind.unavailable;
    }
    if (e.code == 'ERR_ASSISTANT_SESSION_NOT_FOUND' ||
        e.code == 'ERR_ASSISTANT_SESSION_CLOSED') {
      return AssistErrorKind.ended;
    }
    if (e is NetworkException ||
        e is ServerException ||
        _busyCodes.contains(e.code)) {
      return AssistErrorKind.busy;
    }
    return AssistErrorKind.generic;
  }

  bool _isCurrent(int token) =>
      !_disposed &&
      token == _pendingToken &&
      _boundKey != null &&
      _contextKeyOf() == _boundKey;

  void _finish() {
    _slowTimer?.cancel();
    _slowTimer = null;
    runInAction(() => _slow.value = false);
  }

  void _bind(String key) {
    if (_boundKey == key) return;
    reset();
    _boundKey = key;
  }

  /// Bỏ hội thoại đang hiện + response đang chờ (đổi ngữ cảnh/household,
  /// logout). Lịch sử vẫn ở BE; ngữ cảnh mới tạo phiên mới.
  void reset() {
    _pendingToken = 0;
    _failedMessage = null;
    _failedClientTurnId = null;
    _failedStep = null;
    _boundKey = null;
    _sessionId = null;
    _opened = false;
    _slowTimer?.cancel();
    _slowTimer = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    runInAction(() {
      messages.clear();
      _actionResults.clear();
      _state.value = AssistRequestState.idle;
      _errorCode.value = null;
      _errorKind.value = null;
      _error.value = null;
      _slow.value = false;
      _disabled.value = false;
      _progressTool.value = null;
    });
  }

  void dispose() {
    _disposed = true;
    _scopeReaction?.call();
    _scopeReaction = null;
    _slowTimer?.cancel();
    _slowTimer = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _pendingToken = 0;
    runInAction(() => messages.clear());
  }
}
