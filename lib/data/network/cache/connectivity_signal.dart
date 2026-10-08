import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Tín hiệu online/offline nhẹ (image-caching-strategy §5.3) — OPTIMIZATION,
/// KHÔNG phải correctness requirement (Guard #7).
///
/// Dùng đúng package `connectivity_plus` (đã là quy ước dự án) — KHÔNG import
/// thẳng `ConnectivityGate` từ module `ai_runtime` vào `lib/widgets/` (Guard #8:
/// phân tầng widget dùng chung không được phụ thuộc ngược vào feature module).
class ConnectivitySignal {
  ConnectivitySignal(this._connectivity) {
    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Optimistic default TRƯỚC lần check đầu — tránh flash "offline" lúc mở app.
  bool isOnline = true;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _onChanged(results);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onChanged(List<ConnectivityResult> results) {
    isOnline = !(results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none));
  }
}