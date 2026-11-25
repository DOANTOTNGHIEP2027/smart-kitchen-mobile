/// Parse + validate chiều cao/cân nặng nhập tay. Chấp nhận dấu thập phân
/// `.` hoặc `,` (bàn phím số tiếng Việt thường ra `,`). Ô trống = `null` hợp lệ.
abstract final class HealthMeasurement {
  static const double heightMin = 1;
  static const double heightMax = 300;
  static const double weightMin = 1;
  static const double weightMax = 500;

  static final RegExp _number = RegExp(r'^\d+([.,]\d+)?$');

  /// Số đã parse, hoặc `null` nếu trống / không phải số thập phân dương hợp lệ
  /// (loại `1e3`, `NaN`, `-1`, `0x10`…).
  static double? parse(String raw) {
    final trimmed = raw.trim();
    if (!_number.hasMatch(trimmed)) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  static bool isValidHeight(String raw) => _isValid(raw, heightMin, heightMax);

  static bool isValidWeight(String raw) => _isValid(raw, weightMin, weightMax);

  static bool _isValid(String raw, double min, double max) {
    if (raw.trim().isEmpty) return true;
    final value = parse(raw);
    return value != null && value >= min && value <= max;
  }
}
