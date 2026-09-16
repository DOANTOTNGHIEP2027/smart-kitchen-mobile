# Tiến độ dự án Smart Kitchen Mobile

> Cập nhật: 2026-09-16 — Sau khi merge `origin/main` (commit `c9836f4`)

---

## Tổng quan các nhóm tính năng

| # | Nhóm tính năng | Trạng thái | Người/nhánh |
|---|---|---|---|
| 0 | App shell & nền tảng dùng chung | ✅ Hoàn thành | — |
| 1 | Auth, OTP & household | ✅ Hoàn thành source | quangdv-feature1 |
| 2 | Profile, health & family | ✅ Hoàn thành source (mới merge) | PR #2 — `feature/29_profile-family-health-v2` |
| 3 | Local/realtime/notification | ✅ Hoàn thành | STOMP WS, FCM, Connectivity, Local Notif |
| 4 | Inventory offline-first | ❌ Chưa bắt đầu | — |
| 5–20 | Các tính năng còn lại | ❌ Chưa bắt đầu | — |

---

## Chi tiết Tính năng 2 — Profile, gia đình & hồ sơ sức khoẻ (MỚI MERGE)

PR #2 (`7e90417`) đã merge vào `main` và bạn vừa pull về. Dưới đây là tất cả những gì nhóm đã làm:

### Màn hình mới (6 màn hình)

| Màn hình | File | Mô tả |
|---|---|---|
| **ProfileScreen** | [`profile_screen.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/profile_screen.dart) | Hiển thị avatar, tên, email. Nút điều hướng đến Edit Profile, Health Profile, Family |
| **EditProfileScreen** | [`edit_profile_screen.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/edit_profile_screen.dart) | ⚠️ **BLOCKED** — Form chỉnh sửa tên nhưng bị khoá vì BE chưa ship `PUT /api/v1/users/me`. Hiển thị banner cảnh báo "đang xây dựng" |
| **HealthProfileScreen** | [`health_profile_screen.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/health_profile_screen.dart) | Form nhập calo mục tiêu, chế độ ăn (diet type), chiều cao, cân nặng. Hiển thị danh sách dị ứng (allergens) + nút chỉnh sửa |
| **AllergenSelectScreen** | [`allergen_select_screen.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/allergen_select_screen.dart) | Danh sách checkbox chọn chất gây dị ứng từ catalog. Lưu lại và patch ngược vào health profile |
| **FamilyScreen** | [`family_screen.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/family_screen.dart) | Danh sách thành viên household, kéo refresh, OWNER có thể mời thành viên mới hoặc xoá thành viên |
| **MemberDetailScreen** | [`member_detail_screen.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/member_detail_screen.dart) | Xem tóm tắt sức khoẻ (diet type, allergens) của thành viên trong household |

### Routes mới

| Route | Constant |
|---|---|
| `/profile` | `AppRoutes.profile` |
| `/profile/edit` | `AppRoutes.profileEdit` |
| `/profile/health` | `AppRoutes.profileHealth` |
| `/profile/allergens` | `AppRoutes.profileAllergens` |
| `/family` | `AppRoutes.family` |
| `/family/:userId` | `AppRoutes.memberDetail` |

Tất cả routes đều được bảo vệ bởi `AuthGuard`.

### API layer (3 API class)

