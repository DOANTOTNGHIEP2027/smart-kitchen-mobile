import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import '../network/api_response.dart';
import '../network/dio_client.dart';

class InventoryQuickActionResult {
  const InventoryQuickActionResult({
    required this.itemId,
    required this.itemName,
    required this.action,
    required this.applied,
    this.transactionReason,
  });

  final String itemId;
  final String itemName;
  final String action;
  final bool applied;
  final String? transactionReason;
}

InventoryQuickActionResult inventoryQuickActionResultFromJson(
  Map<String, dynamic> data,
) {
  return InventoryQuickActionResult(
    itemId: data['itemId'] as String,
    itemName: data['itemName'] as String,
    action: data['action'] as String,
    applied: data['applied'] as bool,
    transactionReason: data['transactionReason'] as String?,
  );
}

abstract interface class QuickActionApi {
  Future<InventoryQuickActionResult> apply({
    required String itemId,
    required String action,
  });
}

class QuickActionApiImpl implements QuickActionApi {
  QuickActionApiImpl(DioClient client) : _dio = client.dio;

  /// Isolate nền (Amendment #134 A3): Dio tối giản, KHÔNG `DioClient.build()`
  /// (TokenRefreshInterceptor dùng GetX).
  QuickActionApiImpl.withDio(Dio dio) : _dio = dio;

  final Dio _dio;

  /// [options] mang header `Authorization` + timeout phụ, [cancelToken] cắt
  /// ngân sách tổng — chỉ isolate nền truyền (A3/A4).
  @override
  Future<InventoryQuickActionResult> apply({
    required String itemId,
    required String action,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/inventory-items/$itemId/quick-action',
        data: <String, dynamic>{'action': action},
        options: options,
        cancelToken: cancelToken,
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const <String, dynamic>{},
        (Object? value) => Map<String, dynamic>.from(value! as Map),
      );
      if (!envelope.success || envelope.data == null) {
        throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
      }
      final data = envelope.data!;
      return inventoryQuickActionResultFromJson(data);
    } on DioException catch (error) {
      final mapped = error.error;
      throw mapped is ApiException
          ? mapped
          : ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
