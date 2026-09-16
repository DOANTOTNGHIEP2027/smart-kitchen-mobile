# Code Review — FE-4 Drift + WebSocket baseline

- **Branch:** `feature/50-49_drift-websocket-infra`
- **Base:** `origin/main` (commit `7e90417`)
- **Head:** `7581185` (gộp thêm `b8305b5` FE-3 polish)
- **Reviewer:** OpenCode (lens `coding-fe-reviewer` SKILL.md)
- **Ngày:** 2026-09-16
- **Spec nguồn:** `D:/DO_AN/ai-native/docs/design/frontend/inventory-management.md` §7 +
  `D:/DO_AN/ai-native/docs/design/backend-server/redis-cache-ws-baseline.md` (Transport & Handshake)

## Scope review

Phần FE-4 mới (2 file production + 2 file test + bootstrap/env_config diff):
- `lib/data/network/ws/stomp_frame.dart`
- `lib/data/network/ws/app_event_bus.dart`
- `lib/app/bootstrap.dart` (diff: register AppEventBus + skip Firebase web)
- `lib/app/env_config.dart` (diff: thêm wsUrl)
- `test/data/network/ws/stomp_frame_test.dart`
- `test/data/network/ws/app_event_bus_test.dart`
- `pubspec.yaml` (diff: deps)

Phần `b8305b5` (FE-3 polish + web/windows scaffolding) được review riêng nếu
cần — nó thuộc commit trước, không phải scope FE-4.

## Findings

### HIGH

#### H1 — `EnvConfig.wsUrl` mặc định sai path thật của BE

- **File:** `lib/app/env_config.dart:23`
- **Bằng chứng:** Default `ws://localhost:8080/ws`. Spec BE
  `redis-cache-ws-baseline.md:834` quy định URL thật là `ws://{host}:8080/api/ws`
  (có prefix `/api` vì `server.servlet.context-path=/api`).
- **Rủi ro:** Khi FE-5/FE-6/FE-7 wire tới BE thật, connection sẽ 404 ngay ở
  HTTP upgrade. Hiện không bắt được vì FE-4 mới chạy demo. Sẽ mất 30 phút debug
  nếu phát hiện muộn.
- **Sửa nhỏ nhất:** Đổi default thành `ws://localhost:8080/api/ws`. Trong file
  comment đã dẫn đúng rồi, chỉ cần align giá trị.

### MEDIUM

#### M2 — `_connect()` gán `_channel` trước khi `ready` complete → race khi reconnect

- **File:** `lib/data/network/ws/app_event_bus.dart:97-98`
- **Code:**
  ```dart
  _channel = _channelFactory(Uri.parse(wsUrl));
  await _channel!.ready;
  ```
- **Rủi ro:** Nếu `ready` future throw (network down, server refuse), `_channel`
  đã bị gán giá trị non-null nhưng connection rỗng. `catch` bên dưới có set lại
  null không? **Có** — vì `catch` gọi `_onDisconnected` set `_channel = null`.
  Nhưng còn một khúc tinh tế hơn: trong lúc `await _channel!.ready`, listener
  (`onError`/`onDone`) chưa được gắn (vì `.listen` nằm sau lệnh `await`). Nếu
  server reject trong khoảng đó (vd 401), frame ERROR bị mất — không có listener
  nào nhận.
- **Sửa nhỏ nhất:** Đảo thứ tự: `listen` trước, `await ready` sau. Hoặc gắn
  `onError`/`onDone` cho `stream` không phụ thuộc `ready`.
- **Ghi chú:** Test hiện tại không cover case này. Khi fix cần thêm test.

#### M3 — `host` header trong `StompFrame.connect()` hardcode `'localhost'`

- **File:** `lib/data/network/ws/stomp_frame.dart:41`
- **Code:**
  ```dart
  'host': 'localhost',
  ```
- **Bằng chứng:** STOMP 1.2 RFC bắt buộc header `host` (virtual host). Spec FE
  mẫu (`inventory-management.md:431`) không pass params vào. Default `localhost`
  sai cho mọi môi trường không phải local.
- **Rủi ro:** Production deploy với domain khác → server STOMP có thể reject
  CONNECT (tuỳ cấu hình server). Hiện demo không vấp vì demo không có WS thật.
- **Sửa nhỏ nhất:** Thêm param `host` vào factory  default rút từ `wsUrl`.

#### M4 — `dispose()` xong rồi listen lại crash vì `_connectedController` đã đóng

- **File:** `lib/data/network/ws/app_event_bus.dart:70-81` + 85-92
- **Code:**
  ```dart
  Future<void> dispose() async {
    _manuallyClosed = true;
    // ... đóng hết ...
  }
  void _ensureConnected() {
    if (_manuallyClosed) {
      _manuallyClosed = false;  // ← reset
    }
    ...
  }
  ```
