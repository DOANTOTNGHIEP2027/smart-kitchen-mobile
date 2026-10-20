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

### OD-08 · #101 PR 2 — candidate theo KẾ HOẠCH TUẦN + gắn theo sessionId, khác thiết kế §5.3/§6/§7.3
- **Ngày:** 2026-10-19 · **Task:** #101 PR 2 (slice 6–8) · **Nhánh:** `feature/101_candidate-repetition`
- **Tình huống:** BE thật `GET /meal-plans/{mealPlanId}/candidates` coi `mealPlanId` là id `meal_plans` (tuần, như OD-06); `MealPlanCandidateResponse` KHÔNG có `dishId/slotId/mealDate/mealTime` mà có `sessionId`; field là `algorithmRecommended` (không `is`); `softScoreBreakdown` là map `feature_breakdown` snake_case của AI (inventory_coverage, expiry_urgency, repetition_penalty…, weights, contributions, profile_version), không phải `{dietScore, expiringScore, weights:{diet,expiry,repeat}}`. Phiên join qua 409 có sessionId sentinel `__unknown__`.
- **Đã chọn:** Route `/meal-plan/plan/:planId/candidates?sessionId&slotId&dishId&noSession`. Biết sessionId thật → lọc 1 phiên; sentinel → hiện cả tuần nhóm theo phiên; món chưa mở phiên → rỗng + nút sinh. Sinh gợi ý dùng lại `MealPlanStore.openVoteSession` (không thêm `CandidateApi.generate`). Không có nút "Sinh gợi ý mới" khi đã có phiên (vote/open trả 409). Breakdown render động theo key, trọng số âm tô cảnh báo. · **Theo:** §6.2 luật 1 + §6.1 D-09.
- **Đảo ngược thế nào:** Nếu BE thêm `dishId` vào response hoặc trả sessionId ở `vote/result`, lọc theo dishId và bỏ chế độ cả tuần.
- **Cần người quyết lại không:** Có — thiết kế FE §5.3/§8.3 cần cập nhật theo shape thật; nên đề xuất BE trả `sessionId` ở `GET vote/result`.

### OD-09 · #101 PR 2 — 6 finding LOW còn lại sau 3 vòng review (gom vào task dọn riêng)
- **Ngày:** 2026-10-19 · **Task:** #101 PR 2 · **Nhánh:** `feature/101_candidate-repetition`
- **Tình huống:** (1) Chưa có widget test cho `MealSlotEditorScene._openCandidates` (món CONFIRMED không sinh gợi ý) — thiếu harness MealPlanStore. (2) `blockedReason` BE trả tiếng Việt hardcode kèm `allergen_derivation=UNVERIFIED`, FE hiện nguyên văn — cần BE trả mã lý do. (3) `AppStateView` hiện `error.message` tiếng Anh với ERR_UNKNOWN — sửa ở widget dùng chung. (4) Thứ tự feature theo key JSONB không cố định. (5) `_unwrap` lặp ở 4 Api planning (2 kiểu khác nhau) — nên có helper chung. (6) Nút ✨ không phản hồi khi `currentPlanId == null`.
- **Đã chọn:** Hoãn — gom vào task dọn riêng. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Làm trong task dọn planning; (2) cần phiên BE.
- **Cần người quyết lại không:** Không.

