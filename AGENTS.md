# AGENTS.md — `smart-kitchen-mobile` (Flutter · MobX + GetX)

## Tài liệu nằm ở repo KHÁC

Repo này **chỉ chứa code**. Thiết kế/contract/kế hoạch ở repo anh em:

```
DOCS = D:/DO_AN/ai-native
```

Đường dẫn **ngoài project root** → lần đọc đầu OpenCode hỏi quyền `external_directory`.

| Cần gì | Đọc file nào |
|---|---|
| Luật vận hành | `DOCS/CODEX.md` · `DOCS/CLAUDE.md` |
| Context FE | `DOCS/CONTEXT_FE.md` |
| **Kế hoạch đang chạy** | `DOCS/docs/planning/mvp-demo-execution-plan.md` |
| Thiết kế màn hình | `DOCS/docs/design/frontend/<slug>.md` |
| **Mock-up** | `DOCS/docs/design/frontend/mockups/<slug>.html` — mở bằng trình duyệt |
| Contract REST | `DOCS/docs/contracts/openapi/<slug>.yaml` |
| Skill definition | `DOCS/.github/skills/<skill>/SKILL.md` |

**Chỉ ĐỌC từ `DOCS`.** Sửa tài liệu thì mở phiên riêng trong repo đó.

## ⚠️ Key JSON là camelCase — sai là hỏng âm thầm

Mọi response REST và payload WebSocket dùng **camelCase** (`recipeId`, `totalMembers`, `slotId`,
`dishId`, `deadlineAt`, `fullName`…). Một số đoạn code mẫu trong tài liệu thiết kế **đời cũ** viết
`snake_case` — đã sửa 2026-09-15, nhưng nếu gặp bản cũ ở đâu đó thì camelCase là đúng.

Parse sai key trong Dart **không ném exception, không log gì** — field lặng lẽ về `null` và UI trống
trơn. Đây là lớp lỗi tốn công truy nhất của pass thiết kế này. Nghi ngờ thì mở OAS ra đối chiếu.

## Cổng chất lượng

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # BẮT BUỘC sau khi đổi @observable
flutter analyze                                             # 0 error, 0 warning
flutter test                                                # TOÀN BỘ
```

**Xanh =** `flutter analyze` không có `error`/`warning`; `flutter test` in `All tests passed!`.

> Quên `build_runner` sau khi thêm `@observable`/`@action` → `*.g.dart` lệch → lỗi biên dịch khó
> hiểu, trông như lỗi ở chỗ khác. Chạy nó **trước** `analyze`, luôn luôn.

## Quy ước code

- **MobX sở hữu toàn bộ business/reactive state. GetX chỉ routing + DI.**
  Không `Rx`/`Obx`/`GetxController` cho feature state (quyết định D1, luật toàn project).
- Layer: Model → Repository → UseCase → Store (MobX) → View
- **Thứ tự interceptor trong `DioClient.build()` là load-bearing** — Dio chạy `onError` **ngược**
  thứ tự thêm vào. `TokenRefreshInterceptor` phải nằm **sau** `ErrorMappingInterceptor` trong list.
  Đảo lại là tắt âm thầm cơ chế refresh token. Đây từng là blocker, không phải lựa chọn phong cách.
- `*Api` bắt buộc convert `DioException` → `ApiException` **bên trong** (`_unwrap`) trước khi ném ra
  Store. Thiếu bước này, mọi `catch (BusinessException e) when (e.code == ...)` không bao giờ match
  và toàn bộ fallback/rollback đã thiết kế trở thành code chết.
- Mọi màn hình cover đủ **loading / empty / error / success** (`ViewState<T>` + `AppStateView<T>`)
- **Không hardcode text** — dùng `context.l10n.xxx`
- Không mất dữ liệu thao tác người dùng khi offline/reconnect
- Optimistic update phải rollback về **đúng snapshot trước đó**, không về `null`/giá trị suy đoán

## An toàn dị ứng — không được im lặng

`allergenTags = []` với `allergenDerivation != "INGREDIENT_RULE"` nghĩa là **"chưa kiểm được"**,
KHÔNG phải "an toàn". `AllergenBanner` có 3 nhánh (thiết kế §9.3) và **không bao giờ** trả
`SizedBox.shrink()` ở nhánh chưa kiểm chứng. Widget test cho nhánh này là test chống hồi quy an
toàn — **không được xoá**.

## Dependency

Được phép thêm không cần hỏi (kế hoạch §6.1 D-05): `drift`, `drift_flutter`/`sqlite3_flutter_libs`,
`path_provider`, `web_socket_channel`, `stomp_dart_client`, `connectivity_plus`,
`cached_network_image`, `fl_chart`; dev: `build_runner`, `drift_dev`, `mobx_codegen`, `mocktail`.
**Ngoài danh sách thì ưu tiên tự viết thay vì thêm thư viện.**

## Chế độ tự động

Áp `DOCS/docs/planning/mvp-demo-execution-plan.md`: §0 luật vàng · §3 vòng lặp tối đa **3 vòng**
rồi `PARKED` · §4.3 cổng chất lượng · §5 chống bug chồng bug · §6 sổ quyết định · §7 đúng 4 trường
hợp được dừng · §8 giao thức merge.

**Không dừng hỏi ngoài §7.** Chưa phủ thì áp §6.0 → ghi `DOCS/docs/planning/open-decisions.md` →
đi tiếp. Chưa có `google-services.json` thì theo §6.1 D-01: demo bằng email + OTP, vẫn code và
unit-test `GoogleAuthGateway` bằng fake. **Không chặn task nào.**

## Git

- Nhánh: `feature/<issue>_<slug>` · Commit/PR **tiếng Việt**
- **Rebase, không merge**, và **chạy lại cổng chất lượng SAU rebase**
- **Hook chặn trailer đồng tác giả AI**
