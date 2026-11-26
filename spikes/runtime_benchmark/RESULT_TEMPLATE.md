# Kết quả benchmark gate — D1-update (#116)

> Điền bằng số đo thật, kèm file JSON gốc. Ô nào chưa đo ghi `—`, không ước lượng.

## Đầu vào

- Ngưỡng cứng (open-questions Q2): `<số đã được product/QA chốt>` — nếu chưa chốt, ghi rõ
  **PLACEHOLDER**: warm p95 ≤ 2× thời gian chờ trung bình của cùng tác vụ trên cloud (mạng tốt) = `___ ms`.
- App size tăng tối đa: `___ MB` · crash-free tối thiểu: `___ %`
- Thiết bị chuẩn (Q5): Android `________` (Android __) · iOS `________` (iOS __)
- Model: `________` (nguồn, version, kích thước `.tflite` / `.onnx`)
- Build: `flutter run --release`, commit spike `_______`

## Số đo

| Thiết bị | Cấu hình | Cold load (ms) | Warm p50 (ms) | Warm p95 (ms) | Delegate speedup (×CPU) | Crash-free (n phiên) | App size (+MB) |
|---|---|---|---|---|---|---|---|
| Android | tflite/cpu | | | | — | | |
| Android | tflite/gpu | | | | | | ↑ cùng |
| Android | tflite/nnapi | | | | | | ↑ cùng |
| Android | onnx/cpu | | | | — | | |
| Android | onnx/nnapi | | | | | | ↑ cùng |
| Android | mlkit/bundled | | | | — | | |
| iOS | tflite/cpu | | | | — | | |
| iOS | tflite/gpu (Metal) | | | | | | ↑ cùng |
| iOS | tflite/coreml | | | | | | ↑ cùng |
| iOS | onnx/cpu | | | | — | | |
| iOS | onnx/coreml | | | | | | ↑ cùng |
| iOS | mlkit/bundled | | | | — | | |

Mỗi runtime lấy **cấu hình delegate tốt nhất** trên từng thiết bị để so ở bước dưới.

## Áp công thức (§4.3 mục 4) — làm tuần tự, không bỏ bước

1. **Loại** runtime fail bất kỳ ngưỡng cứng nào trên bất kỳ thiết bị chuẩn nào: `________`
2. Trong số còn lại, chọn **warm p95 thấp hơn**: `________`
3. Nếu chênh p95 nằm trong biên sai số đo (khoảng max−min giữa các lần chạy lặp): **tie-break app
   size nhỏ hơn**: `________`

**Runtime thắng:** `________`

- [ ] Nếu ML Kit thắng receipt-ocr: xác nhận biến thể bundled (`com.google.mlkit:text-recognition`,
      không phải `play-services-mlkit-text-recognition`) — không tải model qua mạng lúc runtime.
