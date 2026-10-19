# Open Decisions — quyết định agent tự chốt khi chạy tự động

> Agent **ghi vào đây rồi đi tiếp**, không dừng chờ trả lời.
> Luật: `D:/DO_AN/ai-native/docs/planning/mvp-demo-execution-plan.md` §6.0 (quy tắc vét cạn),
> §6.1 (20 tình huống đã chốt), §6.3 (mẫu ghi), §0.1 (vì sao file này nằm ở đây chứ không ở repo
> tài liệu).

## Vì sao file này ở repo code, không ở `ai-native`

Mỗi repo là một session OpenCode riêng và **không commit được sang repo khác**. Ghi quyết định
sang `ai-native` thì file nằm dirty vĩnh viễn ở một repo mà session này không đẩy lên được, và
không ai thấy. Ghi ở đây thì nó đi kèm chính PR đã sinh ra quyết định đó.

Phiên `ai-native` gom định kỳ bằng `/status` vào `docs/planning/open-decisions.md`.

## Cách dùng

- Một mục = một quyết định agent đã tự chốt, hoặc một việc phát hiện ngoài phạm vi task.
- **Không** dùng file này để hỏi. Đã ghi vào đây nghĩa là **đã chọn và đã đi tiếp**.
- Đánh số `OD-01`, `OD-02`… nối tiếp, không tái sử dụng số.
- Việc ngoài phạm vi (bug, refactor, finding MEDIUM/LOW) ghi cùng mẫu, mục "Đã chọn" ghi
  `Hoãn — gom vào task dọn riêng`.

## Mẫu

```markdown
## OD-<số> · <tiêu đề ngắn>
- **Ngày:** YYYY-MM-DD · **Task:** <id> · **Nhánh:** <branch>
- **Tình huống:** <mô tả 1–3 câu>
- **Đã chọn:** <phương án> · **Theo:** §6.0 quy tắc <n> / §6.1 D-<nn>
- **Đảo ngược thế nào:** <1 câu>
- **Cần người quyết lại không:** Có/Không — <lý do>
```

## Danh sách

### OD-04 · FE-6 DoD nói `INSUFFICIENT_STOCK_FOR_RECIPE` nhưng OAS cooking-session v1.0.0 không có lỗi đó
- **Ngày:** 2026-09-16 · **Task:** FE-6 (cooking session) · **Nhánh:** `feature/81_cooking-session`
- **Tình huống:** Kế hoạch `mvp-demo-execution-plan.md` §9.0 + DoD FE-6 (thêm 2026-09-16) yêu cầu: "Bấm *Hoàn tất nấu* khi **thiếu** nguyên liệu → hiện `INSUFFICIENT_STOCK_FOR_RECIPE` kèm danh sách nguyên liệu thiếu, và **kho không đổi gì cả** (rollback toàn phần)". Nhưng OpenAPI thật `cooking-session.yaml` v1.0.0 (REVIEWED+FIXED) cho `POST /complete` mô tả khác: "Thiếu kho KHÔNG làm response trả lỗi — 200 luôn được trả nếu session hợp lệ, kể cả khi mọi shortfallQuantity đều dương."
- **Đã chọn:** Code theo **OAS thật** (§6.2 luật 1). · **Theo:** §6.2 + §6.1 D-09 + §6.0 quy tắc 2.
- **Đảo ngược thế nào:** Nếu BE thêm `INSUFFICIENT_STOCK_FOR_RECIPE`, cập nhật `CookingSessionStore.complete()` + dialog thiếu.
- **Cần người quyết lại không:** Có — kịch bản demo §9.1 bước 6b có thể lệch BE thật.

### OD-05 · FE-7 review pass 1 — 4 LOW findings chưa fix (gom vào pass i18n/dọn sau)
- **Ngày:** 2026-09-16 · **Task:** FE-7 (meal-plan voting) · **Nhánh:** `feature/62-63_meal-plan-voting`
- **Tình huống:** `/review` pass 1 tìm ra 4 LOW ngoài scope §6.1 D-10 (gom vào task dọn riêng, không chặn merge):
  1. **Double WS handling** — cả `MealPlanStore._subscribeWs()` và `VoteSessionStore.init()` đều listen `_realtimeStore.events` rồi delegate tới `handleVoteEvent`. Mỗi vote event bị xử lý 2× (idempotent về data nhưng waste + log 2×). Khác inventory FE-5 không gặp vì không có sub thứ 2.
  2. **Hardcode text tiếng Việt** — hàng chục chuỗi UI lie trickly: 'Kế hoạch tuần', 'Sáng/Trưa/Tối', 'Phiên vote', 'Chọn món', … — vi phạm AGENTS.md "Không hardcode text". Cùng loại với inventory FE-5, cooking FE-6 — chưa có convention i18n cấp platform.
  3. **`MealSuggestionDetailScene._store` cleanup symmetry** — tạo `_store` trong initState nhưng không dispose. Hiện `SuggestionStore` không giữ sub/resource nên không leak, chỉ thiếu defensive.
  4. **`navigateWeek` ERR_PLAN_001 — error recovery yếu** — chứa clear slots/sessions nhưng không có nút "Quay lại tuần này" rõ ràng trong UI error. User kẹt với `loadWeekPlan()` thủ công. Cũng gap Q1/CRITICAL thiết kế BE chưa fix.