| API | File | Endpoints |
|---|---|---|
| **ProfileApi** | [`profile_api.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/api/profile_api.dart) | `PUT /api/v1/users/me` (⚠️ BLOCKED — BE chưa ship) |
| **HealthApi** | [`health_api.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/api/health_api.dart) | `GET/PUT /api/v1/users/me/health-profile`, `GET /api/v1/allergens`, `PUT /api/v1/users/me/allergens`, `GET /api/v1/users/:userId/health-summary` |
| **FamilyApi** | [`family_api.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/api/family_api.dart) | `GET /api/v1/households/me`, `POST /api/v1/households/invites`, `DELETE /api/v1/households/members/:userId` |

### Store layer (2 MobX stores)

| Store | File | Chức năng |
|---|---|---|
| **ProfileStore** | [`profile_store.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/stores/profile_store.dart) | Load/save health profile, load/save allergens, save profile (blocked). Hỗ trợ read-cache fallback offline |
| **FamilyStore** | [`family_store.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/stores/family_store.dart) | Load roster, xem member health summary, tạo invite, xoá thành viên. Có cache fallback |

### Domain models mới

| Model | File |
|---|---|
| `HealthProfile` | [`health_profile.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/health_profile.dart) |
| `Allergen` | [`allergen.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/allergen.dart) |
| `DietType` (enum) | [`diet_type.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/diet_type.dart) |
| `HouseholdMember` | [`household_member.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/household_member.dart) |
| `HouseholdRoster` | [`household_roster.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/household_roster.dart) |
| `InviteResult` | [`invite_result.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/invite_result.dart) |
| `MemberHealthSummary` | [`member_health_summary.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/member_health_summary.dart) |
| `ProfileMappers` | [`profile_mappers.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/domain/profile_mappers.dart) |

### Hạ tầng mới

| Thành phần | File | Mô tả |
|---|---|---|
| **AppDatabase** (Drift) | [`app_database.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/db/app_database.dart) | SQLite local database (schema v1), singleton qua GetX |
| **ReadCacheDao** | [`read_cache_dao.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/db/read_cache_dao.dart) | DAO key-value cache cho offline-first: `get(key)` / `put(key, json)` |
| **ReadCacheEntries** (table) | [`read_cache_table.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/db/read_cache_table.dart) | Bảng Drift `(key TEXT PK, payload TEXT, fetchedAt TEXT)` |
| **StaleDataBanner** | [`stale_data_banner.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/widgets/stale_data_banner.dart) | Banner cảnh báo "dữ liệu cũ" khi hiển thị từ cache |
| **MemberRow** | [`member_row.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/scenes/profile/widgets/member_row.dart) | Widget hiển thị 1 thành viên trong danh sách family |

### Thay đổi trên nền tảng cũ

- **bootstrap.dart**: Thêm DI cho `AppDatabase`, `ReadCacheDao`, `HealthApi`, `FamilyApi`, `ProfileApi`
- **app_routes.dart**: Thêm 6 route constants cho profile/family
- **app_pages.dart**: Đăng ký `profileFamilyPages`
- **pubspec.yaml**: Thêm dependencies `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`
- **i18n (en/vi)**: Thêm ~50 chuỗi dịch mới cho profile/health/family
- **l10n**: Chuyển từ `assets/i18n/` sang `lib/l10n/` (xoá file cũ)

### Tests mới

