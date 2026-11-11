import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/dio_client.dart';
import '../domain/meal_composition.dart';

class MealCompositionApi {
  MealCompositionApi(this._client);
  final DioClient _client;
  String _base(String pid, String sid) => '/api/v1/meal-plans/$pid/slots/$sid';
  Future<CompositionContext> context(String pid, String sid) =>
      _unwrap(() async {
        final res = await _client.dio.get<Map<String, dynamic>>(
          '${_base(pid, sid)}/menu-context',
        );
        return CompositionContext.fromJson(
          res.data!['data'] as Map<String, dynamic>,
        );
      });
  Future<CompositionReceipt> read(String pid, String sid, String requestId) =>
      _unwrap(() async {
        final res = await _client.dio.get<Map<String, dynamic>>(
          '${_base(pid, sid)}/menu-generations/$requestId',
        );
        return CompositionReceipt.fromJson(
          res.data!['data'] as Map<String, dynamic>,
        );
      });
  Future<CompositionReceipt> generate(
    String pid,
    String sid, {
    required String requestId,
    required int version,
    required bool replaceExisting,
    required List<String> dependents,
    required List<String> guests,
  }) =>
      _unwrap(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '${_base(pid, sid)}/menu-generations',
          options: Options(receiveTimeout: const Duration(seconds: 25)),
          data: <String, dynamic>{
            'requestId': requestId,
            'expectedMenuVersion': version,
            'replaceExisting': replaceExisting,
            'dependentIds': dependents,
            'guestIds': guests,
          },
        );
        return CompositionReceipt.fromJson(
          res.data!['data'] as Map<String, dynamic>,
        );
      });
  Future<T> _unwrap<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error! as ApiException;
      throw NetworkException();
    }
  }
}
