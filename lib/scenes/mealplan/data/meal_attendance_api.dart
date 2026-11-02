import 'package:dio/dio.dart';
import '../../../data/network/api_exception.dart';
import '../../../data/network/dio_client.dart';
import '../domain/meal_attendance.dart';

class MealAttendanceApi {
  MealAttendanceApi(this._client);
  final DioClient _client;
  String _path(String pid, String sid) =>
      '/api/v1/meal-plans/$pid/slots/$sid/attendance';
  Future<List<MealAttendance>> list(String pid) async {
    try {
      final response = await _client.dio
          .get<Map<String, dynamic>>('/api/v1/meal-plans/$pid/attendance');
      return (response.data!['data'] as List<dynamic>)
          .map((v) => MealAttendance.fromJson(v as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

  Future<MealAttendance> get(String pid, String sid) async {
    try {
      final response =
          await _client.dio.get<Map<String, dynamic>>(_path(pid, sid));
      return MealAttendance.fromJson(
          response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

  Future<MealAttendance> update(
      String pid, String sid, AttendanceStatus status) async {
    try {
      final path = '${_path(pid, sid)}/me';
      final response = status == AttendanceStatus.unknown
          ? await _client.dio.delete<Map<String, dynamic>>(path)
          : await _client.dio.put<Map<String, dynamic>>(path,
              data: <String, dynamic>{
                  'status': status == AttendanceStatus.attending
                      ? 'ATTENDING'
                      : 'NOT_ATTENDING'
                });
      return MealAttendance.fromJson(
          response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
