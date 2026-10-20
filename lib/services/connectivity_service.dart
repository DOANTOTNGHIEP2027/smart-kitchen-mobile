import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobx/mobx.dart';

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

  /// Instance `Connectivity` dùng chung — tránh tạo thêm listener trùng
  /// (ConnectivitySignal trong image-caching tái sử dụng instance này).
  Connectivity get instance => _connectivity;

  final _restoredController = StreamController<void>.broadcast();

  /// Stream phát một lần mỗi khi mạng được khôi phục (từ offline → online).
  /// Consumer (ví dụ RealtimeStore) đăng ký để trigger reconnect/sync.
  Stream<void> get onConnectivityRestored => _restoredController.stream;

  bool get isListening => _sub != null;

  /// `null` = chưa biết (trước [init]) — coi như online để không khoá nhầm UI;
  /// thao tác vẫn kiểm [isOnline] lúc bấm.
  final Observable<bool?> _online = Observable<bool?>(null);

  /// Trạng thái mạng REACTIVE cho UI (đọc trong `Observer`) — vd. khoá chip
  /// giao việc khi offline (shopping-list-screen §9.5, OD-21).
  bool get isOnlineNow => _online.value ?? true;

  /// Kiểm tra online tại thời điểm gọi — dùng cho InventoryFormStore quyết
  /// định optimistic-then-enqueue vs optimistic-then-API. Lưu ý: đây là best
  /// effort vì `connectivity_plus` không guarantee internet thật — chỉ loại
  /// kết nối. Đủ để chặn các thao tác chắc chắn thất bại khi `none`.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    final online = !_isOffline(results);
    // Đồng bộ lại [isOnlineNow] — stream có thể lỡ sự kiện (vd. app resume),
    // không được để UI khoá vĩnh viễn theo trạng thái cũ.
    runInAction(() => _online.value = online);
    // Lỡ sự kiện "mất mạng" thì vẫn phải ghi nhận, để lần có mạng lại kế tiếp
    // phát [onConnectivityRestored]. Không hạ cờ khi online — lần khôi phục bị
    // lỡ vẫn được phát ở sự kiện stream tiếp theo.
    if (!online) _wasOffline = true;
    return online;
  }

  /// Bắt đầu lắng nghe thay đổi kết nối.
  Future<void> init() async {
    // Kiểm tra trạng thái hiện tại
    final results = await _connectivity.checkConnectivity();
    _wasOffline = _isOffline(results);
    runInAction(() => _online.value = !_wasOffline);

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
    runInAction(() => _online.value = !offline);
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }
}
