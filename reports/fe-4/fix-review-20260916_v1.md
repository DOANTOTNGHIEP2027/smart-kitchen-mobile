# Fix Report — FE-4 Drift + WebSocket baseline

- **Branch:** `feature/50-49_drift-websocket-infra`
- **Review report nguồn:** `reports/fe-4/code-review-20260916_v1.md`
- **Ngày fix:** 2026-09-16
- **Skill áp dụng:** `coding-fe-fixer/SKILL.md`

## Finding-to-change matrix

| ID | Severity | Accept | File bị tác động | Cách verify |
|---|---|---|---|---|
| H1 | HIGH | ✅ accepted | `lib/app/env_config.dart` | Đọc default wsUrl = `/api/ws` |
| M2 | MEDIUM | ✅ accepted | `lib/data/network/ws/app_event_bus.dart` | Test mới `M2: ready throw → reconnect` |
| M3 | MEDIUM | ✅ accepted | `lib/data/network/ws/stomp_frame.dart` + `app_event_bus.dart` | CONNECT frame có `host` extract từ uri |
| M4 | MEDIUM | ✅ accepted | `lib/data/network/ws/app_event_bus.dart` | Test mới `M4: dispose → listen lại không crash` |
| L5 | LOW | ✅ accepted | `lib/data/network/ws/app_event_bus.dart` | `flutter analyze` 0 issue |
| L6 | LOW | ✅ accepted (gộp vào M2) | `test/.../app_event_bus_test.dart` | như M2 |
| L7 | LOW | ✅ accepted | `lib/data/network/ws/app_event_bus.dart` | Test mới `L7: MESSAGE thiếu destination` |

Không có finding nào bị reject.

## Chi tiết fix

### H1 — wsUrl default sai path

`lib/app/env_config.dart:23`: default `ws://localhost:8080/ws` → `ws://localhost:8080/api/ws`.
Đối chiếu BE spec `redis-cache-ws-baseline.md` §"Transport & Handshake".

### M2 — listener gắn trước `await ready`

`app_event_bus.dart:_connect` đảo thứ tự:
1. Tạo channel, gán `_channel`.
2. **`.stream.listen(...)`** với `onError`, `onDone` — gắn listener trước.
3. `await channel.ready` — nếu future throw thì `catch` sẽ bắt.
4. `channel.sink.add(StompFrame.connect(...))` nếu ready thành công.

Lý do: nếu server reject trong khoảng giữa handshake (vd 401 STOMP ERROR), không có
listener nào sẵn sàng → frame bị mất. Giờ listener đã có sẵn.

### M3 — `StompFrame.connect` có tham số `host`

Factory `StompFrame.connect(authorizationHeader: ..., host: 'localhost')` — thêm
param `host` (default `localhost` cho backward compat). `AppEventBus._connect` pass
`host: uri.host`.

### M4 — `_ensureConnected` recreate `_connectedController` nếu closed

Sau `dispose()`, `_connectedController.isClosed == true`. Khi caller listen lại
`rawEvents()` → `_ensureConnected` check `isClosed` → nếu true thì tạo broadcast controller mới,
tránh `"Cannot add new events after calling close"` khi nhận CONNECTED.

Field `_connectedController` đổi từ `final` sang mutable (có comment giải thích).

### L5 — Xoá helper `unawaited` custom

Helper custom `(Future<void>?){}` che khuất symbol SDK. Xoá hoàn toàn, dùng
`unawaited` của `dart:async` (file đã `import 'dart:async'`).

### L7 — MESSAGE thiếu destination: cảnh báo nhật ký

Trong `_onFrame` branch `MESSAGE`, khi `destination == null`, thay vì `return`
im lặng thì cảnh báo nhật ký trước rồi return. Debug aid, không thay đổi hành vi.

## Bằng chứng kiểm chứng

```
flutter pub get                                                  OK
flutter analyze                                                  No issues found
flutter test                                                     All tests passed! (97 tests)
```

So với trước fix: 94 → 97 tests (+3 test tái hiện lỗi M2/M4/L7). Toàn bộ cổng
§4.3 xanh.

## Rủi ro dư

1. STOMP re-auth giữa chừng access token hết hạn — ngoài phạm vi (open question Q4).
2. Demo mode chưa có WS giả lập — khi FE-5 wire vào.
3. Drift schema migration baseline sẽ bump ở FE-5.

## Handoff

Code FE-4 đã qua vòng review/fix. Sẵn sàng cho re-review hoặc merge.
