import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/inventory_item.dart';
import '../domain/inventory_mapper.dart';

/// Một trang danh sách inventory từ `GET /inventory-items`.
class InventoryListPage {
  const InventoryListPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<InventoryItemModel> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
}

/// 5 endpoint thật của inventory-core (FE-5 §8).
///
/// Quan trọng (Implementation Guard 11): mọi phương thức convert
/// [DioException] → [ApiException] BÊN TRONG `InventoryApi` qua [_unwrap].
/// Thiếu bước này, mọi `catch (BusinessException e) when (e.code == ...)`
/// ở [InventoryFormStore] không bao giờ match — rollback/conflict dialog
/// không chạy. Đây là Fix CRITICAL-1 của review.
abstract interface class InventoryApi {
  Future<InventoryItemModel> create(Map<String, dynamic> payload);
  Future<InventoryItemModel> update(
    String id, {
    required int version,
    required Map<String, dynamic> payload,
  });
  Future<void> delete(
    String id, {
    required int version,
    required String reason,
    String? wasteCause,
  });
  Future<InventoryItemModel> getById(String id);
  Future<InventoryListPage> list({int page = 0, int size = 100});
}

class InventoryApiImpl implements InventoryApi {
  InventoryApiImpl(this._client);

  final DioClient _client;

  @override
  Future<InventoryItemModel> create(Map<String, dynamic> payload) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/inventory-items',
        data: payload,
      );
      return _parseItem(res.data);
    });
  }

  @override
  Future<InventoryItemModel> update(
    String id, {
    required int version,
    required Map<String, dynamic> payload,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/api/v1/inventory-items/$id',
        data: <String, dynamic>{...payload, 'version': version},
      );
      return _parseItem(res.data);
    });
  }

  @override
  Future<void> delete(
    String id, {
    required int version,
    required String reason,
    String? wasteCause,
  }) {
    return _unwrap(() async {
      await _client.dio.delete<Map<String, dynamic>>(
        '/api/v1/inventory-items/$id',
        data: <String, dynamic>{
          'version': version,
          'reason': reason,
          // Chỉ đính key khi có giá trị — KHÔNG gửi 'wasteCause': null
          // (Epic 14 #133 mapping, OAS v1.2.0 §DELETE).
          if (wasteCause != null) 'wasteCause': wasteCause,
        },
      );
    });
  }

  @override
  Future<InventoryItemModel> getById(String id) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/inventory-items/$id',
      );
      return _parseItem(res.data);
    });
  }

  @override
  Future<InventoryListPage> list({int page = 0, int size = 100}) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/inventory-items',
        queryParameters: <String, dynamic>{'page': page, 'size': size},
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      final data = envelope.data ?? const <String, dynamic>{};
      final rawItems = (data['items'] as List<dynamic>? ?? <dynamic>[])
          .map((Object? e) => inventoryItemFromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return InventoryListPage(
        items: rawItems,
        page: (data['page'] as num?)?.toInt() ?? page,
        size: (data['size'] as num?)?.toInt() ?? size,
        totalElements: (data['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
      );
    });
  }

  /// Bọc call Dio để convert [DioException] → [ApiException] TRƯỚC khi ném ra
  /// ngoài. `ErrorMappingInterceptor` đã gắn `ApiException` vào `err.error`
  /// — ta có việc là đọc nó ra và ném tiếp với đúng kiểu.
  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

  InventoryItemModel _parseItem(Map<String, dynamic>? raw) {
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
      raw ?? const <String, dynamic>{},
      (Object? v) => Map<String, dynamic>.from(v! as Map),
    );
    if (!envelope.success || envelope.data == null) {
      throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
    }
    return inventoryItemFromJson(envelope.data!);
  }
}