| Test | File | Nội dung |
|---|---|---|
| ReadCacheDao test | [`read_cache_dao_test.dart`](file:///e:/DO_AN/smart-kitchen-mobile/test/data/db/read_cache_dao_test.dart) | Test put/get/upsert cho cache |
| ProfileStore test | [`profile_store_test.dart`](file:///e:/DO_AN/smart-kitchen-mobile/test/scenes/profile/profile_store_test.dart) | 254 dòng — test load/save health profile, allergens, cache fallback, error handling |

---

## Chi tiết Tính năng 3 — Local / Realtime / Notification (MỚI HOÀN THÀNH)

### 1. Realtime WebSocket STOMP
- **Transport**: Raw WebSocket qua endpoint `ws://<host>:8080/api/ws` (Backend Spring WebSocket không dùng SockJS, heartbeat tắt `{0,0}`).
- **Authentication**: Gửi STOMP frame `CONNECT` mang STOMP native header `Authorization: Bearer <token>` (tự động đọc access token mới nhất từ `TokenStorage`).
- **Topic Subscription**: Tự động subscribe các topic của gia đình:
  - `/topic/household/{id}/inventory`
  - `/topic/household/{id}/vote`
  - `/topic/household/{id}/shopping`
- **At-least-once Deduplication**: Lọc bỏ trùng lặp event theo `eventId` (sliding window 500 ids).
- **Auto Reconnect & Resilience**: Exponential backoff ($2^n$ giây, cap 60s), tự động reconnect khi có mạng trở lại.
- **Files**:
  - [`stomp_minimal.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/realtime/stomp_minimal.dart): STOMP 1.2 frame builder/parser.
  - [`ws_event_envelope.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/realtime/ws_event_envelope.dart): Parse event chuẩn backend (`eventId`, `eventType`, `householdId`, `occurredAt`, `actorId`, `data`).
  - [`realtime_service.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/realtime/realtime_service.dart): Quản lý vòng đời kết nối STOMP WS.
  - [`realtime_store.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/stores/realtime_store.dart): MobX store cầu nối giữa session, household và realtime event streams.

### 2. Push Notifications & Local Notifications
- **Backend Device Registration**: `DeviceApi` đăng ký FCM token với backend qua `POST /api/v1/devices/register` (`{deviceToken, platform}`).
- **FCM Token Lifecycle**: Tự động đăng ký khi app khởi động và lắng nghe `onTokenRefresh` để re-register.
- **Background & Foreground Messaging**:
  - Background handler chạy trên isolate riêng với `@pragma('vm:entry-point')`.
  - Foreground notification hiển thị qua `flutter_local_notifications` với Android Notification Channel cấu hình sẵn.
- **Permissions & Platform config**: Thêm permissions `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS` vào `AndroidManifest.xml`.
- **Files**:
  - [`device_api.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/notification/device_api.dart)
  - [`notification_service.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/data/notification/notification_service.dart)

### 3. Network Connectivity & Offline Detection
- **Connectivity Service**: Dùng `connectivity_plus` lắng nghe trạng thái mạng, cung cấp stream `onConnectivityRestored` để trigger reconnect WS và làm nền tảng cho sync queue ở Tính năng 4.
- **Files**:
  - [`connectivity_service.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/services/connectivity_service.dart)

### 4. Dependency Injection Wiring
- **File**: [`bootstrap.dart`](file:///e:/DO_AN/smart-kitchen-mobile/lib/app/bootstrap.dart) tích hợp hoàn chỉnh `ConnectivityService`, `RealtimeService`, `DeviceApi`, `NotificationService`, `RealtimeStore` theo thứ tự lifecycle phù hợp (Network -> Auth/Session -> WS -> FCM).

### 5. Tests
- [`stomp_minimal_test.dart`](file:///e:/DO_AN/smart-kitchen-mobile/test/data/realtime/stomp_minimal_test.dart): 8 tests pass.
- [`ws_event_envelope_test.dart`](file:///e:/DO_AN/smart-kitchen-mobile/test/data/realtime/ws_event_envelope_test.dart): 4 tests pass.
- Toàn bộ test suite: 93/93 tests pass (100%).

---

## ⚠️ Lưu ý quan trọng

1. **EditProfileScreen bị BLOCKED**: `PUT /api/v1/users/me` chưa tồn tại ở backend. Form hiện tại bị khoá (disabled), chỉ hiện banner cảnh báo. Cần đợi team BE ship endpoint này.
2. **Drift codegen**: File `app_database.g.dart` (398 dòng) đã được generate sẵn. Nếu thay đổi schema cần chạy lại `dart run build_runner build`.
3. **i18n migration**: Các file `assets/i18n/app_localizations.dart` và `app_localizations_en.dart` cũ đã bị **XOÁ**, thay bằng `lib/l10n/` (Flutter gen_l10n chính thức).

---

## Việc cần làm tiếp theo

Theo roadmap trong `summary.md`, sau khi hoàn thành Tính năng 3, thứ tự tiếp theo là:

### Ưu tiên 1: Tính năng 4 — Inventory offline-first
- [ ] Bảng Drift lưu trữ kho thực phẩm gia đình (items, categories, locations)
- [ ] Offline-first sync queue (hàng đợi sync hành động offline, sync khi online lại qua `ConnectivityService`)
- [ ] Lắng nghe STOMP `/topic/household/{id}/inventory` qua `RealtimeStore` để cập nhật realtime khi thành viên khác thêm/sửa/xoá thực phẩm
- [ ] CRUD thực phẩm tủ lạnh / tủ đông / ngăn bếp
- [ ] Màn hình danh sách kho, thêm mới thực phẩm, chi tiết thực phẩm

### Ưu tiên 2: Tính năng 6 — Meal plan & vote
- [ ] Lên kế hoạch bữa ăn
- [ ] Vote trong household qua WebSocket topic `/topic/household/{id}/vote`
- [ ] Phụ thuộc tính năng 3–4

### Ưu tiên 3: Tính năng 8 — Shopping offline-first
- [ ] Danh sách mua sắm
- [ ] Offline-first sync queue
- [ ] Lắng nghe WebSocket topic `/topic/household/{id}/shopping`

### Ưu tiên 4: Tính năng 8 — Shopping offline-first
- [ ] Danh sách mua sắm
- [ ] Offline-first
- [ ] Phụ thuộc tính năng 3

> **Gợi ý**: Bạn nên bắt đầu với **Tính năng 3 (Local/realtime/notification)** vì nó là dependency chung cho hầu hết các tính năng còn lại (4, 6, 8, 10).