### OD-10 · Tier-gate (slice 1–7) — lệch thiết kế theo BE thật; ngân sách §19 tách PR sau
- **Ngày:** 2026-10-19 · **Task:** tier-gate-screens (#96/#100) · **Nhánh:** `feature/tier-gate-screens`
- **Tình huống:** (1) `PATCH /households/members/{id}/role` trả **204** (thiết kế §7.1 đọc `data.role`). (2) `PATCH /households/me/tier` trả camelCase `householdId/tier/requiresTokenRefresh` (thiết kế viết snake_case). (3) Thiết kế dùng `MutationStatus` sealed — repo không có, dùng `FormStatus` + error observable như `FamilyStore` hiện có. (4) `SessionStore.refreshClaims()` bọc `refreshSession()` có sẵn, nuốt mọi lỗi (thiết kế chỉ nuốt `ApiException`). (5) Route `/family/tier-upgrade` đăng ký TRƯỚC `/family/:userId`.
- **Đã chọn:** Code theo BE thật + pattern repo. Phần ngân sách household (§19, `GET/PATCH /me/budget`) để PR riêng. · **Theo:** §6.2 luật 1 + §6.0 quy tắc 3.
- **Đảo ngược thế nào:** —
- **Cần người quyết lại không:** Không.

### OD-11 · Tier-gate — 7 finding LOW còn lại sau 3 vòng review (gom vào task dọn riêng)
- **Ngày:** 2026-10-19 · **Task:** tier-gate-screens · **Nhánh:** `feature/tier-gate-screens`
- **Tình huống:** (1) Đổi gói thành công nhưng `/auth/refresh` lỗi → toast báo gói mới, màn vẫn hiện gói cũ + nút cũ (trade-off Guard 4) — nên hiện banner 'đã đổi, đăng nhập lại để cập nhật'. (2) Chip 'Chỉ xem' ở MemberDetail cần roster đã tải; deep-link thẳng thì không hiện. (3) Badge MEMBER in chuỗi thô 'MEMBER' (code cũ, chưa l10n). (4) Banner lỗi hiện `ApiException.message` tiếng Anh với NetworkException (pattern toàn repo). (5) `FamilyApi` không `_unwrap` DioException trong Api (pattern cũ, store bù bằng storeApiException). (6) `TierUpdateResult` ép kiểu cứng `householdId`. (7) `applyHouseholdContext` không set `tier` khi refresh lỗi sau tạo/join household.
- **Đã chọn:** Hoãn — gom vào task dọn riêng. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Làm trong task dọn profile/tier.
- **Cần người quyết lại không:** Không.

### OD-12 · Ngân sách household (tier-gate §19, #133) — lệch thiết kế theo BE thật + cấu trúc repo
- **Ngày:** 2026-10-19 · **Task:** #133 · **Nhánh:** `feature/133_household-budget`
- **Tình huống:** (1) `BudgetResponse` BE trả camelCase `householdId/period/amount/currency/updatedBy/updatedAt` (thiết kế §19.2 đọc snake_case `updated_by/updated_at`). (2) Thiết kế đặt `formatVnd` ở `lib/core/format/money.dart` — repo không có `lib/core`, đặt ở `lib/utils/money_format.dart` (cạnh helper dùng chung khác); `BudgetPeriod` ở `lib/domain/shared/budget_period.dart` đúng thiết kế, nhãn lấy từ l10n thay vì `displayName`. (3) Trạng thái tải/ghi dùng `FormStatus` (repo không có `MutationStatus`).
- **Đã chọn:** Code theo BE thật + cấu trúc repo. Recap (weekly-recap §17) khi làm phải import đúng 2 file dùng chung này, không tạo bản thứ hai. · **Theo:** §6.2 luật 1 + §6.0 quy tắc 3.
- **Đảo ngược thế nào:** Nếu chốt `lib/core/format`, chỉ cần di chuyển file + sửa import.
- **Cần người quyết lại không:** Không.

### OD-13 · Ngân sách household — 6 finding LOW còn lại sau 3 vòng review + quyết định parse số tiền
- **Ngày:** 2026-10-19 · **Task:** #133 · **Nhánh:** `feature/133_household-budget`
- **Quyết định parse (lệch Guard #16):** Guard #16 nói strip MỌI ký tự không phải chữ số; làm vậy biến `1500000.50` thành 150.000.050 (gấp 100 lần) âm thầm. Code chỉ nhận số thuần hoặc phân cách nghìn đúng nhóm 3 (`1.500.000`/`1,500,000`), bỏ hậu tố ₫/đ/VND; còn lại báo lỗi inline. Nên cập nhật Guard #16 ở repo tài liệu.
- **LOW còn lại:** (1) `period=unknown` + có `amount` vẫn hiện nhãn 'Ngân sách tuần', sheet chọn sẵn Tuần (BE hiện chỉ WEEKLY/MONTHLY). (2) Vuốt đóng sheet khi đang lưu mà PATCH lỗi → không có phản hồi nào. (3) `parseAmount` chấp nhận '1đ500' và dấu phân cách trộn lẫn ('1.500,000'). (4) `formatVnd(-0.4)` ra '-0 ₫' — đúng nguyên văn đặc tả weekly-recap §17.2, cần sửa đặc tả. (5) Chip 'VND' cứng + banner hiện nguyên `error.message` tiếng Anh (pattern chung module profile). (6) Thứ tự import chưa alphabet ở family_store/household_plan_strip.
- **Đã chọn:** Hoãn — gom vào task dọn riêng. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Làm trong task dọn profile/budget; (4) và Guard #16 sửa ở repo ai-native.
- **Cần người quyết lại không:** Có — cập nhật Guard #16 theo quyết định parse ở trên.

### OD-14 · Recap lãng phí & chi tiêu (weekly-recap §17, #133) — lệch thiết kế theo BE thật
- **Ngày:** 2026-10-19 · **Task:** #133 recap · **Nhánh:** `feature/133_recap-spend-waste`
- **Tình huống:** (1) `WeeklyRecapResponse` BE trả camelCase (`wasteItemCount`, `spendByCategory`, `spendTrend[].weekStart`…) — thiết kế §17.2 viết snake_case. (2) `HouseholdTier.fromApi` đổi sang không phân biệt hoa/thường để claim 'premium' ra `lockedNeutral` đúng Guard #20/FIX MEDIUM-A4 (ảnh hưởng nhẹ tier-gate: chỉ là hint). (3) 10 field mới của `WeeklyRecapSummary` có giá trị mặc định (0/null/unknown) để payload cũ và các test cũ không vỡ. (4) Sparkline: đường ngân sách vẽ theo ngân sách tuần gần nhất có giá trị; tuần `spendTotal == null` là cột rỗng viền đứt.
- **Đã chọn:** Code theo BE thật. · **Theo:** §6.2 luật 1 + §6.0 quy tắc 3.
- **Đảo ngược thế nào:** —
- **Cần người quyết lại không:** Không.

### OD-15 · Recap lãng phí & chi tiêu — 8 finding LOW còn lại sau 3 vòng review (gom vào task dọn riêng)
- **Ngày:** 2026-10-19 · **Task:** #133 recap · **Nhánh:** `feature/133_recap-spend-waste`
- **Tình huống:** (1) `_fetchStreak` chỉ bắt ApiException — payload streak méo làm streak kẹt loading. (2) Nên đưa chuyển lỗi parse xuống `RecapApi._unwrap` thay vì ở Store. (3) catch-all không log stack trace. (4) `canSetBudget`/`spendDetailGate` đọc role/tier không qua observable → không rebuild khi claim đổi giữa chừng. (5) Quay về từ nâng cấp → `fetchAll` hiện skeleton, mất vị trí cuộn. (6) Nhánh `ratio > 1` trong `SpendSection.colorFor` là code chết. (7) Nhãn tuần sparkline `fontSize: 10` cứng, không qua AppTextStyles. (8) Assert `BudgetPeriod.fromApi('monthly')` lạc chỗ; ngưỡng màu 0.8 chưa có test riêng. Ghi chú tài liệu: §17.4 ghi `TierGateRoutes` (không tồn tại) — code dùng `ProfileFamilyRoutes.tierUpgrade`; mock-up state 11 tô cam ở đúng 80% trong khi văn bản ghi `<= 0.8` xanh.
- **Đã chọn:** Hoãn — gom vào task dọn riêng. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Làm trong task dọn recap; 2 ghi chú tài liệu sửa ở repo ai-native.
- **Cần người quyết lại không:** Không.

### OD-16 · Task dọn LOW (gom OD-05/07/09/11/13/15) — đã làm & còn lại
- **Ngày:** 2026-10-19 · **Task:** dọn LOW FE · **Nhánh:** `chore/fe-cleanup-low-findings`
- **Đã làm:** 61 key l10n cho chuỗi cứng (shopping, dependent, inventory list/validate, mealplan tooltip/status, meal log, badge MEMBER); helper `apiErrorMessage` (ERR_NETWORK/ERR_UNKNOWN → copy l10n) dùng ở `AppStateView` + các màn planning/tier/budget; toast đổi gói nói rõ khi claim chưa cập nhật; nút ✨ báo khi chưa có kế hoạch tuần; `_unwrap` planning thống nhất `e.apiException`; streak recap bắt mọi lỗi.
- **Còn lại (cố ý):** nhãn `MealType` là dữ liệu (ghép vào description gửi BE); 'Thành viên' mặc định trong `UserSummary`; danh mục mua sắm là giá trị gửi BE; nhãn đơn vị `unit_option`; badge 'GUEST'; message `ERR_INVENTORY_NOT_FOUND` tạo ở FE store. **Phát hiện BE:** `meal_plan_slots` vẫn enum `MealTime` 3 bữa, `resolveEffectiveSlots` không được gọi → template bữa tự cấu hình (PR #30) chưa áp vào lịch tuần — cần phiên BE.
- **Đã chọn:** Hoãn phần còn lại. · **Theo:** §6.0 quy tắc 3 + §6.1 D-09.
- **Đảo ngược thế nào:** —
- **Cần người quyết lại không:** Có — báo BE việc áp template bữa vào `meal_plan_slots`.

### OD-17 · Task dọn LOW — finding còn lại sau 3 vòng review
- **Ngày:** 2026-10-19 · **Task:** dọn LOW FE · **Nhánh:** `chore/fe-cleanup-low-findings`
- **Tình huống:** (1) Tuổi người phụ thuộc tính bằng hiệu số năm → dư 1 tuổi khi chưa tới sinh nhật (lỗi cũ). (2) Ngày sinh ghép cứng d/m/y cho cả locale en. (3) Card nhật ký bữa hiện description thô còn tiền tố '[Bữa sáng]' (lỗi cũ). (4) `apiErrorMessage` chưa phủ `ERR_AUTH_UNKNOWN` ('Session expired'). (5) Tooltip 'Tải lại' → 'Làm mới' do dùng key chung. (6) `health_profile_screen` hiện tên field kỹ thuật từ `fieldErrors`. (7) ~10 màn ngoài diff còn hiện `error.message` thô: cooking_session_scene, calorie_confirm_sheet, monthly_history_scene, recipe_*, vote_session_scene, meal_suggestion_detail_scene, weekly_recap_scene.
- **Đã chọn:** Hoãn — gom vào task dọn tiếp theo. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Áp `apiErrorMessage` cho các màn ở (7); sửa (1)(3) như bug riêng.
- **Cần người quyết lại không:** Không.

### OD-18 · Dọn nốt OD-17 — đã làm & còn lại
- **Ngày:** 2026-10-19 · **Task:** dọn OD-17 · **Nhánh:** `chore/fe-cleanup-od17`
- **Đã làm:** `apiErrorMessage` áp cho cooking_session_scene, calorie_confirm_sheet, monthly_history_scene (3 chỗ), meal_suggestion_detail_scene, vote_session_scene, weekly_recap_scene, recipe_detail_scene, recipe_list_scene (2 chỗ); `AuthExpiredException` (mọi 401) → `sessionExpiredError`; field lỗi hồ sơ sức khoẻ hiện nhãn l10n thay vì tên field kỹ thuật; tuổi người phụ thuộc tính đúng (`ageOn`), ngày sinh theo locale (`DateFormat.yMd`, như inventory_history_scene); card nhật ký bữa bỏ tiền tố '[Bữa sáng]' khỏi mô tả (`stripMealTypePrefix`).
- **Còn lại:** chưa có widget test cho snackbar lỗi cooking chỉ hiện 1 lần/instance (cần dựng Get + WakelockPlus); snackbar cooking 'Thử lại' chỉ xoá lỗi, không retry, và sau khi snackbar tự ẩn thì `actionError` vẫn còn mà không có UI (có từ trước); `ageOn` trả số âm nếu BE trả ngày sinh ở tương lai; tooltip 'Tải lại' → 'Làm mới' (chấp nhận); `ocr_store` truyền `'SAVE_FAILED'` như mã lỗi (không hiển thị thô).
- **Đã chọn:** Hoãn phần còn lại. · **Theo:** §6.0 quy tắc 3.
- **Đảo ngược thế nào:** —
- **Cần người quyết lại không:** Không.

### OD-19 · Đi chợ — nhập giá khi tick (#133, shopping-list-screen §9.4); phạm vi PR
- **Ngày:** 2026-10-19 · **Task:** shopping price capture · **Nhánh:** `feature/shopping-complete-price-delete`
- **Tình huống:** Đề xuất ban đầu gồm xoá món + sinh danh sách từ kế hoạch tuần + sửa món, nhưng `shopping-list-screen.md` §2 ghi rõ DELETE / form sửa đầy đủ / generate là NGOÀI phạm vi; FE hiện không gọi DELETE nên thay đổi breaking (body `{version}`) của BE #55 chưa ảnh hưởng. Assignee (#134) cần thêm `FamilyBinding fenix` + luồng online-only → tách PR sau.
- **Đã chọn:** PR này chỉ làm nhập giá: cột Drift `price` (schema v5, ALTER chỉ khi đi từ v4), `toggle(price)` gửi `price`+`currency: VND` chỉ khi có giá và chỉ chiều PENDING→COMPLETED, hàng đợi offline mang giá trong payload, tile hiện giá bằng `formatVnd` (hậu tố ₫ thống nhất toàn app thay vì 'đ' của thiết kế). · **Theo:** §6.0 quy tắc 2–3 + §6.1 D-09.
- **Đảo ngược thế nào:** Thêm DELETE/generate khi có thiết kế FE riêng.
- **Cần người quyết lại không:** Có — có cần thiết kế FE cho xoá món / sinh danh sách từ kế hoạch tuần không.

### OD-20 · Nhập giá đi chợ — finding LOW còn lại sau 3 vòng review
- **Ngày:** 2026-10-19 · **Task:** shopping price capture · **Nhánh:** `feature/shopping-complete-price-delete`
- **Đã thêm ngoài OD-19:** banner `shoppingPriceNotSaved` (AM-TB-4) khi toggle có giá bị BE từ chối (409 version / 400 validation) ở cả đường online lẫn drain — entry stale bị bỏ khỏi hàng đợi thay vì kẹt; toggle khi row còn PENDING_TOGGLE luôn đi qua coalesce kể cả online.
- **Còn lại:** (1) drain vẫn kẹt với `ERR_SHOP_ITEM_NOT_FOUND`/`ERR_SHOP_LIST_NOT_ACTIVE` (lỗi cũ, không liên quan giá). (2) Race: huỷ cặp đúng lúc drain đang gửi T1 → T1 vẫn tới server, ý định bỏ tick bị mất.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Task dọn hàng đợi shopping riêng.
- **Cần người quyết lại không:** Không.

### OD-21 · Gán người đi mua (#134, shopping-list-screen §9.5) — lệch thiết kế
- **Ngày:** 2026-10-19 · **Task:** #134 · **Nhánh:** `feature/134_shopping-assignee`
- **Tình huống:** (1) Thiết kế muốn chip assignee **disabled** khi offline; `ConnectivityService` chỉ có `isOnline()` async + stream 'có mạng lại', không có trạng thái online reactive → kiểm mạng lúc bấm, offline thì snackbar 'Cần mạng để giao việc' (store vẫn chặn lần 2). Chip vẫn disabled khi `isPendingSync` hoặc đang gửi (Guard #18). (2) Filter 'Của tôi' giữ ở state của scene (giống filter trạng thái hiện có) thay vì observable trong store; badge `assignedToMeCount` tính cục bộ trong store. (3) Áp blueprint B1: `FamilyBinding` đổi sang `fenix: true`; `ShoppingListBinding` lazyPut `FamilyStore` fenix + picker degrade khi chưa đăng ký. (4) Drift v6 thêm `assigned_to` (ALTER khi từ v4/v5). (5) `ERR_SHOP_ITEM_VERSION_CONFLICT` khi gán → sync lại + snackbar lỗi.
- **Đã chọn:** Như trên. · **Theo:** §6.0 quy tắc 3.
- **Đảo ngược thế nào:** Khi có observable online ở ConnectivityService, đổi sang disable chip + hint tĩnh.
- **Cần người quyết lại không:** Không.

### OD-22 · Gán người đi mua — finding LOW còn lại sau 3 vòng review
- **Ngày:** 2026-10-19 · **Task:** #134 · **Nhánh:** `feature/134_shopping-assignee`
- **Tình huống:** (1) Mất mạng sau khi mở picker → `assign()` trả false không lỗi, không snackbar 'Cần mạng'. (2) Chip disabled do `isPendingSync` nuốt tap im lặng — thiết kế §14 muốn hint 'Đang đồng bộ…'. (3) Dòng 'Tôi nhận' không lọc whitelist role — REMOTE_VIEWER tự gán sẽ ăn 400 + snackbar sai ngữ cảnh. (4) Chip 'Của tôi (0)' luôn hiện số, thiết kế chỉ hiện badge khi > 0. (5) Roster từ cache thiếu người → chip skeleton mãi, không đường nạp lại. (6) Điều kiện 'gán cho tôi' lặp ở scene + store (nên gom vào `ShoppingItem.isAssignedToMe`). (7) Thiếu test: 409 VERSION_CONFLICT khi gán, filter 'Của tôi' không đổi summary, mở picker từ /shopping không qua /family. **Ghi chú:** version guard của `sync()` chỉ áp cho món nhận PATCH gán trong lúc sync đang chạy (Demo Mode reset về v1 mỗi lần mở app nên guard chung theo version là sai).
- **Đã chọn:** Hoãn — gom vào task dọn shopping. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Task dọn shopping riêng (gộp OD-20).
- **Cần người quyết lại không:** Không.

### OD-23 · Dọn màn đi chợ (gộp OD-20 + OD-22) — đã làm
- **Ngày:** 2026-10-19 · **Task:** dọn shopping · **Nhánh:** `chore/shopping-cleanup-od20-od22`
- **Đã làm:** (1) `sync()` reconcile: row SYNCED mà server không còn trả → xoá cục bộ (§16 #16), row PENDING_* giữ cho drain. (2) Drain gặp `ERR_SHOP_ITEM_NOT_FOUND`/`ERR_SHOP_LIST_NOT_ACTIVE` → bỏ entry + xoá row, không chặn entry sau (có giá thì báo mất giá). (3) Race huỷ cặp lúc T1 đang bay → sau khi T1 về, nếu entry đã bị huỷ thì xếp toggle đảo lại từ state server. (4) Mất mạng sau khi mở picker → snackbar 'Cần mạng để giao việc'. (5) Bấm chip lúc đang đồng bộ → snackbar 'Đang đồng bộ…'. (6) 'Tôi nhận' chỉ khi role của chính mình thuộc whitelist (roster thắng, fallback JWT). (7) Badge 'Của tôi' chỉ hiện số khi > 0. (8) Mở picker khi roster lỗi hoặc từ cache → nạp lại. (9) `ShoppingItem.isAssignedTo` dùng chung cho badge + filter.
- **Ghi chú test:** fake `list()` trả rỗng giờ có nghĩa 'server đã xoá hết' (reconcile) — các test cũ đổi sang mirror dữ liệu cục bộ / server có món.
- **Đã chọn:** Như trên. · **Theo:** §6.0 quy tắc 3.
- **Đảo ngược thế nào:** —
- **Cần người quyết lại không:** Không.

### OD-24 · Dọn màn đi chợ — finding LOW còn lại sau 3 vòng review
- **Ngày:** 2026-10-19 · **Task:** dọn shopping · **Nhánh:** `chore/shopping-cleanup-od20-od22`
- **Tình huống:** (1) Drain gặp NOT_FOUND/LIST_NOT_ACTIVE vẫn bật banner 'giá chưa lưu — tick lại' dù row đã bị xoá; đường online không bật → không nhất quán, cần copy riêng. (2) `assign()` trả false khi row vừa bị reconcile xoá → snackbar 'Đang đồng bộ…' sai ngữ cảnh. (3) Mở picker khi roster từ cache → `loadRoster()` đặt Loading, chip nháy về skeleton; BE lỗi liên tục thì mỗi lần mở lại gọi thêm request. (4) Drain coi mọi BusinessException của CREATE (trừ IN_PROGRESS) là vĩnh viễn — nếu BE thêm 429 thì món bị xoá oan (OAS hiện chưa có 429). (5) Đảo lại sau race theo ngược trạng thái server; giá nhập lại trong lúc T1 đang bay bị mất. (6) Thiếu test UI: snackbar khi assign false, badge 'Của tôi' không số, nạp lại roster từ cache. (7) Lỗi cũ ngoài diff: `add()` online bị server từ chối xoá món + đóng sheet không báo.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Task dọn shopping tiếp theo.
- **Cần người quyết lại không:** Có cho (1) — câu chữ banner khi món đã bị xoá.

### OD-25 · On-device AI runtime (Epic 13, on-device-ai-runtime.md) — làm Slice 1/4/5/6, KHÔNG chọn runtime NN
- **Ngày:** 2026-10-19 · **Task:** #115 · **Nhánh:** `feature/on-device-ai-runtime`
- **Tình huống:** Người duyệt đã đồng ý thêm `tflite_flutter`/`onnxruntime_flutter`, nhưng Guard #2/§4.3 cấm chốt runtime khi chưa benchmark trên thiết bị vật lý (Q5), chưa có ngưỡng (Q2), chưa có model đã train (§14 mục 4). → KHÔNG thêm 2 package này ở lượt này.
- **Đã làm:** `AIResult<T>` + 2 mã `ERR_ONDEVICE_*` tách biệt; `ConnectivityGate` bọc `ConnectivityService` sẵn có (không thêm listener); `ModelRegistry` đọc `metadata.json` + verify SHA-256 (tự viết `lib/utils/sha256.dart` — package `crypto` ngoài danh sách D-05; có test vector FIPS), degrade theo từng task; `HybridAIRunner` viết bảng quyết định §8 MỘT lần cho mọi repository; Task 4 `OnDeviceMealSelectionRuleEngine` (lọc cứng dị ứng trước, xếp hạng mềm sau, tái chuẩn hoá khi thiếu tín hiệu — §6.4 AMEND) + `MealSelectionRepository`; `OfflineModeBanner`/`AIResultSourceBadge` (dùng `FeatureBanner`); wiring bootstrap; package `assets/models/rule_based_selection/v1`.
- **Lệch thiết kế:** (1) `MealCandidate` thêm `allergenTags` (null = chưa kiểm chứng → bị LOẠI khi household có dị ứng cần tránh) — thiếu nó không lọc cứng được. (2) Checksum là của file payload (`payloadFile` trong manifest), không phải của chính metadata.json (vòng tròn). (3) `isDegraded` = success && onDevice (kết quả lỗi không hiện banner, §9.3). (4) Trọng số `rules_config.json` là placeholder (Q1). (5) Receipt OCR / calorie / repetition: chưa có repository — engine báo `ERR_ONDEVICE_MODEL_UNAVAILABLE`; calorie cần nguồn `nutrition_table.json` (Q6).
- **Đã chọn:** Như trên. · **Theo:** Guard #2 + §6.0 quy tắc 2–3 + D-05.
- **Đảo ngược thế nào:** Slice 2 (benchmark thiết bị thật) → chốt runtime ở decision-log D1 → thêm package + engine cho 3 task NN.
- **Cần người quyết lại không:** Có — Q1 (trọng số), Q2 (ngưỡng benchmark), Q5 (thiết bị chuẩn), Q6 (nguồn nutrition table), owner train model.

### OD-26 · On-device AI — finding còn lại sau 3 vòng review
- **Ngày:** 2026-10-19 · **Task:** #115 · **Nhánh:** `feature/on-device-ai-runtime`
- **Tình huống:** (1) `cloud == null` lúc online vẫn chạy on-device → `isDegraded` = true → banner 'chế độ offline' hiện dù có mạng (cần cờ kiểu `isFallback` tách khỏi §9.3). (2) Payload hash trên main isolate + giữ trong RAM cả đời app — vô hại với rules_config, cần xem lại khi có model NN vài MB. (3) So khớp dị ứng phân biệt hoa/thường, chưa chuẩn hoá — chưa xác nhận là bug (cần đối chiếu định dạng id dị ứng ở OAS). (4) `loadIfNeeded` gọi 2 lần (runner + engine). (5) `?? 0` ở trọng số là code chết sau khi `fromConfig` đã bắt buộc đủ key. (6) Thư mục untracked `web/`, `windows/` + dòng `web/**` trong analysis_options ngoài phạm vi task — KHÔNG đưa vào PR này.
- **Đã sửa ở vòng 3:** `.gitattributes` `assets/models/** -text` (autocrlf làm lệch checksum); `ModelRegistry.bootstrap()` chạy song song các task. Vòng 2: dời `AllergenDerivation` sang `lib/domain/shared/` (tầng data không phụ thuộc scenes; file cũ re-export).
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Khi feature đầu tiên tiêu thụ `MealSelectionRepository` / khi có model NN.
- **Cần người quyết lại không:** Có cho (1) — banner khi chạy cục bộ lúc online; (3) — định dạng id dị ứng.

### OD-27 · Dọn OD-18 (cooking retry + tuổi người phụ thuộc) — đã làm & còn lại
- **Ngày:** 2026-10-20 · **Task:** dọn OD-18 · **Nhánh:** `chore/cleanup-od18`
- **Đã làm:** 'Thử lại' trên snackbar lỗi cooking gọi lại ĐÚNG thao tác vừa lỗi (advance → quay về bước hiện tại trước; complete; resync) — abandon không có 'Thử lại' (dialog Huỷ bỏ vẫn mở); thao tác mới huỷ retry cũ; snackbar ẩn → dọn `actionError`; lỗi bị xoá/thay → ẩn snackbar cũ (SnackBar có action là persist trên Flutter 3.47); ngày sinh tương lai → chỉ hiện ngày, không tuổi âm. Test widget snackbar 1 lần/instance, retry thật, tuổi.
- **Còn lại:** (1) Cơ chế snackbar nên chuyển sang `reaction` theo `actionError` trong State (bỏ Expando + post-frame; hide hiện có thể ẩn nhầm snackbar khác đang xếp trước). (2) Mọi ApiException của advance/complete đều có 'Thử lại', kể cả lỗi chắc chắn lặp lại (AuthExpired, 404) — cần danh sách non-retryable như phần load. (3) Retry complete không quay về bước hiện tại như retry advance. (4) Retry resync không bật cờ loading → nút chính vẫn bấm được. (5) `canRetryAction` đọc field thường, không Observable.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Task dọn cooking tiếp theo.
- **Cần người quyết lại không:** Có cho (2) — lỗi nào được 'Thử lại'.

### OD-28 · Dọn OD-27 (snackbar lỗi cooking) — đã làm & còn lại
- **Ngày:** 2026-10-20 · **Task:** dọn OD-27 · **Nhánh:** `chore/cooking-od27`
- **Đã làm:** Snackbar lỗi thao tác chuyển sang `reaction` theo `actionError` trong State (bỏ Expando/post-frame; chỉ đóng snackbar khi đã hiện — `onVisible`); bị snackbar khác đẩy ra thì xếp hiện lại, không xoá lỗi; rời màn → dọn lỗi + đóng snackbar. Không 'Thử lại' cho AuthExpired, ValidationException, `ERR_SESSION_NOT_FOUND`, `ERR_SESSION_NO_HOUSEHOLD` (người duyệt chốt 2026-10-20). Retry complete quay về bước hiện tại; `isResyncing` (bộ đếm) khoá nút chính; kết quả advance/resync về muộn sau abandon/complete/dispose bị bỏ (không timer mồ côi); `canRetryAction` là Observable.
- **Còn lại:** (1) Snackbar lỗi đang XẾP HÀNG lúc rời màn chớp ~250ms ở màn trước rồi tự đóng (Flutter không gỡ riêng được 1 snackbar trong hàng). (2) Bản debug + TalkBack: đóng snackbar trong `dispose` có thể báo setState khi cây khoá. (3) Chưa có test cho advance về muộn sau abandon và 2 resync chồng nhau. (4) Mã non-retryable lặp 2 mã với `_nonRetryableLoadErrorCodes`.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Nếu cần triệt để (1)(2): đổi snackbar lỗi thành banner inline trong Observer.
- **Cần người quyết lại không:** Không.

### OD-29 · Chip giao việc khoá khi offline (đảo ngược OD-21 (1)) — đã làm & còn lại
- **Ngày:** 2026-10-20 · **Task:** #134 · **Nhánh:** `feature/134_assignee-offline-chip`
- **Đã làm:** `ConnectivityService.isOnlineNow` (MobX Observable, cập nhật theo `onConnectivityChanged` và mỗi lần `isOnline()`); chip giao việc disabled + bấm hiện 'Cần mạng để giao việc' khi offline, đúng shopping-list-screen §9.5; bấm chip đang khoá thì kiểm lại mạng thật (stream lỡ sự kiện → chip tự mở); `isOnline()` thấy offline thì ghi `_wasOffline` để lần có mạng sau vẫn phát `onConnectivityRestored`.
- **Còn lại:** (1) Bấm chip khoá mà kiểm lại thấy đã online → chip mở nhưng lần bấm đó không mở picker (phải bấm lại). (2) Sau await trong `onDisabledTap` vẫn đọc `item.isPendingSync` lúc build. (3) Test: chip đọc `ConnectivityService` thật, store dùng fake riêng — nên đưa trạng thái online vào 1 nguồn. (4) 3 biến cùng theo dõi online (`_wasOffline`, `_online`, `ConnectivitySignal`). (5) `Get.find<ConnectivityService>()` mỗi dòng lúc build.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Task dọn shopping tiếp theo.
- **Cần người quyết lại không:** Có cho (1) — có mở picker luôn khi kiểm lại thấy online không.

### OD-30 · Chia sẻ + quản lý danh mục đi chợ (#69, shopping-share-category.md) — lệch thiết kế theo code thật
- **Ngày:** 2026-10-20 · **Task:** #69 · **Nhánh:** `feature/69_shopping-share-category`
- **Tình huống:** (1) Repo KHÔNG có `QuickAddSheet`/ô nhập category tự do/`knownCategories` như thiết kế giả định — sheet thêm món là `_showAddDialog` trong scene với hàng ChoiceChip cố định → chip gợi ý = category local (màu, thứ tự người dùng) + category đã dùng trên món + bộ mặc định cũ, không trùng (hoa/thường). (2) Lỗi validate của `CategoryStore` là enum `CategoryError` dịch qua l10n thay vì `String` tiếng Việt (luật không hardcode text); vẫn KHÔNG phải ApiException (Guard #9). (3) Không có package `uuid` → id `cat-<micros>-<rand>` như id tạm của shopping. (4) Flutter 3.47: `ReorderableListView.onReorder` deprecated → dùng `onReorderItem` (đã trừ sẵn chỉ số) — bước -1 của Guard #6 không còn áp dụng. (5) Row Drift đặt `@DataClassName('ShoppingCategoryRow')` để không trùng model domain. (6) Chuỗi share text lấy từ l10n, truyền vào builder qua `ShoppingShareLabels` (builder vẫn pure, Guard #7). (7) Sửa kèm: dropdown đơn vị trong sheet thêm món tràn ngang với nhãn dài → `isExpanded: true`.
- **Đã chọn:** Như trên. · **Theo:** §6.0 quy tắc 2–3 + AGENTS.md (không hardcode text, không thêm package ngoài D-05).
- **Đảo ngược thế nào:** Khi BE có category CRUD/share-link (Q1/Q2 của thiết kế) → thiết kế lượt riêng.
- **Cần người quyết lại không:** Không.

### OD-31 · Chia sẻ + danh mục đi chợ (#69) — finding còn lại sau 3 vòng review
- **Ngày:** 2026-10-20 · **Task:** #69 · **Nhánh:** `feature/69_shopping-share-category`
- **Đã sửa trong 3 vòng:** xoá/sắp xếp optimistic + trả đúng snapshot khi ghi lỗi + snackbar; sortOrder mới = max+1 (không trùng sau khi xoá); `update()` chỉ ghi tên + màu; lỗi đọc/ghi Drift → `saveFailed` (không kẹt dialog); stream lỗi → màn hiện lỗi + thử lại; nạp lại cùng household không nháy loading, gọi song song không rò subscription.
- **Còn lại:** (1) `CategoryStore.dispose()` không được GetX gọi khi xoá instance `lazyPut(fenix)` — cùng kiểu `ShoppingStore` hiện có. (2) Đổi household khi tab đi chợ đã dựng → chip category không nạp lại tới khi mở màn quản lý. (3) `/shopping/categories` mở trực tiếp (deep link/web reload) → `Get.find<CategoryStore>()` crash — đúng ràng buộc Guard #11 (chỉ push từ màn đi chợ). (4) Giới hạn 100 đếm theo UTF-16 (khớp BE) còn ô nhập đếm theo ký tự hiển thị — emoji lệch. (5) Share text ghép số lượng + đơn vị không dấu cách ('2cái'), theo đúng mẫu §11. (6) Hàm định dạng số lượng lặp ở 3 nơi. (7) Thêm category đọc bảng 2 lần.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Task dọn shopping tiếp theo.
- **Cần người quyết lại không:** Có cho (5) — có thêm dấu cách '2 cái' không.

### OD-32 · Dọn đi chợ (OD-29 + OD-31) — đã làm & còn lại
- **Ngày:** 2026-10-20 · **Task:** dọn shopping · **Nhánh:** `chore/shopping-cleanup-od29-od31`
- **Đã làm:** bấm chip giao việc đang khoá mà kiểm lại thấy có mạng → mở picker luôn (đọc lại món mới nhất sau await; món đã bị gỡ/đang gán thì không mở); share text '2 cái' (người duyệt chốt 2026-10-20), đơn vị rỗng không thừa khoảng trắng; mở sheet thêm món nạp lại danh mục (đổi household → xoá danh mục cũ ngay; rollback ghi lỗi không đè sang household mới); gom `formatQuantity`/`formatQuantityWithUnit` vào `lib/utils/quantity_format.dart` (vô cực/NaN không crash).
- **Còn lại:** (1) **`ShoppingStore` và `CategoryStore` không tự theo dõi `session.householdId`** — đổi household khi tab đi chợ đã dựng thì danh sách món vẫn của household cũ (có từ trước, cần reaction trong store — đổi vòng đời store). (2) Món tạo offline vừa đồng bộ xong trong lúc kiểm mạng đổi id (`local-…` → id server) → vẫn báo 'đang đồng bộ'. (3) Bấm nhanh 2 lần có thể mở 2 picker (cả đường onTap cũ). (4) Đang gán (`isAssigning`) mà bấm chip khoá → báo 'đang đồng bộ' (sai lý do, cần chuỗi mới). (5) Hàm định dạng số lượng còn ở `recipe_detail_scene`, `ocr_item_card`, `calorie_confirm_sheet`.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** (1) task riêng: store nghe `householdId` bằng reaction.
- **Cần người quyết lại không:** Có cho (1) — duyệt đổi vòng đời store.

### OD-33 · Store permanent bám household (đảo ngược OD-32 (1)) — đã làm & còn lại
- **Ngày:** 2026-10-20 · **Task:** OD-32 (1) · **Nhánh:** `fix/household-scoped-store-reset`
- **Đã làm:** `ShoppingStore`/`InventoryStore` (permanent, sống qua logout) tự nghe `session.householdId` bằng MobX `reaction` (cùng pattern `RealtimeStore`): đổi household/logout → huỷ luồng Drift cũ, xoá dữ liệu + lỗi + bộ lọc cũ, nghe lại; `init()` idempotent theo household. Sync/drain của household cũ về muộn: không reconcile-xoá kho household mới, không ghi lỗi sang household mới, drain dừng khi household đổi (không gửi thao tác h1 bằng token h2) và chạy bù drain cho household mới. Các store `fenix` khác được tạo lại sau `offAllNamed`.
- **Còn lại:** (1) Request đang bay đúng lúc đổi household không huỷ được — nếu server nhận thì vẫn lọt. (2) Đổi A→B→A trong lúc sync: điều kiện so household vẫn đúng → có thể reconcile nhầm (cần số đếm thế hệ/epoch). (3) `add`/`toggle`/`assign` đang chạy dở vẫn ghi lỗi không kiểm household. (4) Ô tìm kiếm kho không có controller → sau reset vẫn hiện chữ cũ. (5) Logic bám household chép ở 2 store — nên gom mixin/epoch khi có store thứ 3. (6) Các nhánh sửa ở vòng 3 (drain dừng/chạy bù, `_isSyncing`) chưa có test riêng.
- **Đã chọn:** Hoãn. · **Theo:** §3 (tối đa 3 vòng) + §6.1 D-10.
- **Đảo ngược thế nào:** Task riêng: epoch dùng chung cho mọi tác vụ bất đồng bộ theo household.
- **Cần người quyết lại không:** Không.

### OD-34 · Áp quyết định OD-24 (1) + OD-26 (1)(3) — đã làm & còn lại
- **Ngày:** 2026-10-20 · **Task:** quyết định người duyệt 2026-10-20 · **Nhánh:** `chore/decisions-od24-od26`
- **Đã làm:** OD-26 (1) — `AIResult.offlineFallback` (bắt buộc truyền ở `fromOnDevice`/`runOnDevice`); `isDegraded` chỉ khi chạy on-device VÌ offline → không banner "chế độ offline" lúc online. OD-26 (3) — so khớp dị ứng không phân biệt hoa/thường + bỏ khoảng trắng (trong rule engine). OD-24 (1) — lý do mất giá thành tập `PriceLostReason {stale, itemDeleted, listClosed}`, banner hiện đủ mọi lý do: "Món đã bị xoá trên máy khác…", "Danh sách đã sang tuần mới…" (câu theo khuyến nghị, người duyệt giao chọn), cả đường online lẫn drain; không ghi lý do sang household khác.
- **Còn lại:** (1) Mỗi lần tick xoá mọi lý do mất giá — kể cả lý do drain vừa báo (hành vi cũ). (2) Chuẩn hoá dị ứng mới ở rule engine — model/parse (`MealSuggestion`, candidate) vẫn giữ chuỗi gốc; chưa xử lý 'TREE NUT' vs 'TREE_NUT' (chưa rõ định dạng BE). (3) Exclusion rỗng sau trim vẫn tính là ràng buộc (giữ vì an toàn hơn).
- **Đã chọn:** Hoãn phần còn lại. · **Theo:** §3 + §6.1 D-10.
- **Đảo ngược thế nào:** (2) chuẩn hoá ở tầng parse khi chốt định dạng mã dị ứng với BE.
- **Cần người quyết lại không:** Không.

### OD-35 · Epoch household dùng chung (đảo ngược OD-33) — đã làm & còn lại
- **Ngày:** 2026-10-20 · **Task:** OD-33 · **Nhánh:** `fix/household-epoch-od33`
- **Đã làm:** mixin `HouseholdScoped` (`lib/stores/household_scoped.dart`): reaction theo `householdId` + epoch tăng mỗi lần đổi household và khi dispose; `ShoppingStore`/`InventoryStore` dùng chung, bỏ code chép. Sync/drain/add/toggle/assign/báo mất giá/`_isSyncing` so epoch (đúng cả A→B→A); drain dừng + chạy bù chỉ khi store còn bind; ô tìm kiếm kho có controller, tự xoá khi store reset. Test: A→B→A, drain dừng/chạy bù, `_isSyncing`, lỗi household cũ, dispose, ô tìm.
- **Còn lại:** (1) 2 lần sync CÙNG household chạy chồng: lần xong trước tắt `isSyncing` của lần kia (có từ trước). (2) Shopping `sync()` không kiểm epoch sau `list()` (list truyền householdId tường minh — rủi ro thấp). (3) Test chờ bằng delay cố định 20ms — có thể chập chờn trên CI chậm. (4) Epoch tăng 2 lần mỗi lần đổi (reaction + rebind) — cố ý phòng hờ.
- **Đã chọn:** Hoãn. · **Theo:** §3 + §6.1 D-10.
- **Đảo ngược thế nào:** —
- **Cần người quyết lại không:** Không.
