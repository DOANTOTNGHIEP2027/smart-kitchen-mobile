import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../data/network/api_exception.dart';
import '../../../../data/network/api_response.dart';
import '../../../../data/network/dio_client.dart';
import '../domain/ocr_scan_result.dart';
import 'ocr_mapper.dart';

abstract interface class OcrApi {
  Future<OcrScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
  });
}

class OcrApiImpl implements OcrApi {
  OcrApiImpl(this._client);

  final DioClient _client;

  @override
  Future<OcrScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
  }) {
    return _unwrap(() async {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/inventory-items/scan',
        data: FormData.fromMap(<String, dynamic>{
          'image': MultipartFile.fromBytes(imageBytes, filename: 'scan.jpg'),
        }),
        options: Options(
          headers: <String, dynamic>{'X-Idempotency-Key': idempotencyKey},
        ),
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const <String, dynamic>{},
        (value) => Map<String, dynamic>.from(value! as Map),
      );
      if (!envelope.success || envelope.data == null) {
        throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
      }
      return OcrMapper.scanResultFromJson(envelope.data!);
    });
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw error.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
