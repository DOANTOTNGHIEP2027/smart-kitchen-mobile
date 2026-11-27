import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/checkout_preview_item.dart';

/// `GET /api/v1/shopping/checkout/preview` (#239) — món đã mua chưa vào kho,
/// kèm hạn gợi ý. Chỉ đọc.
abstract interface class CheckoutApi {
  Future<List<CheckoutPreviewItem>> preview();
}

class CheckoutApiImpl implements CheckoutApi {
  CheckoutApiImpl(this._client);

  final DioClient _client;

  @override
  Future<List<CheckoutPreviewItem>> preview() async {
    try {
      final res = await _client.dio
          .get<Map<String, dynamic>>('/api/v1/shopping/checkout/preview');
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      if (!envelope.success || envelope.data == null) {
        throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
      }
      return (envelope.data!['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((Object? v) =>
              CheckoutPreviewItem.fromJson(Map<String, dynamic>.from(v! as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
