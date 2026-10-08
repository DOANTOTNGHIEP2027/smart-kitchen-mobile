import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/realtime/realtime_service.dart';

/// Tái hiện bug FE: endpoint WebSocket thật là `/api/ws` (context-path `/api`
/// của Spring Boot được tiền tố vào cả mapping `/ws`), nhưng base URL cũ loại
/// bỏ `/api` và kết nối vào `ws://host:8080/ws` — handshake 404 nên toàn bộ
/// real-time (inventory/vote/shopping) chết. Contract nguồn:
/// `redis-cache-ws-baseline.md` §6 — URL = `ws://{host}:8080/api/ws`.
void main() {
  group('RealtimeService.wsBaseUrlFrom', () {
    test('host không sẵn context-path → thêm đủ `/api` (endpoint `/api/ws`)', () {
      expect(RealtimeService.wsBaseUrlFrom('http://localhost:8080'),
          'ws://localhost:8080/api');
    });

    test('giữ nguyên context-path và không nhân đôi', () {
      expect(RealtimeService.wsBaseUrlFrom('https://api.example.com/api'),
          'ws://api.example.com/api');
    });

    test('bỏ trailing slash nhưng vẫn giữ context-path', () {
      expect(RealtimeService.wsBaseUrlFrom('https://host:8443/'),
          'ws://host:8443/api');
    });
  });
}