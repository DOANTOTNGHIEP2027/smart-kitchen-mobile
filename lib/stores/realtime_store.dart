import 'dart:async';

import 'package:mobx/mobx.dart';

import '../data/realtime/realtime_service.dart';
import '../data/realtime/ws_event_envelope.dart';
import '../services/connectivity_service.dart';
import 'session_store.dart';

/// MobX store quản lý trạng thái realtime WebSocket (FE-3 #49).
///
/// Đóng vai trò điều phối giữa [RealtimeService] (transport) và phần còn lại
/// của app (UI, các feature store). Feature store (ví dụ InventoryStore ở FE-4)
/// subscribe [events] để nhận update realtime; không cần biết WS details.
///
/// **Lifecycle:**
/// - Được tạo trong `bootstrap()` và đăng ký permanent.
/// - `init()` gọi sau khi [SessionStore] bootstrap xong — nếu user đã auth thì
///   connect ngay, nếu không thì chờ [onAuthChanged].
/// - `onAuthChanged()` được gọi bởi [SessionStore] (hoặc auth store) sau login/logout.
/// - `dispose()` được gọi khi app đóng.
///
/// Không dùng codegen MobX (`part '*.g.dart'`) vì chỉ cần 1 observable đơn giản
/// — bám pattern thủ công hiện tại của project.
class RealtimeStore {
  RealtimeStore({
    required RealtimeService realtimeService,
    required ConnectivityService connectivityService,
    required SessionStore sessionStore,
  })  : _service = realtimeService,
        _connectivity = connectivityService,
        _session = sessionStore;

  final RealtimeService _service;
  final ConnectivityService _connectivity;
  final SessionStore _session;

  final Observable<WsConnectionState> _connectionState =
      Observable<WsConnectionState>(WsConnectionState.disconnected);
  final Observable<WsEventEnvelope?> _lastEvent =
      Observable<WsEventEnvelope?>(null);

  StreamSubscription<WsConnectionState>? _stateSub;
  StreamSubscription<WsEventEnvelope>? _eventSub;
  StreamSubscription<void>? _connectivitySub;

  /// Trạng thái kết nối WS hiện tại — dùng cho UI indicator.
  WsConnectionState get connectionState => _connectionState.value;

  /// Stream event nhận được — feature store subscribe để cập nhật dữ liệu.
  Stream<WsEventEnvelope> get events => _service.events;

  /// Event cuối cùng nhận được (null nếu chưa có) — dùng để debug/test.
  WsEventEnvelope? get lastEvent => _lastEvent.value;

  /// Khởi tạo: bắt đầu lắng nghe connectivity và kết nối nếu đã có household.
  Future<void> init() async {
    // Lắng nghe trạng thái connection từ service
    _stateSub = _service.connectionState.listen((state) {
      runInAction(() => _connectionState.value = state);
    });

    // Forward event để các store khác subscribe qua [events]
    _eventSub = _service.events.listen((event) {
      runInAction(() => _lastEvent.value = event);
    });

    // Reconnect khi mạng khôi phục
    _connectivitySub = _connectivity.onConnectivityRestored.listen((_) {
      final householdId = _session.householdId;
      if (householdId != null &&
          _connectionState.value != WsConnectionState.connected) {
        _service.connect(householdId);
      }
    });

    // Connect ngay nếu đã authenticated và có household
    final householdId = _session.householdId;
    if (_session.isAuthenticated && householdId != null) {
      await _service.connect(householdId);
    }
  }

  /// Gọi khi auth state thay đổi (login / logout / household joined).
  Future<void> onAuthChanged() async {
    final householdId = _session.householdId;
    if (_session.isAuthenticated && householdId != null) {
      await _service.connect(householdId);
    } else {
      await _service.disconnect();
    }
  }

  Future<void> dispose() async {
    await _stateSub?.cancel();
    await _eventSub?.cancel();
    await _connectivitySub?.cancel();
    await _service.dispose();
  }
}
