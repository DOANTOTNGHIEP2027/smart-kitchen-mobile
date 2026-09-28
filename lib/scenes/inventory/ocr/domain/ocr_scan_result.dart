import 'ocr_item.dart';

class OcrScanResult {
  const OcrScanResult({required this.scanId, required this.items});

  final String scanId;
  final List<OcrItem> items;
}

enum OcrScanMode { item, receipt }

enum OcrImageSource { camera, gallery }