- **Đã chọn:** Gom tất cả vào task dọn riêng — không fix trong PR này để giữ scope gọn. · **Theo:** §6.1 D-10 (review >10 finding → MEDIUM/LOW gom vào `open-decisions.md` thành 1 task dọn riêng), §6.0 quy tắc 3 (ít thay đổi nhất thắng).
- **Đảo ngược thế nào:** Khi pass i18n/dọn (sau demo) áp lên cả 3 feature (FE-5/6/7). Pass i18n là thay đổi cấp platform — không gộp vào 1 task feature.
- **Cần người quyết lại không:** Không.
- **Ngày:** 2026-09-16 · **Task:** FE-6 (cooking session) · **Nhánh:** `feature/81_cooking-session`
- **Tình huống:** Kế hoạch `mvp-demo-execution-plan.md` §9.0 + DoD FE-6 (thêm 2026-09-16) yêu cầu: "Bấm *Hoàn tất nấu* khi **thiếu** nguyên liệu → hiện `INSUFFICIENT_STOCK_FOR_RECIPE` kèm danh sách nguyên liệu thiếu, và **kho không đổi gì cả** (rollback toàn phần)". Nhưng OpenAPI thật `cooking-session.yaml` v1.0.0 (REVIEWED+FIXED) cho `POST /complete` mô tả khác: "Thiếu kho KHÔNG làm response trả lỗi — 200 luôn được trả nếu session hợp lệ, kể cả khi mọi shortfallQuantity đều dương." Tức là BE trừ FIFO tới đâu hết rồi dừng, KHÔNG rollback, trả 200 với `deductions[].shortfallQuantity > 0`.
- **Đã chọn:** Code theo **OAS thật** (§6.2 luật 1: code+test merge thắng kế hoạch khi mâu thuẫn). FE hiển thị kết quả `complete()` với badge "Không đủ" trên từng ingredient có `hasShortfall`, KHÔNG raise dialog lỗi đỏ. UI diễn giải rõ "BE đã trừ tới đâu hết rồi dừng", không có rollback. · **Theo:** §6.2 luật 1 + §6.1 D-09 (không bịa API) + §6.0 quy tắc 2 (thiết kế/OAS thắng phỏng đoán).
- **Đảo ngược thế nào:** Nếu sau này BE thay đổi để thêm `INSUFFICIENT_STOCK_FOR_RECIPE` (422/409), cập nhật `CookingSessionStore.complete()` thêm `catch` cho mã đó, và sửa UI hiển thị dialog "thiếu + rollback".
- **Cần người quyết lại không:** Có — kịch bản demo §9.1 bước 6b dựa trên giả định "kho không đổi gì cả". Nếu thầy chấm điểm dựa trên bước 6b, cần đối chiếu lại với BE team xem `complete()` thật có rollback khi thiếu hay không (OAS ghi không, nhưng BE code có thể khác OAS — chưa verify code BE thật).

### OD-06 · Khách ăn cùng (guest-diner) gắn với KẾ HOẠCH TUẦN, không phải 1 bữa như thiết kế FE giả định (D1)
- **Ngày:** 2026-10-18 · **Task:** #101 flexible meal planning (PR 1: slice 1–5) · **Nhánh:** `feature/101_flexible-meal-planning`
- **Tình huống:** `flexible-meal-planning-screens.md` §8.2 + D1 giả định `mealPlanId == MealPlanSlot.id` và copy UI "chỉ áp dụng cho ĐÚNG bữa này". BE thật (`GuestDinerServiceImpl.requirePlan` → `MealPlanRepository.findById`) coi `mealPlanId` là id `meal_plans` = 1 row/1 tuần. Gọi bằng slotId sẽ ra `ERR_MEAL_PLAN_NOT_FOUND`. Ngoài ra `DELETE` trả `204` (thiết kế ghi `{success:true}`).
- **Đã chọn:** Code theo BE thật: route `/meal-plan/plan/:planId/guest-diners`, lấy `MealPlanStore.currentPlanId`, nút mở ở thanh tiêu đề lịch tuần; copy UI nói "chỉ áp dụng cho kế hoạch tuần này". · **Theo:** §6.2 luật 1 + §6.1 D-09 (không bịa API).
- **Đảo ngược thế nào:** Nếu BE đổi sang scope theo bữa (Q11 của `meal-planning-core.md`), đổi route param sang `slotId` + sửa chuỗi `planningGuestScopeBanner`.
- **Cần người quyết lại không:** Có — thiết kế và BE đang lệch về ngữ nghĩa an toàn dị ứng (khách tuần vs khách 1 bữa); cần chốt ở phiên repo `ai-native`.

### OD-07 · #101 PR 1 — 3 finding LOW còn lại sau 3 vòng review (gom vào task dọn riêng)
- **Ngày:** 2026-10-19 · **Task:** #101 PR 1 · **Nhánh:** `feature/101_flexible-meal-planning`
- **Tình huống:** (1) Chưa có widget test bảo vệ điều kiện chỉ hiện nút 'Khách ăn cùng' khi `status == ready` — thiếu harness `WeeklyMealPlanScene`. (2) [ĐÃ LÀM 2026-10-19: banner hiện tên khách] Banner sau khi xoá chưa tự tắt khi thêm/sửa tiếp. (3) Xoá gặp 404 thì list đã tải lại nhưng dialog vẫn mở.
- **Đã chọn:** Hoãn — gom vào task dọn riêng. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Làm trong PR 2 hoặc task dọn planning.
- **Cần người quyết lại không:** Không — người duyệt đã chốt hiện tên khách (2026-10-19).
