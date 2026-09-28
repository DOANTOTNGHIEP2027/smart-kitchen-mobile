import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../domain/ocr_scan_result.dart';

const int maxOcrImageBytes = 2 * 1024 * 1024;

class OcrImageTooLargeException implements Exception {
  const OcrImageTooLargeException();
}

class OcrImageInvalidException implements Exception {
  const OcrImageInvalidException();
}

class OcrPermissionDeniedException implements Exception {
  const OcrPermissionDeniedException();
}

abstract interface class OcrImagePicker {
  Future<Uint8List?> pick(OcrImageSource source);
}

class DeviceOcrImagePicker implements OcrImagePicker {
  DeviceOcrImagePicker({picker.ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? picker.ImagePicker();

  final picker.ImagePicker _imagePicker;

  @override
  Future<Uint8List?> pick(OcrImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source == OcrImageSource.camera
            ? picker.ImageSource.camera
            : picker.ImageSource.gallery,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      if (code.contains('denied') || code.contains('permission')) {
        throw const OcrPermissionDeniedException();
      }
      rethrow;
    }
  }
}

abstract interface class OcrImageCompressor {
  Future<Uint8List> compress(Uint8List bytes);
}

class FlutterOcrImageCompressor implements OcrImageCompressor {
  const FlutterOcrImageCompressor();

  @override
  Future<Uint8List> compress(Uint8List bytes) async {
    if (bytes.isEmpty) throw const OcrImageInvalidException();
    var quality = 88;
    Uint8List output = bytes;
    do {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1600,
        minHeight: 1600,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (compressed.isEmpty) throw const OcrImageInvalidException();
      output = compressed;
      quality -= 15;
    } while (output.lengthInBytes > maxOcrImageBytes && quality >= 28);

    if (output.lengthInBytes > maxOcrImageBytes) {
      throw const OcrImageTooLargeException();
    }
    return output;
  }
}
