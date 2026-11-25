import '../../../../data/ai_runtime/tasks/receipt_ocr_task.dart';
import '../../../../utils/sha256.dart';
import 'ocr_api.dart';

/// Đường cloud của `ReceiptOcrRepository` (on-device-ai-runtime.md §6.5.1) —
/// bọc endpoint thật #38 qua [OcrApi] (#57).
///
/// `X-Idempotency-Key` = SHA-256 của ảnh: thử lại cùng ảnh (vd. sau
/// NetworkException) dùng CÙNG key → BE trả kết quả cache / 409 thay vì gọi
/// AI lần 2 (Guard 3 của #57). Ảnh phải ĐÃ nén ≤2MB — adapter không nén.
ReceiptOcrCloudScan receiptOcrCloudScan(OcrApi api) => (imageBytes) async {
      final result = await api.scan(
        imageBytes: imageBytes,
        idempotencyKey: sha256Hex(imageBytes),
      );
      return ReceiptOcrResult(
        items: result.items
            .map((item) => ReceiptLineItem.fromCloudScan(
                  name: item.name,
                  quantity: item.quantity,
                  unit: item.unit,
                ))
            .toList(growable: false),
      );
    };
