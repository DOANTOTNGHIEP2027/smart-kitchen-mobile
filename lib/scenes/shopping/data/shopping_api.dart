import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/shopping_item.dart';
import 'shopping_mapper.dart';

abstract interface class ShoppingApi {
  Future<List<ShoppingItem>> list(String householdId);
  /// [idempotencyKey]: header `X-Idempotency-Key` (#55, offline-sync-contract.md §5).
  Future<ShoppingItem> create(Map<String, dynamic> payload, String householdId, {String? idempotencyKey});
  /// [price] CHỈ khi kết quả toggle là COMPLETED (#133, Guard #13) — BE trả 400
  /// nếu có giá ở chiều về PENDING. Không có giá thì bỏ hẳn key `price`/
  /// `currency` (BE coi thiếu key và `null` như nhau; bỏ key cho body gọn).
  Future<ShoppingItem> toggle(String id, int version, String householdId, {double? price});

  /// `PATCH /items/{id}` — CHỈ `{version, assignedTo}` (#134). `assigneeId ==
  /// null` = BỎ GIAO: key `assignedTo` VẪN PHẢI có mặt với `null` — BE đọc
  /// JsonNode, vắng key = giữ nguyên (Guard #14).
  Future<ShoppingItem> assign(String id, int version, String householdId, {required String? assigneeId});
}

class ShoppingApiImpl implements ShoppingApi {
  ShoppingApiImpl(this._client);
  final DioClient _client;

  @override
  Future<List<ShoppingItem>> list(String householdId) => _unwrap(() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/api/v1/shopping');
    final data = _data(response.data);
    final groups = data['itemsByCategory'] as List<dynamic>? ?? <dynamic>[];
    return groups.expand((group) => (group as Map<String, dynamic>)['items'] as List<dynamic>? ?? <dynamic>[])
        .map((raw) => shoppingItemFromJson(Map<String, dynamic>.from(raw as Map), householdId)).toList();
  });

  @override
  Future<ShoppingItem> create(Map<String, dynamic> payload, String householdId, {String? idempotencyKey}) => _unwrap(() async {
    final response = await _client.dio.post<Map<String, dynamic>>('/api/v1/shopping/items', data: payload,
        options: idempotencyKey == null ? null : Options(headers: <String, dynamic>{'X-Idempotency-Key': idempotencyKey}));
    return shoppingItemFromJson(_data(response.data), householdId);
  });

  @override
  Future<ShoppingItem> toggle(String id, int version, String householdId, {double? price}) => _unwrap(() async {
    final response = await _client.dio.post<Map<String, dynamic>>('/api/v1/shopping/items/$id/complete', data: <String, dynamic>{
      'version': version,
      if (price != null) 'price': price,
      if (price != null) 'currency': 'VND',
    });
    return shoppingItemFromJson(_data(response.data), householdId);
  });

  @override
  Future<ShoppingItem> assign(String id, int version, String householdId, {required String? assigneeId}) => _unwrap(() async {
    final response = await _client.dio.patch<Map<String, dynamic>>('/api/v1/shopping/items/$id', data: <String, dynamic>{
      'version': version,
      'assignedTo': assigneeId,
    });
    return shoppingItemFromJson(_data(response.data), householdId);
  });

  Map<String, dynamic> _data(Map<String, dynamic>? raw) {
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(raw ?? const <String, dynamic>{}, (v) => Map<String, dynamic>.from(v! as Map));
    if (!envelope.success || envelope.data == null) throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
    return envelope.data!;
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try { return await call(); } on DioException catch (e) {
      throw e.error as ApiException? ?? ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
