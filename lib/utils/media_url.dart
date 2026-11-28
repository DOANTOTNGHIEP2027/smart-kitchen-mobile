import '../app/env_config.dart';

/// Ảnh do BE lưu (`/files/...`): BE dựng URL tuyệt đối từ host của request
/// UPLOAD (vd. `10.0.2.2` của emulator, `localhost` qua `adb reverse`), nên máy
/// khác không tải được → avatar "chập chờn" giữa các máy. Thay host bằng API
/// base của máy ĐANG XEM; URL ngoài (Google avatar, CDN) giữ nguyên.
String normalizeMediaUrl(String url, {String baseUrl = EnvConfig.apiBaseUrl}) {
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.path.contains('/files/')) return trimmed;
  final base = Uri.tryParse(baseUrl);
  if (base == null || !base.hasScheme || base.host.isEmpty) return trimmed;
  if (uri.hasScheme && uri.scheme != 'http' && uri.scheme != 'https') {
    return trimmed;
  }
  return uri
      .replace(
        scheme: base.scheme,
        host: base.host,
        // `port` của base luôn có giá trị (mặc định 80/443 thì toString tự bỏ).
        port: base.port,
      )
      .toString();
}
