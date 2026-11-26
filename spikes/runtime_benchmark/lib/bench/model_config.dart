/// Cấu hình model benchmark — SỬA cho khớp model OCR thật đặt vào `assets/`.
library;

const kTfliteAsset = 'assets/models/ocr.tflite';
const kOnnxAsset = 'assets/models/ocr.onnx';

/// Ảnh hoá đơn mẫu — ML Kit cần ảnh thật; tflite/onnx dùng tensor 0.
const kReceiptImageAsset = 'assets/receipt_sample.jpg';

/// Shape input khi model có chiều động (-1). Mặc định theo kiểu model nhận
/// dạng dòng chữ 48×320 — ĐỔI nếu model của bạn khác. ONNX trên iOS bắt buộc
/// dùng giá trị này (plugin không trả shape input trên iOS).
const kOcrInputShapeNhwc = [1, 48, 320, 3];
const kOcrInputShapeNchw = [1, 3, 48, 320];

const kCpuThreads = 4;