- **Rủi ro:** Sau `dispose()`, `onConnected` stream và các `rawEvents`
  controller **đã đóng** (`_connectedController.close()` + clear map). Nếu
  caller gọi `rawEvents()` lại, `_ensureConnected` reset cờ → kết nối lại,
  _nhưng_ `_connectedController` đã closed → `.add(null)` trong `_onFrame`
  branch `CONNECTED` sẽ throw "Cannot add new events after calling close" → crash.
- **Sửa nhỏ nhất:** `dispose()` nên tạo lại `_connectedController` + clear map
  (đã clear rồi), hoặc cấm hoàn toàn post-dispose use và document rõ. Đảm bảo
  có test "dispose rồi listen lại" cover.

### LOW

#### L5 — `unawaited` helper trùng lặp với `dart:async` SDK

- **File:** `lib/data/network/ws/app_event_bus.dart:186-189`
- **Code:**
  ```dart
  /// Helper nhỏ — `unawaited` chỉ có từ Dart 3.x, giữ backward compat.
  void unawaited(Future<void>? future) {
    // no-op
  }
  ```
- **Bằng chứng:** `dart:async` đã export `unawaited` từ Dart 2.15+ (2021).
  Comment của chính hàm ghi "chỉ có từ Dart 3.x" — **sai về mặt lịch sử**. SDK
  constraint `sdk: '>=3.6.0 <4.0.0'` đảm bảo `dart:async` có `unawaited`.
- **Sửa nhỏ nhất:** Xoá hàm custom (dòng 186-189), dùng `unawaited(...)` của
  SDK. File đã `import 'dart:async'` ở line 1 rồi. Hiện helper local che khuất
  symbol SDK — `unawaited(_connect())` đang resolve về local no-op thay vì SDK.
  Kết quả runtime giống nhau (cả hai đều no-op discard Future) nhưng aerodrom
  dễ gây nhầm cho dev sau.

#### L6 — Test app_event_bus_test không cover case `ready` throw

- **File:** `test/data/network/ws/app_event_bus_test.dart`
- **Bằng chứng:** `_FakeChannel.ready` mặc định complete thành công. Không
  có test cho case `ready` throw (server refuse) →` _onDisconnected` path
  trong `catch` không được verify.
- **Sửa nhỏ nhất:** Thêm test `_FakeChannel.isReady = false` rồi verify
  reconnect timer được lên lịch.

#### L7 — ` MESSAGE parse JSON` không log destination/khi destination thiếu chỉ im

- **File:** `lib/data/network/ws/app_event_bus.dart:142-154`
- **Rủi ro:** Nếu server gửi MESSAGE thiếu header `destination` (violation
  contract), code `return` im lặng. Trong spec `inventory-core.md` destination
  luôn có, nhưng nếu BE bug thì FE không có dấu vết.
- **Sửa nhỏ nhất:** Log warning khi destination null. Not a bug, debug aid.

## Residual risks (không fix tại FE-4)

1. **STOMP re-auth giữa chừng access token hết hạn** — Open question Q4 trong
   spec, đã ghi trong PR body, không fix ở FE-4.
2. **`connectivity_plus` thêm vào pubspec nhưng chưa được dùng.**  Sẽ wire làm
   nguồn trigger thứ hai cho `SyncQueueDrainer.drain()` ở FE-5 (§11), hiện là
   "pre-install để FE-5 không phải đụng pubspec". Acceptable nhưng cần nhớ.
3. **Drift `schemaVersion` vẫn = 1**, sẽ bump ở FE-5 khi thêm table
   `inventory_items` + `sync_queue`. Migration baseline thực sự nằm ở FE-5.
4. **Demo (DEMO_MODE) chưa có transport WS giả lập** — FE-4 không sinh UI nên
   không có gì để demo cả. Khi FE-5 (inventory) wire vào, demo WS mới cần.

## Validation gaps

- Không chạy app thật (web) để verify STOMP tới BE thật  BE chưa có endpoint
  /api/ws chạy ở local lúc review.
- Không test load (nhiều subscriber đồng thời trên cùng destination).

## Summary

| Severity | Count |
|---|---|
| BLOCKER | 0 |
| HIGH | 1 (H1 wsUrl sai path) |
| MEDIUM | 3 (M2 race, M3 host, M4 dispose) |
| LOW | 3 (L5-L7) |

**Khuyến nghị:** Fix H1 + M4 (blocker tri-enn khi FE-5 wire vào BE + dispose
race) trước khi merge. M2/M3 có thể fix cùng lúc không tốn thêm bao nhiêu công.
L5-L7 nice-to-have.

## Suggested next prompt

`/fix reports/fe-4/code-review-20260916_v1.md`
