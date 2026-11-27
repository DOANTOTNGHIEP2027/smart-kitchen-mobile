import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/assistant_models.dart';
import 'assistant_mapper.dart';

/// `/api/v1/assistant/**` (#204, `kitchen-assistant.md` v2 §2). FE không gọi
/// AI trực tiếp.
///
/// Cùng pattern `_unwrap` của các API khác: convert `DioException` →
/// `ApiException` BÊN TRONG API layer.
abstract interface class AssistantApi {
  /// Tạo phiên; trả `id`. Ngữ cảnh gắn cố định với phiên.
  Future<String> createSession(
    AssistantContextType type, {
    String? cookingSessionId,
    String? mealPlanId,
    String? slotId,
  });

  /// Gửi một lượt. Lượt mới ⇒ `PENDING` (202); `clientTurnId` đã trả lời ⇒
  /// `ANSWERED` kèm kết quả cũ (200).
  Future<AssistantTurnStatus> sendMessage(
    String sessionId, {
    required String text,
    required String clientTurnId,
    int? currentStep,
  });

  /// Trạng thái lượt — dùng khi stream SSE lỗi (polling dự phòng).
  Future<AssistantTurnStatus> turnStatus(String sessionId, String turnId);

  /// Stream SSE của lượt; kết thúc sau sự kiện [TurnFinished]. Lỗi mạng/HTTP
  /// ném như các hàm khác — bên gọi chuyển sang [turnStatus].
  Stream<AssistantTurnEvent> turnEvents(String sessionId, String turnId);
}

class AssistantApiImpl implements AssistantApi {
  AssistantApiImpl(this._client);

  final DioClient _client;

  static const String _base = '/api/v1/assistant/sessions';

  /// POST/GET ngắn: BE trả ngay (lượt chạy nền).
  static const Duration timeout = Duration(seconds: 15);

  @override
  Future<String> createSession(
    AssistantContextType type, {
    String? cookingSessionId,
    String? mealPlanId,
    String? slotId,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        _base,
        data: <String, dynamic>{
          'contextType': type.wire,
          if (cookingSessionId != null) 'cookingSessionId': cookingSessionId,
          if (mealPlanId != null) 'mealPlanId': mealPlanId,
          if (slotId != null) 'slotId': slotId,
        },
        options: Options(sendTimeout: timeout, receiveTimeout: timeout),
      );
      return _data(res.data)['id'] as String;
    });
  }

  @override
  Future<AssistantTurnStatus> sendMessage(
    String sessionId, {
    required String text,
    required String clientTurnId,
    int? currentStep,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '$_base/$sessionId/messages',
        data: <String, dynamic>{
          'text': text,
          'clientTurnId': clientTurnId,
          if (currentStep != null) 'currentStep': currentStep,
        },
        options: Options(sendTimeout: timeout, receiveTimeout: timeout),
      );
      return mapTurnStatus(_data(res.data));
    });
  }

  @override
  Future<AssistantTurnStatus> turnStatus(String sessionId, String turnId) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '$_base/$sessionId/turns/$turnId',
        options: Options(receiveTimeout: timeout),
      );
      return mapTurnStatus(_data(res.data));
    });
  }

  @override
  Stream<AssistantTurnEvent> turnEvents(
      String sessionId, String turnId) async* {
    final res = await _unwrap(() => _client.dio.get<ResponseBody>(
          '$_base/$sessionId/turns/$turnId/events',
          options: Options(
            responseType: ResponseType.stream,
            // Kèm JSON để lỗi (404…) vẫn có body ApiResponse.
            headers: <String, String>{
              'Accept': 'text/event-stream, application/json',
            },
          ),
        ));
    final lines = res.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    String? event;
    await for (final line in lines) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:') && event != null) {
        final data =
            jsonDecode(line.substring(5).trim()) as Map<String, dynamic>;
        switch (event) {
          case 'turn.progress':
            yield TurnProgress(data['tool'] as String? ?? '');
          case 'turn.completed':
            yield TurnFinished(mapTurnStatus(data));
            return;
          case 'turn.failed':
            yield TurnFinished(mapFailedEvent(data));
            return;
        }
        event = null;
      }
    }
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
