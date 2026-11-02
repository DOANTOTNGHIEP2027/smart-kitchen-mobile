import 'package:dio/dio.dart';
import '../../../data/network/api_exception.dart';
import '../../../data/network/dio_client.dart';
import '../domain/meal_suggestion.dart';
import '../domain/meal_plan_slot.dart';
import 'meal_plan_mapper.dart';

class MealSuggestionApi {
  MealSuggestionApi(this._client);
  final DioClient _client;
  String _path(String pid, String sid, String did) =>
      '/api/v1/meal-plans/$pid/slots/$sid/dishes/$did';
  Future<List<MealSuggestion>> list(String pid, String sid, String did) =>
      _read(pid, sid, did, false);
  Future<List<MealSuggestion>> generate(String pid, String sid, String did) =>
      _read(pid, sid, did, true);
  Future<List<MealSuggestion>> _read(
      String pid, String sid, String did, bool generate) async {
    try {
      final path = '${_path(pid, sid, did)}/suggestions';
      final response = generate
          ? await _client.dio.post<Map<String, dynamic>>(path)
          : await _client.dio.get<Map<String, dynamic>>(path);
      return (response.data!['data'] as List<dynamic>)
          .map((v) => MealSuggestion.fromJson(v as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

  Future<MealPlanDish> select(
      String pid, String sid, String did, String suggestionId) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
          '${_path(pid, sid, did)}/selection',
          data: <String, dynamic>{'suggestionId': suggestionId});
      return MealPlanMapper.dishFromJson(
          response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
