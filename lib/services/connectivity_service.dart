import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service detect trạng thái mạng online/offline (FE-3 #49).
///
/// Dùng `connectivity_plus` để lắng nghe thay đổi kết nối và expose stream
/// [onConnectivityRestored] cho các consumer cần sync khi có mạng lại.
///
/// **Lưu ý quan trọng:** `connectivity_plus` trả về loại kết nối (WiFi/mobile)
/// chứ không guarantee có internet thật. Tuy nhiên đây là best effort — đủ để
/// trigger WS reconnect và sync queue khi mạng được phục hồi.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _wasOffline = false;

  final _restoredController = StreamController<void>.broadcast();

  /// Stream phát một lần mỗi khi mạng được khôi phục (từ offline → online).
  /// Consumer (ví dụ RealtimeStore) đăng ký để trigger reconnect/sync.
  Stream<void> get onConnectivityRestored => _restoredController.stream;

  bool get isListening => _sub != null;

  /// Bắt đầu lắng nghe thay đổi kết nối.
  Future<void> init() async {
    // Kiểm tra trạng thái hiện tại
    final results = await _connectivity.checkConnectivity();
    _wasOffline = _isOffline(results);

    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
    developer.log(
      'ConnectivityService: init, offline=$_wasOffline',
      name: 'Connectivity',
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _restoredController.close();
  }

  void _onChanged(List<ConnectivityResult> results) {
    final offline = _isOffline(results);
    developer.log(
      'ConnectivityService: results=$results, offline=$offline, wasOffline=$_wasOffline',
      name: 'Connectivity',
    );

    if (_wasOffline && !offline) {
      // Mạng vừa được khôi phục
      developer.log(
        'ConnectivityService: mạng khôi phục — phát onConnectivityRestored',
        name: 'Connectivity',
      );
      if (!_restoredController.isClosed) {
        _restoredController.add(null);
      }
    }
    _wasOffline = offline;
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }
}
