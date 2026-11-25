import 'dart:typed_data';

import '../ai_result.dart';
import '../engine/ai_task.dart';
import '../engine/on_device_inference_engine.dart';
import '../hybrid_ai_runner.dart';

/// Task 1 — quét hoá đơn bằng OCR (on-device-ai-runtime.md §6.1, §6.5).
class ReceiptLineItem {
  const ReceiptLineItem({
    required this.rawName,
    this.quantity,
    this.unit,
    this.price,
    this.confidence,
  });

  /// Nhánh cloud (§6.5.2) — map CÓ MẤT THÔNG TIN từ item #38 đã match phía
  /// BE: `rawName` nhận tên cloud ĐÃ chuẩn hoá (ngoại lệ D11/Guard #8);
  /// `price`/`confidence` BE không trả.
  factory ReceiptLineItem.fromCloudScan({
    required String name,
    double? quantity,
    String? unit,
  }) =>
      ReceiptLineItem(rawName: name, quantity: quantity, unit: unit);

  /// Nhánh on-device: dòng OCR NGUYÊN VĂN trên hoá đơn — KHÔNG phải tên đã
  /// chuẩn hoá/khớp với inventory item nào (Guard #8, Q8).
  final String rawName;
  final double? quantity;
  final String? unit;

  /// Thành tiền của dòng (số cuối dòng) — `null` khi không chắc.
  final double? price;
  final double? confidence;
}

class ReceiptOcrResult {
  const ReceiptOcrResult({required this.items});
  final List<ReceiptLineItem> items;
}

class ReceiptOcrInput implements InferenceInput {
  const ReceiptOcrInput(this.imageBytes);
  final Uint8List imageBytes;
}

class ReceiptOcrOutput implements InferenceOutput {
  const ReceiptOcrOutput(this.lines, {this.confidence});
  final List<String> lines;

  @override
  final double? confidence;
}

/// Dòng OCR → [ReceiptLineItem] — chỉ điền khi chắc chắn, còn lại `null`
/// (§6.5.3). Không đoán ngữ nghĩa dòng (dòng tổng vẫn thành item — Q8).
abstract final class ReceiptLineParser {
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _quantity = RegExp(
    r'(?<![\p{L}\d.,])(\d+(?:[.,]\d+)?)\s?(kg|g|ml|l|quả|cái)(?![\p{L}\d])',
    unicode: true,
    caseSensitive: false,
  );
  static final RegExp _thousands = RegExp(r'^[1-9]\d{0,2}(?:[.,]\d{3})+$');
  static final RegExp _price = RegExp(
    r'(?<![\p{L}\d.,/:])([1-9]\d{0,2}(?:[.,]\d{3})+|[1-9]\d{3,8})\s*(?:đ|vnd|₫|d)?\s*$',
    unicode: true,
    caseSensitive: false,
  );

  static ReceiptOcrResult parse(List<String> lines, {double? confidence}) {
    final items = <ReceiptLineItem>[];
    for (final line in lines) {
      final text = line.trim();
      if (!_letter.hasMatch(text)) continue;

      double? quantity;
      String? unit;
      final q = _quantity.firstMatch(text);
      if (q != null && !_thousands.hasMatch(q.group(1)!)) {
        quantity = double.parse(q.group(1)!.replaceAll(',', '.'));
        unit = q.group(2)!.toLowerCase();
      }

      double? price;
      final p = _price.firstMatch(text);
      // Lưới an toàn theo §6.5.3 — với tập đơn vị/hậu tố tiền hiện tại 2 đoạn
      // không thể chồng nhau; giữ để không đếm trùng nếu sau này mở rộng.
      final overlapsQuantity =
          p != null && q != null && p.start < q.end && q.start < p.end;
      if (p != null && !overlapsQuantity) {
        price = double.parse(p.group(1)!.replaceAll(RegExp('[.,]'), ''));
      }

      items.add(ReceiptLineItem(
        rawName: text,
        quantity: quantity,
        unit: unit,
        price: price,
        confidence: confidence,
      ));
    }
    return ReceiptOcrResult(items: items);
  }
}

abstract class ReceiptOcrRepository {
  Future<AIResult<ReceiptOcrResult>> scan(Uint8List imageBytes);
}

/// Đường cloud — inject từ ngoài (adapter bọc `OcrApi` ở
/// `scenes/inventory/ocr/data/receipt_ocr_cloud.dart`) để tầng data không
/// phụ thuộc scenes. Input là ảnh ĐÃ nén ≤2MB (§6.5.1).
typedef ReceiptOcrCloudScan = Future<ReceiptOcrResult> Function(
    Uint8List imageBytes);

/// Bảng §8 nằm trong [HybridAIRunner] — repository không chép lại (§6.5.1).
class ReceiptOcrRepositoryImpl implements ReceiptOcrRepository {
  ReceiptOcrRepositoryImpl(this._runner, {ReceiptOcrCloudScan? cloud})
      : _cloud = cloud;

  final HybridAIRunner _runner;
  final ReceiptOcrCloudScan? _cloud;

  @override
  Future<AIResult<ReceiptOcrResult>> scan(Uint8List imageBytes) {
    final cloud = _cloud;
    return _runner.run<ReceiptOcrResult>(
      task: AITask.receiptOcr,
      cloud: cloud == null ? null : () => cloud(imageBytes),
      cloudModelUsed: 'cloud:inventory-items-scan#38',
      input: ReceiptOcrInput(imageBytes),
      fromOutput: (o) {
        final out = o as ReceiptOcrOutput;
        return ReceiptLineParser.parse(out.lines, confidence: out.confidence);
      },
    );
  }
}
