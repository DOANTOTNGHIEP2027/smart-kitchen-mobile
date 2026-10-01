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
  QuickActionApiImpl(this._client);

  final DioClient _client;

  @override
  Future<InventoryQuickActionResult> apply({
    required String itemId,
    required String action,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/inventory-items/$itemId/quick-action',
        data: <String, dynamic>{'action': action},
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
      throw error.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
