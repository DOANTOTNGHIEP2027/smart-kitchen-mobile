import '../../../app/env_config.dart';

/// Scheme dùng cho deep link test bằng `adb` (`smartkitchen://app/join/<CODE>`).
/// Host `app` là bắt buộc: Flutter chỉ chuyển **path** của URI thành route,
/// nên `smartkitchen://join/X` sẽ thành `/X` (fe-onboarding.md §12b, D9).
const String inviteDeepLinkScheme = 'smartkitchen';
const String inviteDeepLinkHost = 'app';

final RegExp _codePattern = RegExp(r'^[A-Z0-9]{8}$');

/// Link mời in trong QR: `<inviteBaseUrl>/join/<CODE>`.
String inviteLink(String code, {String baseUrl = EnvConfig.inviteBaseUrl}) {
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  return '$base/join/$code';
}

/// Rút mã mời 8 ký tự từ QR / ô nhập / deep link (fe-onboarding.md §12b).
///
/// Trả `null` khi không phải mã mời Smart Kitchen — caller hiển thị S8.14 và
/// KHÔNG gọi API. Chấp nhận:
/// - mã trơn (bỏ khoảng trắng / gạch ngang, không phân biệt hoa thường);
/// - `https://<host của inviteBaseUrl>/join/<CODE>` (cho phép `/` cuối, query);
/// - `smartkitchen://app/join/<CODE>`.
String? parseInviteCode(
  String raw, {
  String baseUrl = EnvConfig.inviteBaseUrl,
}) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  if (!value.contains('://')) {
    final code = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    return _codePattern.hasMatch(code) ? code : null;
  }

  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  final base = Uri.tryParse(baseUrl);
  final isAppLink = base != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.scheme == base.scheme &&
      uri.host.toLowerCase() == base.host.toLowerCase();
  final isCustomScheme = uri.scheme == inviteDeepLinkScheme &&
      uri.host.toLowerCase() == inviteDeepLinkHost;
  if (!isAppLink && !isCustomScheme) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2 || segments.first != 'join') return null;
  final code = segments.last.toUpperCase();
  return _codePattern.hasMatch(code) ? code : null;
}
