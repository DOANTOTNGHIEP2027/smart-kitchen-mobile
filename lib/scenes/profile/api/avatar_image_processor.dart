import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart' as picker;

/// Lỗi phía client khi xử lý ảnh avatar — dùng chung mã với BE
/// (`object-storage.yaml`) để dùng chung copy l10n (§12).
class AvatarImageException implements Exception {
  const AvatarImageException.invalid() : code = 'ERR_FILE_INVALID';
  const AvatarImageException.tooLarge() : code = 'ERR_FILE_TOO_LARGE';

  final String code;

  @override
  String toString() => 'AvatarImageException($code)';
}

/// Người dùng từ chối quyền camera/thư viện ảnh.
class AvatarPermissionDeniedException implements Exception {
  const AvatarPermissionDeniedException();
}

/// Nén ảnh avatar trước khi upload (Decision D11, Guard 1).
abstract interface class AvatarImageProcessor {
  /// Trả bytes JPEG sẵn sàng cho `POST /api/v1/files`. Ném
  /// [AvatarImageException] khi ảnh không giải mã được / vẫn quá lớn — khi đó
  /// KHÔNG được gọi API.
  Future<Uint8List> process(Uint8List picked);
}

/// Re-encode 1 lần sang JPEG ≤ 512px (loại luôn HEIC/WebP — BE chỉ nhận
/// JPEG/PNG theo magic bytes), rồi kiểm < [targetBytes]. Cùng pattern
/// `FlutterOcrImageCompressor`; không thêm dependency.
class FlutterAvatarImageProcessor implements AvatarImageProcessor {
  const FlutterAvatarImageProcessor();

  static const int targetBytes = 500 * 1024;
  static const int maxDimension = 512;
  static const int quality = 85;

  @override
  Future<Uint8List> process(Uint8List picked) async {
    if (picked.isEmpty) throw const AvatarImageException.invalid();
    final Uint8List out;
    try {
      out = await FlutterImageCompress.compressWithList(
        picked,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.jpeg,
      );
    } on Exception {
      throw const AvatarImageException.invalid();
    }
    if (out.isEmpty) throw const AvatarImageException.invalid();
    if (out.lengthInBytes >= targetBytes) {
      throw const AvatarImageException.tooLarge();
    }
    return out;
  }
}

enum AvatarImageSource { gallery, camera }

/// Chọn ảnh avatar — tách interface để widget test thay bằng fake.
abstract interface class AvatarImagePicker {
  /// `null` = người dùng huỷ chọn.
  Future<Uint8List?> pick(AvatarImageSource source);
}

class DeviceAvatarImagePicker implements AvatarImagePicker {
  DeviceAvatarImagePicker({picker.ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? picker.ImagePicker();

  final picker.ImagePicker _imagePicker;

  @override
  Future<Uint8List?> pick(AvatarImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source == AvatarImageSource.camera
            ? picker.ImageSource.camera
            : picker.ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      if (code.contains('denied') || code.contains('permission')) {
        throw const AvatarPermissionDeniedException();
      }
      rethrow;
    }
  }
}
