import '../../../services/connectivity_service.dart';

/// Nguồn DUY NHẤT để quyết định chuyển sang on-device (§8, D4). Bọc
/// [ConnectivityService] dùng chung — không tạo listener `connectivity_plus`
/// thứ hai.
///
/// Giới hạn đã biết (D8): chỉ biết interface (Wi-Fi/cellular) có associate
/// hay không, không verify internet thật (captive portal). Chấp nhận ở v1.
class ConnectivityGate {
  ConnectivityGate(this._connectivity);

  final ConnectivityService _connectivity;

  Future<bool> isDeviceOffline() async {
    try {
      return !await _connectivity.isOnline();
    } catch (_) {
      // Không xác định được → coi là online: thà hiện lỗi cloud thật còn hơn
      // che một outage bằng UX "chế độ offline" (Guard #1).
      return false;
    }
  }
}
