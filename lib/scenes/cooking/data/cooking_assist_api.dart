import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/cooking_assist.dart';
import 'cooking_assist_mapper.dart';

/// `POST /api/v1/cooking/sessions/{id}/assist` (#157, OAS cooking-assistant).
///
/// Cùng pattern `_unwrap` của [CookingSessionApi]: convert `DioException` →
/// `ApiException` BÊN TRONG API layer.
abstract interface class CookingAssistApi {
  Future<CookingAssistData> ask(
    String sessionId, {
    required String message,
    required int viewedStep,
    required List<ChatTurn> chatHistory,
  });
}

class CookingAssistApiImpl implements CookingAssistApi {
  CookingAssistApiImpl(this._client);

  final DioClient _client;

  /// §14.3: BE chờ AI tối đa 13 s → client cắt ở 15 s (ra `NetworkException`).
  static const Duration timeout = Duration(seconds: 15);

  @override
  Future<CookingAssistData> ask(
    String sessionId, {
    required String message,
    required int viewedStep,
    required List<ChatTurn> chatHistory,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/cooking/sessions/$sessionId/assist',
        data: <String, dynamic>{
          'message': message,
          'viewedStep': viewedStep,
          'chatHistory':
              chatHistory.map((t) => t.toJson()).toList(growable: false),
        },
        options: Options(sendTimeout: timeout, receiveTimeout: timeout),
      );
      return mapCookingAssistData(_data(res.data));
    });
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? raw) {
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
      raw ?? const <String, dynamic>{},
      (Object? v) => Map<String, dynamic>.from(v! as Map),
    );
    if (!envelope.success || envelope.data == null) {
      throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
    }
    return envelope.data!;
  }
}
