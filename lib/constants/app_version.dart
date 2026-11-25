/// Version app (phần trước `+build` của `version:` trong pubspec.yaml).
///
/// Không dùng `package_info_plus` (ngoài danh sách D-05) — test
/// `model_packaging_test.dart` khoá hằng này khớp pubspec
/// (on-device-ai-runtime.md §5.4.3).
abstract final class AppVersion {
  static const String current = '0.1.0';
}
