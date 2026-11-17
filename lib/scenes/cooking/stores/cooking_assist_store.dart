import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../data/cooking_assist_api.dart';
import '../domain/cooking_assist.dart';

enum AssistRequestState { idle, sending, error }

/// Cách sheet hiển thị lỗi lần gửi gần nhất (§14.5).
enum AssistErrorKind {
  /// 502/503/504/429/timeout/mất kết nối giữa chừng — có "Thử lại".
  busy,

  /// 422 `ERR_AI_CONTENT_FILTERED` — KHÔNG có "Thử lại".
  filtered,

  /// 409 `ERR_ASSIST_CONTEXT_UNAVAILABLE` — tắt trợ lý cho hết phiên.
  unavailable,

  /// 409 `ERR_SESSION_ALREADY_ENDED` / 404 — đóng sheet, ẩn FAB.
  ended,

  /// 400/403/khác — câu báo chung.
  generic,
}

/// Trợ lý nấu ăn (FE design §14.2–§14.3, #157).
///
/// Store RIÊNG, chỉ ĐỌC màn nấu qua callback — lỗi/chờ ở đây không bao giờ
/// đổi `phase`, không chặn timer/chuyển bước/complete/abandon (Guard §14.7.1).
/// MobX thủ công như `CookingSessionStore` (không codegen).
class CookingAssistStore {
  CookingAssistStore({
    required CookingAssistApi api,
    required String? Function() sessionId,
    required int? Function() viewedStepNumber,
    required bool Function() isOnline,
    String? Function()? accountScope,
    this.slowAfter = const Duration(seconds: 5),
  })  : _api = api,
        _sessionIdOf = sessionId,
        _viewedStepNumberOf = viewedStepNumber,
        _isOnline = isOnline {
    // Đổi tài khoản/household (logout cũng đổi) → xoá history ngay (§14.2).
    if (accountScope != null) {
      _scopeReaction = reaction<String?>((_) => accountScope(), (_) => reset());
    }
  }

  static const int maxMessageLength = 500;
  static const int maxHistoryItems = 4;
  static const int maxHistoryTextLength = 1000;

  static const Set<String> _busyCodes = <String>{
    'ERR_AI_TIMEOUT',
    'ERR_AI_SERVICE_DOWN',
    'ERR_AI_INVALID_OUTPUT',
    'ERR_AI_RATE_LIMIT',
    'ERR_NETWORK',
    // 4xx không envelope (vd. 429 từ gateway) — interceptor không biết mã.
    'ERR_UNKNOWN',
  };

  final CookingAssistApi _api;
  final String? Function() _sessionIdOf;
  final int? Function() _viewedStepNumberOf;
  final bool Function() _isOnline;
  final Duration slowAfter;
  ReactionDisposer? _scopeReaction;

  /// Token của request đang chờ — response mang token khác bị bỏ (§14.3.4).
  int _pendingToken = 0;
  int _tokenSeq = 0;
  String? _pendingSessionId;

  /// Session sở hữu `messages` hiện tại — history không lẫn giữa các phiên.
  String? _boundSessionId;
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

  /// Tin USER của lần gửi lỗi — "Thử lại" gửi lại đúng tin này.
  AssistMessage? _failedMessage;

  /// `viewedStep` lúc BẤM GỬI tin lỗi — "Thử lại" giữ đúng ngữ cảnh đó dù
  /// người dùng đã chuyển sang bước khác (§14.2).
  int? _failedViewedStep;

  AssistRequestState get state => _state.value;
  String? get errorCode => _errorCode.value;
  AssistErrorKind? get errorKind => _errorKind.value;
  ApiException? get error => _error.value;
  bool get isSending => !_isStale && state == AssistRequestState.sending;

  /// "Câu hỏi này cần thêm chút thời gian" — sau [slowAfter] vẫn đang gửi.
  bool get isSlow => _slow.value;

  /// FAB ẩn + không gửi nữa cho hết phiên (409/404).
  bool get isDisabled => !_isStale && _disabled.value;

