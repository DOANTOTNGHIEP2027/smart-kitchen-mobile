/// Cấu hình theo môi trường.
///
/// Giá trị đến từ `--dart-define` lúc build (compile-time constant), không
/// phải đọc file lúc chạy — `config/env/*.dart` là file gitignored dành cho
/// ops, Dart không thể `import` file nằm ngoài cây nguồn một cách có điều
/// kiện. Mặc định trỏ vào stack local để `flutter run` mà không truyền gì
/// vẫn chạy được.
///
/// Ví dụ:
/// ```
/// flutter build web --dart-define=API_BASE_URL=https://api.example.com \
///                   --dart-define=APP_ENV=prod
/// ```
abstract class EnvConfig {
  static const String appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

  static const String aiBaseUrl =
      String.fromEnvironment('AI_BASE_URL', defaultValue: 'http://localhost:8000');

  static bool get isDev => appEnv == 'dev';

  /// Seam của chuỗi bootstrap (fe-app-shell.md §5). Hiện không có I/O vì mọi
  /// giá trị đều là compile-time; giữ chữ ký async để một nguồn config bất
  /// đồng bộ sau này (remote config, .env) không phải sửa call site.
  static Future<void> load() async {}
}
