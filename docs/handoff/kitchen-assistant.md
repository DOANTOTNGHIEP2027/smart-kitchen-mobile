# Bàn giao — Kitchen Assistant (phía Frontend)

> Ngày bàn giao: 2026-11-16. Phần FE **chưa bắt đầu**; tài liệu này gom đủ để người phụ trách FE làm mà không phải
> hỏi lại. Người bàn giao (HieuNT316) chuyển sang phần AI (chương 3–4 đồ án).

## 1. Đọc trước

| Tài liệu (repo `ai-native`, nhánh `docs/assistant-neo4j-design`) | Dùng để |
|---|---|
| `docs/design/frontend/kitchen-assistant.md` | thiết kế FE — **nguồn chính**: điểm vào, cấu trúc code, store MobX, trạng thái S1–S11 |
| `docs/design/frontend/mockups/kitchen-assistant.html` | mockup mở bằng trình duyệt |
| `docs/design/backend-server/kitchen-assistant.md` §2 | API, shape response, bảng `reply_status` (gửi lại) |

Ý tưởng chính: trợ lý là **nút nổi (FAB) trên mọi tab**, không chỉ trong màn nấu — người dùng hỏi nấu gì, thay
nguyên liệu, đi chợ… ở bất kỳ đâu; màn nấu / màn thực đơn chỉ mở phiên có ngữ cảnh sẵn.

## 2. Backend đã sẵn sàng

Nhánh BE `feature/ka-be-1_assistant-sessions` (chưa merge main; bật bằng `ASSISTANT_ENABLED=true`):

| Method | Path | Body / ghi chú |
|---|---|---|
| `POST` | `/v1/assistant/sessions` | `{contextType: GLOBAL\|COOKING\|PLANNING\|SHOPPING, mealPlanId?, slotId?, cookingSessionId?}` — COOKING cần `cookingSessionId` (phiên nấu đang dở), PLANNING cần `mealPlanId` + `slotId` |
| `GET` | `/v1/assistant/sessions` | 20 phiên gần nhất |
| `GET` | `/v1/assistant/sessions/{id}/messages` | 30 message gần nhất |
| `POST` | `/v1/assistant/sessions/{id}/messages` | `{text, clientTurnId, currentStep?}` |

Ba điều FE phải làm đúng:
1. **`clientTurnId`** (uuid) sinh một lần cho mỗi câu hỏi và **giữ nguyên khi bấm "Gửi lại"** — BE dựa vào nó để
   không gọi AI hai lần. Nhận `409 ERR_ASSISTANT_TURN_IN_FLIGHT` ⇒ lần trước còn đang chờ: không báo lỗi, tải lại
   lượt sau 5 s.
2. **Phiên COOKING gửi `currentStep`** (bước đang mở trên máy, 1-based) mỗi lượt. Thiếu/sai ⇒
   `422 ERR_ASSISTANT_CONTEXT_INVALID`.
3. `fallback = true` trong response ⇒ câu trả lời từ luật (AI không có LLM) — vẫn hiển thị bình thường, có thể gắn
   nhãn nhỏ.

Mã lỗi khác: `ERR_ASSISTANT_DISABLED`, `ERR_ASSISTANT_NO_HOUSEHOLD`, `ERR_ASSISTANT_SESSION_NOT_FOUND`,
`ERR_ASSISTANT_SESSION_CLOSED` (đã rời hộ ⇒ phiên chỉ đọc), `ERR_AI_TIMEOUT`, `ERR_AI_SERVICE_DOWN`.

## 3. Việc cần làm

| Slice | Nội dung | Phụ thuộc BE |
|---|---|---|
| **KA-FE-1** | FAB + `AssistantScene` + trạng thái S1, S3, S4, S8, S9, S10, S11 (phiên GLOBAL) | KA-BE-1 — **có rồi** |
| **KA-FE-2** | điểm vào COOKING (từ màn nấu, gửi `currentStep`) / PLANNING (từ slot thực đơn) + S2, S5 | KA-BE-2 — **có rồi** |
| **KA-FE-3** | thẻ hành động S6, S7 (xác nhận / huỷ) | KA-BE-3 — **chưa có** |

KA-FE-1 và KA-FE-2 làm được ngay.