  /// Session hiện tại khác session sở hữu hội thoại → state cũ (đang gửi/
  /// đã tắt) thuộc phiên trước, không được chặn phiên mới.
  bool get _isStale =>
      _boundSessionId != null && _sessionIdOf() != _boundSessionId;
  bool get isOffline => !_isOnline();
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
        !isOffline &&
        _viewedStepNumberOf() != null;
  }

  /// `chatHistory` gửi lên: ≤4 tin GẦN NHẤT, chỉ từ cặp USER→ASSISTANT thành
  /// công, cũ → mới. Tin lỗi và câu đang gửi KHÔNG vào (§14.2).
  List<ChatTurn> chatHistory() => _historyOf(messages);

  static List<ChatTurn> _historyOf(List<AssistMessage> list) {
    final turns = <ChatTurn>[];
    for (var i = 0; i + 1 < list.length; i++) {
      final q = list[i];
      final a = list[i + 1];
      if (q.role == AssistRole.user && a.role == AssistRole.assistant) {
        turns
          ..add(ChatTurn(role: AssistRole.user, text: _clip(q.text)))
          ..add(ChatTurn(role: AssistRole.assistant, text: _clip(a.text)));
        i++;
      }
    }
    return turns.length <= maxHistoryItems
        ? turns
        : turns.sublist(turns.length - maxHistoryItems);
  }

  static String _clip(String text) => text.length <= maxHistoryTextLength
      ? text
      : text.substring(0, maxHistoryTextLength);

  Future<void> send(String raw) async {
    final text = raw.trim();
    final sessionId = _sessionIdOf();
    if (sessionId == null) return;
    // Bind TRƯỚC khi xét canSend: đổi session giữa lúc chờ thì state cũ
    // (sending/lỗi/tắt) thuộc phiên trước, không được chặn phiên mới.
    _bindSession(sessionId);
    if (!canSend(text)) return;
    // Câu mới thay câu lỗi cũ: tin lỗi vẫn hiển thị nhưng không còn retry.
    final message = AssistMessage(role: AssistRole.user, text: text);
    final history = chatHistory();
    runInAction(() => messages.add(message));
    final viewedStep = _viewedStepNumberOf();
    if (viewedStep == null) return;
    await _request(sessionId, message, viewedStep, history);
  }

  /// "Thử lại" — gửi lại ĐÚNG text cũ, không thêm tin USER trùng. Mỗi lần
  /// thử lại là request mới, chỉ khi người dùng bấm (§14.3).
  Future<void> retry() async {
    final message = _failedMessage;
    final viewedStep = _failedViewedStep;
    final sessionId = _sessionIdOf();
    if (!canRetry ||
        message == null ||
        sessionId == null ||
        sessionId != _boundSessionId ||
        isOffline ||
        viewedStep == null) {
      return;
    }
    // History lấy từ các tin TRƯỚC tin lỗi — đúng ngữ cảnh lúc hỏi.
    final idx = messages.indexOf(message);
    final before = idx < 0 ? messages.length : idx;
    await _request(sessionId, message, viewedStep,
        _historyOf(messages.sublist(0, before)));
  }

  Future<void> _request(
    String sessionId,
    AssistMessage message,
    int viewedStep,
    List<ChatTurn> history,
  ) async {
    final token = ++_tokenSeq;
    _pendingToken = token;
    _pendingSessionId = sessionId;
    _failedMessage = null;
    _failedViewedStep = null;
    runInAction(() {
      _state.value = AssistRequestState.sending;
      _errorCode.value = null;
      _errorKind.value = null;
      _error.value = null;
      _slow.value = false;
    });
    _slowTimer?.cancel();
    _slowTimer = Timer(slowAfter, () {
      if (_isCurrent(token, sessionId)) runInAction(() => _slow.value = true);
    });
    try {
      final data = await _api.ask(
        sessionId,
        message: message.text,
        viewedStep: viewedStep,
        chatHistory: history,
      );
      if (!_isCurrent(token, sessionId)) return;
      _finish();
      runInAction(() {
        // Retry: tin USER đã ở cuối danh sách hoặc bị tin khác chen sau → đặt
        // câu trả lời ngay sau đúng tin USER của nó.
        final idx = messages.indexOf(message);
        final reply = AssistMessage(
            role: AssistRole.assistant, text: data.answer, data: data);
        if (idx < 0 || idx == messages.length - 1) {
          messages.add(reply);
        } else {
          messages.insert(idx + 1, reply);
        }
        _state.value = AssistRequestState.idle;
      });
    } on ApiException catch (e) {
      if (!_isCurrent(token, sessionId)) return;
      _finish();
      final kind = _classify(e);
      if (kind == AssistErrorKind.generic) {
        // Thiết kế yêu cầu log Sentry cho 400; repo chưa có Sentry.
        developer.log('Cooking assist failed: ${e.code}',
            name: 'cooking.assist', error: e);
      }
      _failedMessage = message;
      _failedViewedStep = viewedStep;
      runInAction(() {
        _state.value = AssistRequestState.error;
        _errorCode.value = e.code;
        _errorKind.value = kind;
        _error.value = e;
        if (kind == AssistErrorKind.unavailable ||
            kind == AssistErrorKind.ended) {
          _disabled.value = true;
        }
      });
    }
  }

  static AssistErrorKind _classify(ApiException e) {
    if (e.code == 'ERR_AI_CONTENT_FILTERED') return AssistErrorKind.filtered;
    if (e.code == 'ERR_ASSIST_CONTEXT_UNAVAILABLE') {
      return AssistErrorKind.unavailable;
    }
    if (e.code == 'ERR_SESSION_ALREADY_ENDED' ||
        e.code == 'ERR_SESSION_NOT_FOUND') {
      return AssistErrorKind.ended;
    }
    if (e is NetworkException ||
        e is ServerException ||
        _busyCodes.contains(e.code)) {
      return AssistErrorKind.busy;
    }
    return AssistErrorKind.generic;
  }

  bool _isCurrent(int token, String sessionId) =>
      !_disposed &&
      token == _pendingToken &&
      sessionId == _pendingSessionId &&
      _sessionIdOf() == sessionId;

  void _finish() {
    _slowTimer?.cancel();
    _slowTimer = null;
    runInAction(() => _slow.value = false);
  }

  void _bindSession(String sessionId) {
    if (_boundSessionId == sessionId) return;
    reset();
    _boundSessionId = sessionId;
  }

  /// Xoá toàn bộ hội thoại + bỏ response đang chờ (đổi session/household,
  /// logout). History chỉ sống trong bộ nhớ.
  void reset() {
    _pendingToken = 0;
    _pendingSessionId = null;
    _failedMessage = null;
    _failedViewedStep = null;
    _boundSessionId = null;
    _slowTimer?.cancel();
    _slowTimer = null;
    runInAction(() {
      messages.clear();
      _state.value = AssistRequestState.idle;
      _errorCode.value = null;
      _errorKind.value = null;
      _error.value = null;
      _slow.value = false;
      _disabled.value = false;
    });
  }

  void dispose() {
    _disposed = true;
    _scopeReaction?.call();
    _scopeReaction = null;
    _slowTimer?.cancel();
    _slowTimer = null;
    _pendingToken = 0;
    runInAction(() => messages.clear());
  }
}
