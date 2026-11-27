import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_mapper.dart';

/// `POST /api/v1/inventory-items/batch` (#239) — ghi 1–50 lô trong một
/// transaction, all-or-nothing. Tách khỏi [InventoryApi] để các fake sẵn có
/// không phải đổi theo.
abstract interface class InventoryBatchApi {
  /// [items]: mỗi phần tử là payload kiểu `POST /inventory-items` + tuỳ chọn
  /// `sourceShoppingItemId`/`sourceShoppingItemVersion`. Trả các lô đã tạo
  /// đúng thứ tự gửi.
  Future<List<InventoryItemModel>> batchCreate(
    List<Map<String, dynamic>> items, {
    required String idempotencyKey,
  });
}

class InventoryBatchApiImpl implements InventoryBatchApi {
  InventoryBatchApiImpl(this._client);

  final DioClient _client;

  @override
  Future<List<InventoryItemModel>> batchCreate(
    List<Map<String, dynamic>> items, {
    required String idempotencyKey,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/inventory-items/batch',
        data: <String, dynamic>{'items': items},
        options: Options(headers: <String, dynamic>{
          'X-Idempotency-Key': idempotencyKey,
        }),
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      if (!envelope.success || envelope.data == null) {
        throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
      }
      return (envelope.data!['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((Object? v) =>
              inventoryItemFromJson(Map<String, dynamic>.from(v! as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}

/// Vị trí dòng lỗi của một lỗi batch (#239 F6): `fieldErrors` key
/// `items[i].*` (400) hoặc `details.index` (409 `ERR_SHOP_*`).
Set<int> batchErrorRows(ApiException error) {
  final rows = <int>{};
  final pattern = RegExp(r'^items\[(\d+)\]');
  for (final key in (error.fieldErrors ?? const <String, String>{}).keys) {
    final match = pattern.firstMatch(key);
    if (match != null) rows.add(int.parse(match.group(1)!));
  }
  final index = error.details?['index'];
  if (index is num) rows.add(index.toInt());
  return rows;
}
