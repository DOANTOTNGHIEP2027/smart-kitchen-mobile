import 'package:dio/dio.dart';

import '../../domain/household/household_models.dart';
import '../network/api_response.dart';

/// Gọi các endpoint `/api/v1/households/*` trong phạm vi #28
/// (fe-onboarding.md Flow 7, 8). Quản lý thành viên (Flow 12) thuộc #29.
class HouseholdRepository {
  const HouseholdRepository(this._dio);

  static const String _households = '/api/v1/households';
  static const String _join = '/api/v1/households/join';
  static const String _invitePrefix = '/api/v1/households/invites/';

  final Dio _dio;

  Future<HouseholdCreated> create({required String name}) async {
    // `avatarUrl` bị bỏ khỏi form theo Decision D5 — chưa có luồng upload ảnh.
    final response = await _dio.post<dynamic>(
      _households,
      data: <String, dynamic>{'name': name},
    );
    return HouseholdCreated.fromJson(unwrapEnvelope(response));
  }

  /// Public, không cần JWT — `AuthHeaderInterceptor` loại trừ prefix này
  /// (fe-app-shell.md §7.4).
  Future<InvitePreview> previewInvite(String code) async {
    final response = await _dio.get<dynamic>('$_invitePrefix$code');
    return InvitePreview.fromJson(unwrapEnvelope(response));
  }

  /// Dành cho user **đã có JWT nhưng chưa có household**. Request field là
  /// `code`, không phải `inviteCode` — khác với `/auth/qr-join`, theo đúng
  /// `household-invite-role.yaml` schema `JoinHouseholdRequest`.
  Future<JoinHouseholdResult> join(String code) async {
    final response = await _dio.post<dynamic>(
      _join,
      data: <String, dynamic>{'code': code},
    );
    return JoinHouseholdResult.fromJson(unwrapEnvelope(response));
  }
}
