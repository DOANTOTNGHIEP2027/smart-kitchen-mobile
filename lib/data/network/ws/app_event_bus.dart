import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../auth/token_storage.dart';
import 'stomp_frame.dart';

/// Bus sự kiện realtime dùng chung (FE-4 §7).
///
/// Đóng gói tầng transport STOMP tối thiểu trên `web_socket_channel`. Mọi
/// feature subscribe destination (_inventory, vote, shopping..._) dùng chung
/// một connection này — không ai tự mở WebSocket riêng.
///
/// Bề mặt API cố ý trung tính (không gắn tên inventory) để feature thứ hai
/// tái dụng được (Decision D6/D7 trong inventory-management.md §7).
///
/// **Resilience:** mất kết nối → reconnect exponential backoff (cap 30s).
/// Khi `CONNECTED` lại → tự resubscribe toàn bộ destination đang mở + phát
/// sự kiện `onConnected` để caller biết "vừa (re)connect xong, nên catch-up
/// từ REST" (Fix MEDIUM-1).
class AppEventBus {
  AppEventBus(
    this._tokenStorage, {
    required this.wsUrl,
    WebSocketChannel Function(Uri uri)? channelFactory,
    Duration Function(int attempt)? backoffFor,
  })  : _channelFactory = channelFactory ?? _defaultChannelFactory,
        _backoffFor = backoffFor ?? _defaultBackoff;

  final TokenStorage _tokenStorage;
  final String wsUrl;

  final WebSocketChannel Function(Uri uri) _channelFactory;
  final Duration Function(int attempt) _backoffFor;

  WebSocketChannel? _channel;
  final Map<String, StreamController<Map<String, dynamic>>> _destinationControllers =
      <String, StreamController<Map<String, dynamic>>>{};
  // Non-final để có thể tạo lại sau dispose() — xem _ensureConnected (Fix M4).
  StreamController<void> _connectedController =
      StreamController<void>.broadcast();

  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manuallyClosed = false;

  /// Subscribe một destination STOMP (vd `/topic/household/{id}/inventory`).
  ///
  /// Trả về Stream payload JSON thô của frame MESSAGE — caller tự parse thành
  /// event type cụ thể (vd `InventoryStore.handleWsEvent`). Controller được
  /// tạo lazy và tái dùng cho các subscriber sau trên cùng destination.
  Stream<Map<String, dynamic>> rawEvents(String destination) {
    _ensureConnected();
    return (_destinationControllers[destination] ??=
            StreamController<Map<String, dynamic>>.broadcast())
        .stream;
  }

  /// Phát 1 sự kiện mỗi khi STOMP `CONNECTED` xảy ra (lần đầu HOẶC sau reconnect).
  ///
  /// Tín hiệu duy nhất class expose cho bên ngoài biết "kết nối vừa sẵn sàng
  /// lại" — caller nên listen then catch-up từ REST (Fix MEDIUM-1).
  Stream<void> get onConnected => _connectedController.stream;

  /// Đóng connection + huỷ toàn bộ subscription. Idempotent.
  ///
  /// Sau khi gọi, bus không tự reconnect nữa. Đăng ký lại `rawEvents` sẽ mở
  /// connection mới.
  Future<void> dispose() async {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _channel = null;
    for (final controller in _destinationControllers.values) {
      await controller.close();
    }
    _destinationControllers.clear();
    await _connectedController.close();
  }

  // ── Internal ──────────────────────────────────────────────────────────

  void _ensureConnected() {
    if (_manuallyClosed) {
      // Sink re-open sau dispose: reset cờ, cho phép reconnect.
      _manuallyClosed = false;
    }
    // Fix review M4: `_connectedController` đã close sau dispose() — nếu caller
    // listen lại rawEvents(), tạo broadcast controller mới để `.add()` không
    // throw "Cannot add new events after calling close".
    if (_connectedController.isClosed) {
      _recreateConnectedController();
    }
    if (_channel != null) return;
    unawaited(_connect());
  }

  void _recreateConnectedController() {
    _connectedController = StreamController<void>.broadcast();
  }

  Future<void> _connect() async {
    try {
      final token = _tokenStorage.accessToken;
      final uri = Uri.parse(wsUrl);
      final channel = _channelFactory(uri);
      _channel = channel;
      // Gắn listener TRƯỚC `await ready` để frame do server gửi trong lúc
      // handshake (vd ERROR 401) không bị mất (Fix review M2).
      channel.stream.listen(
        _onFrame,
        onError: (Object error) => _onDisconnected(reason: 'stream error: $error'),
        onDone: () => _onDisconnected(reason: 'stream done'),
      );
      await channel.ready;
      channel.sink.add(
        StompFrame.connect(
          authorizationHeader: 'Bearer $token',
          // STOMP `host` = authority của WS endpoint (Fix review M3).
          host: uri.host.isEmpty ? 'localhost' : uri.host,
        ).encode(),
      );
    } catch (error, stack) {
      developer.log(
        'AppEventBus connect failed, lên lịch reconnect',
        name: 'app_event_bus',
        error: error,
        stackTrace: stack,
      );
      _onDisconnected(reason: 'connect exception: $error');
    }
  }

  void _onFrame(dynamic raw) {
    final StompFrame frame;
    try {
      frame = StompFrame.decode(raw as String);
    } catch (error) {
      developer.log(
        'STOMP decode failed — bỏ qua frame',
        name: 'app_event_bus',
        error: error,
      );
      return;
    }
    switch (frame.command) {
      case 'CONNECTED':
        _reconnectAttempt = 0;
        // Resubscribe toàn bộ destination đang mở (STOMP không giữ subscribe
        // qua các connection — phải gửi SUBSCRIBE lại mỗi khi (re)connect).
        for (final destination in _destinationControllers.keys) {
          _channel?.sink.add(
            StompFrame.subscribe(destination: destination, id: destination).encode(),
          );
        }
        // Phát onConnected cho caller catch-up (Fix MEDIUM-1).
        _connectedController.add(null);
      case 'MESSAGE':
        final destination = frame.headers['destination'];
        if (destination == null) {
          // BE violation contract — không crash, chỉ log để debug (Fix L7).
          developer.log(
            'STOMP MESSAGE thiếu header destination — bỏ qua frame',
            name: 'app_event_bus',
          );
          return;
        }
        try {
          final body = jsonDecode(frame.body) as Map<String, dynamic>;
          _destinationControllers[destination]?.add(body);
        } catch (error) {
          developer.log(
            'STOMP MESSAGE parse JSON thất bại cho destination=$destination',
            name: 'app_event_bus',
            error: error,
          );
        }
      case 'ERROR':
        developer.log(
          'STOMP ERROR frame: ${frame.body}',
          name: 'app_event_bus',
        );
      default:
        break;
    }
  }

  void _onDisconnected({String? reason}) {
    _channel = null;
    if (_manuallyClosed) return;
    developer.log(
      'AppEventBus đứt kết nối (reason: $reason) — lên lịch reconnect',
      name: 'app_event_bus',
    );
    final delay = _backoffFor(_reconnectAttempt);
    _reconnectAttempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _ensureConnected);
  }

  static WebSocketChannel _defaultChannelFactory(Uri uri) =>
      WebSocketChannel.connect(uri);

  /// Exponential backoff cap 30s — spec §7 line 459.
  static Duration _defaultBackoff(int attempt) =>
      Duration(seconds: math.min(30, math.pow(2, attempt).toInt()));
}
