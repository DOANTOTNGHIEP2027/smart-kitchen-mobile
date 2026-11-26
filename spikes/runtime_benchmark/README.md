# Spike benchmark gate — chọn runtime on-device (#116)

Project Flutter **riêng**, không ship, không phải dependency của app chính. Mục đích duy nhất: đo
5 metric (on-device-ai-runtime.md §4.3) cho 3 ứng viên trên **thiết bị vật lý thật**, rồi chọn
runtime theo công thức ở `RESULT_TEMPLATE.md`. Emulator/simulator chỉ dùng để loại sớm runtime
hỏng hẳn, **không** dùng làm căn cứ chốt.

| Runtime | Package (ghim) | Android | iOS |
|---|---|---|---|
| TFLite | `tflite_flutter: 0.12.1` | CPU · GPU (`GpuDelegateV2`) · NNAPI | CPU · Metal (`GpuDelegate`) · CoreML |
| ONNX Runtime | `flutter_onnxruntime: 1.9.0` | CPU · NNAPI EP | CPU · CoreML EP |
| ML Kit Text Recognition | `google_mlkit_text_recognition: 0.17.1` | bundled | bundled |

Ghi chú package:
- `onnxruntime_flutter` (tên trong issue) **không tồn tại** trên pub.dev. `onnxruntime` (gói cũ) không
  cập nhật từ 03/2024 ⇒ dùng `flutter_onnxruntime` (ORT 1.28.0).
- ML Kit: plugin dùng `com.google.mlkit:text-recognition` = biến thể **bundled** (model Latin nằm
  trong APK), không tải model qua Play Services lúc runtime (Guard #6).

## Chuẩn bị (người chạy tự làm)

1. Đặt file vào `assets/` (đã gitignore — giấy phép model do bạn chịu trách nhiệm):
   - `assets/models/ocr.tflite`, `assets/models/ocr.onnx` — **cùng một** model OCR ở 2 định dạng.
   - `assets/receipt_sample.jpg` — một ảnh hoá đơn thật (cho ML Kit).
2. Sửa `lib/bench/model_config.dart` cho khớp shape input của model.
3. iOS (cần macOS + Xcode): `ios/Podfile` đặt `platform :ios, '16.0'` và
   `use_frameworks! :linkage => :static` (yêu cầu của `flutter_onnxruntime`; ML Kit cần ≥ 15.5).

## Chạy

```bash
flutter run --release -d <device-id>      # release: số đo debug/JIT vô nghĩa
```

1. Nhập model máy → **Chạy** với `Số vòng = 1` → **Copy JSON**.
2. **Cold load thật**: kill app, mở lại, chỉ tick 1 cấu hình, chạy 1 vòng. Lặp cho từng cấu hình.
   (Chạy chung nhiều cấu hình thì cấu hình sau hưởng thư viện native đã nạp.)
3. **Crash-free**: `Reset ledger`, chạy `Số vòng = 30`. Crash native làm app chết ⇒ mở lại app, marker
   còn sót được tính là 1 crash. Mở lại app rồi chạy tiếp cho đủ vòng.
4. **App size**: `bash tool/size_matrix.sh` (Android) · `PLATFORM=ios bash tool/size_matrix.sh` (macOS).
   Con số là phần tăng do **thư viện runtime**; dung lượng file model cộng riêng.

Điền kết quả vào `RESULT_TEMPLATE.md`, rồi chép sang
`ai-native/reports/design/on-device-ai-runtime/decision-log.md` (D1-update) ở phiên của repo đó.

## Giới hạn đã biết

- ONNX & ML Kit đi qua MethodChannel ⇒ latency đo ở Dart gồm overhead channel (đó cũng là chi phí
  app thật phải trả). TFLite gọi FFI trực tiếp.
- ONNX: không kiểm được bao nhiêu node thực sự chạy trên NNAPI/CoreML — EP thiếu op sẽ âm thầm về
  CPU. Đọc từ "delegate speedup": ≈1.0 nghĩa là EP gần như không giúp gì.
- Input tflite/onnx là tensor 0 (latency mạng tích chập không phụ thuộc giá trị); ML Kit dùng ảnh thật.
