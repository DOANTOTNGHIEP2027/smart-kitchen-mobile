import 'dart:async';
import 'dart:developer' as developer;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../app/env_config.dart';
import '../auth/token_storage.dart';
import 'stomp_minimal.dart';
import 'ws_event_envelope.dart';

/// Trạng thái kết nối WebSocket.
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Service quản lý vòng đời WebSocket STOMP cho FE-3 (#49).
///
/// Trách nhiệm:
/// - Kết nối raw WS tới `{wsBaseUrl}/ws` (context-path `/api` không có trong
///   WS URL vì WebSocketConfig.java đăng ký tại `/ws`, servlet context `/api`
///   chỉ áp dụng cho HTTP).
/// - Gửi STOMP CONNECT với Bearer token trong native header.
/// - Subscribe các topic của household.
/// - Reconnect tự động với exponential backoff khi mất kết nối.
/// - Dedupe event theo `eventId` (at-least-once delivery từ backend).
/// - Phát event qua [events] stream để các consumer đăng ký.
/// - Không biết gì về nghiệp vụ inventory/vote/shopping — chỉ là transport.
///
/// **Luồng kết nối (bám redis-cache-ws-baseline.md §3.2):**
/// 1. HTTP GET /ws  Upgrade: websocket  (NOT mang Authorization header)
/// 2. STOMP CONNECT native-header Authorization: Bearer `<access_token>`
/// 3. Server trả CONNECTED
/// 4. Client SUBSCRIBE /topic/household/{id}/inventory (và vote, shopping)
///
/// **Edge cases đã xử lý:**
/// - Token hết hạn (TTL 900s): [TokenStorage] quản lý access token in-memory;
///   service luôn đọc token mới nhất từ [_tokenStorage.accessToken] trước mỗi
///   lần kết nối — nếu DioClient đã silent-refresh thì token sẽ mới.
/// - Mất kết nối: reconnect với backoff 2s → 4s → 8s → ... tối đa 60s.
/// - Duplicate event: [_seenEventIds] giữ N id gần nhất để dedupe.
/// - Stream error bất ngờ từ WebSocket channel: bắt và trigger reconnect.
/// - [dispose] được gọi (app đóng): huỷ mọi timer và stream.
class RealtimeService {
  RealtimeService({
    required TokenStorage tokenStorage,
    String? wsBaseUrl,
  })  : _tokenStorage = tokenStorage,
        _wsBaseUrl = wsBaseUrl ?? _defaultWsBaseUrl();

  final TokenStorage _tokenStorage;
  final String _wsBaseUrl;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;

  final _stateController =
      StreamController<WsConnectionState>.broadcast();
  final _eventController = StreamController<WsEventEnvelope>.broadcast();

  WsConnectionState _state = WsConnectionState.disconnected;
  String? _currentHouseholdId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Set dedupe giữ tối đa [_maxSeen] eventId gần nhất.
  final Set<String> _seenEventIds = <String>{};
  static const int _maxSeen = 500;

  /// Stream trạng thái kết nối — dùng cho UI indicator.
  Stream<WsConnectionState> get connectionState => _stateController.stream;

  /// Stream event nghiệp vụ đã qua dedupe — consumer subscribe để nhận update.
  Stream<WsEventEnvelope> get events => _eventController.stream;

  WsConnectionState get currentState => _state;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Kết nối và subscribe các topic của [householdId].
  /// Nếu đang kết nối với household khác, disconnect trước.
  Future<void> connect(String householdId) async {
    if (_currentHouseholdId == householdId &&
        _state == WsConnectionState.connected) {
      return; // đã connected đúng household, không làm gì
    }
    _currentHouseholdId = householdId;
    _reconnectAttempts = 0;
    await _connect();
  }

  /// Ngắt kết nối và dừng reconnect.
  Future<void> disconnect() async {
    _currentHouseholdId = null;
    _cancelReconnect();
    await _closeChannel(sendDisconnect: true);
    _setState(WsConnectionState.disconnected);
  }

  /// Giải phóng tài nguyên — gọi khi app đóng.
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _eventController.close();
  }

  // ── Private: connection lifecycle ─────────────────────────────────────────

  Future<void> _connect() async {
    final householdId = _currentHouseholdId;
    if (householdId == null) return;

    final token = _tokenStorage.accessToken;
    if (token == null) {
      developer.log(
        'RealtimeService: chưa có access token, bỏ qua kết nối',
        name: 'RealtimeService',
      );
      return;
    }

    _setState(_reconnectAttempts == 0
        ? WsConnectionState.connecting
        : WsConnectionState.reconnecting);

    await _closeChannel(sendDisconnect: false);

    final uri = Uri.parse('$_wsBaseUrl/ws');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
    } catch (e) {
      developer.log(
        'RealtimeService: không kết nối được WS: $e',
        name: 'RealtimeService',
      );
      _scheduleReconnect();
      return;
    }

    // Gửi STOMP CONNECT — token trong native header, không phải HTTP header
    _channel!.sink.add(buildConnect(token));

    _channelSub = _channel!.stream.listen(
      _onMessage,
      onError: _onChannelError,
      onDone: _onChannelDone,
      cancelOnError: false,
    );
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;

    final frame = parseFrame(raw);
    switch (frame) {
      case StompConnected():
        developer.log(
          'RealtimeService: STOMP CONNECTED, subscribing household=$_currentHouseholdId',
          name: 'RealtimeService',
        );
        _reconnectAttempts = 0;
        _setState(WsConnectionState.connected);
        _subscribeHousehold(_currentHouseholdId!);
      case StompMessage():
        _handleStompMessage(frame);
      case StompError():
        developer.log(
          'RealtimeService: STOMP ERROR: ${frame.message}',
          name: 'RealtimeService',
        );
        // Đặc biệt: ERR_WS_UNAUTHORIZED nghĩa là token hết hạn —
        // DioClient sẽ lo silent refresh qua interceptor. Reconnect sau
        // backoff để lần connect kế tiếp dùng token mới.
        _scheduleReconnect();
      case StompUnknown():
        // Heartbeat hoặc frame không nhận ra — bỏ qua
        break;
    }
  }

  void _handleStompMessage(StompMessage frame) {
    final envelope = WsEventEnvelope.tryParse(frame.body);
    if (envelope == null) {
      developer.log(
        'RealtimeService: không parse được WS event body từ ${frame.destination}',
        name: 'RealtimeService',
      );
      return;
    }

    // Dedupe theo eventId (at-least-once từ backend)
    if (_seenEventIds.contains(envelope.eventId)) {
      return;
    }
    if (_seenEventIds.length >= _maxSeen) {
      // Xoá oldest bằng cách remove first — Set giữ insertion order
      _seenEventIds.remove(_seenEventIds.first);
    }
    _seenEventIds.add(envelope.eventId);

    if (!_eventController.isClosed) {
      _eventController.add(envelope);
    }
  }

  void _subscribeHousehold(String householdId) {
    final topics = <String>[
      '/topic/household/$householdId/inventory',
      '/topic/household/$householdId/vote',
      '/topic/household/$householdId/shopping',
    ];
    for (int i = 0; i < topics.length; i++) {
      _channel?.sink.add(buildSubscribe(
        id: 'sub-$i',
        destination: topics[i],
      ));
    }
  }

  void _onChannelError(Object error) {
    developer.log(
      'RealtimeService: WS channel error: $error',
      name: 'RealtimeService',
    );
    _scheduleReconnect();
  }

  void _onChannelDone() {
    developer.log(
      'RealtimeService: WS channel đóng (onDone)',
      name: 'RealtimeService',
    );
    if (_currentHouseholdId != null) {
      _scheduleReconnect();
    } else {
      _setState(WsConnectionState.disconnected);
    }
  }

  // ── Private: reconnect ────────────────────────────────────────────────────

  static const int _maxBackoffSeconds = 60;

  void _scheduleReconnect() {
    if (_currentHouseholdId == null) return; // disconnect() đã được gọi
    _cancelReconnect();

    final delay = Duration(
      seconds: _clamp(
        _pow2(_reconnectAttempts),
        min: 2,
        max: _maxBackoffSeconds,
      ),
    );
    _reconnectAttempts++;

    developer.log(
      'RealtimeService: reconnect sau ${delay.inSeconds}s (attempt=$_reconnectAttempts)',
      name: 'RealtimeService',
    );

    _reconnectTimer = Timer(delay, () {
      if (_currentHouseholdId != null) _connect();
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _closeChannel({required bool sendDisconnect}) async {
    if (sendDisconnect) {
      try {
        _channel?.sink.add(buildDisconnect());
      } catch (_) {
        // Có thể đã đóng rồi — bỏ qua
      }
    }
    await _channelSub?.cancel();
    _channelSub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  // ── Private: helpers ──────────────────────────────────────────────────────

  void _setState(WsConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  static int _pow2(int n) => n <= 0 ? 1 : 1 << n; // 2^n

  static int _clamp(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Build WS URL từ API base URL: `http://host:8080` → `ws://host:8080`.
  /// Context-path `/api` KHÔNG thêm vào đây — WebSocketConfig đăng ký `/ws`
  /// ở servlet root, không phải `/api/ws` (xem `WebSocketConfig.java:47`).
  ///
  /// Tuy nhiên thực tế Spring Boot có `server.servlet.context-path=/api` nên
  /// endpoint thật là `ws://host:8080/api/ws` (Spring tự tiền tố context-path
  /// vào mọi mapping kể cả WS). Xem `redis-cache-ws-baseline.md` §2: "Endpoint
  /// thật (đã tính context-path): ws://{host}:8080/api/ws".
  static String _defaultWsBaseUrl() {
    final api = EnvConfig.apiBaseUrl;
    return api
        .replaceFirst(RegExp(r'^https?'), 'ws')
        .replaceFirst(RegExp(r'/api$'), '');
  }
}
