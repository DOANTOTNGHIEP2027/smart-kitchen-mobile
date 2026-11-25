import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/receipt_scan_result.dart';
import 'receipt_mapper.dart';

abstract interface class ReceiptApi {
  Future<ReceiptScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
    CancelToken? cancelToken,
  });
}

class ReceiptApiImpl implements ReceiptApi {
  ReceiptApiImpl(this._client);

  final DioClient _client;

  static const String scanPath = '/api/v1/receipts/scan';

  /// BE `aiReceipt.timeout-duration` = 30s; DioClient mặc định chỉ 20s nên
  /// nhánh ERR_AI_TIMEOUT không bao giờ tới FE. Cùng cách
  /// meal_composition_api.dart.
  static const Duration receiveTimeout = Duration(seconds: 35);

  @override
  Future<ReceiptScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
    CancelToken? cancelToken,
  }) {
    return _unwrap(() async {
      final response = await _client.dio.post<Map<String, dynamic>>(
        scanPath,
        data: FormData.fromMap(<String, dynamic>{
          'image': MultipartFile.fromBytes(imageBytes, filename: 'receipt.jpg'),
        }),
        options: Options(
          headers: <String, dynamic>{'X-Idempotency-Key': idempotencyKey},
          receiveTimeout: receiveTimeout,
        ),
        cancelToken: cancelToken,
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const <String, dynamic>{},
        (value) => Map<String, dynamic>.from(value! as Map),
      );
      if (!envelope.success || envelope.data == null) {
        throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
      }
      return ReceiptMapper.scanResultFromJson(envelope.data!);
    });
  }

  /// Bắt buộc (Guard 2). Fallback khi error không phải ApiException — không
  /// cast mù.
  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      final cause = error.error;
      if (cause is ApiException) throw cause;
      throw ServerException('ERR_UNKNOWN', 'Unexpected response');
    } on ApiException {
      rethrow;
    } catch (_) {
      // Body 200 sai hình dạng (cast trong ApiResponse/ReceiptMapper ném
      // TypeError…) → vẫn là ApiException như mọi lỗi khác ra khỏi Api (L5).
      throw ServerException('ERR_UNKNOWN', 'Malformed receipt scan response');
    }
  }
}
