/// Slider mục tiêu calo 800–5000 bước 50 + "Chưa đặt" (Decision D13, Guard 14).
///
/// Hàm thuần — unit-test được không cần widget. BE nhận 0–10000; giới hạn
/// hẹp hơn ở đây là ngoại lệ có chủ đích của form, KHÔNG được dùng để kẹp
/// lặng lẽ giá trị cũ ngoài khoảng ("không chạm thì không đổi").
abstract final class CalorieTarget {
  static const int min = 800;
  static const int max = 5000;
  static const int step = 50;
  static const int divisions = (max - min) ~/ step; // 84

  /// Vị trí thumb khi chuyển "Chưa đặt" → đặt mục tiêu.
  static const int defaultWhenEnabled = 2000;

  static bool isInSliderRange(int? v) => v != null && v >= min && v <= max;

  /// Vị trí thumb khi mở form. Giá trị cũ ngoài khoảng → mép gần nhất (CHỈ để
  /// vẽ, không phải giá trị gửi).
  static int thumbFor(int? stored) =>
      stored == null ? defaultWhenEnabled : stored.clamp(min, max);

  /// Làm tròn giá trị slider về bội số [step] trong [min, max].
  static int snap(double raw) {
    final snapped = ((raw - min) / step).round() * step + min;
    return snapped.clamp(min, max);
  }

  /// Giá trị gửi lên `PUT /me/health-profile`. Chưa kéo slider và chưa bấm
  /// "Chưa đặt" → gửi NGUYÊN giá trị đã lưu (kể cả 0, 600, 6000).
  static int? resolveForSave({
    required int? stored,
    required bool touched,
    required bool notSet,
    required int sliderValue,
  }) {
    if (!touched) return stored;
    if (notSet) return null;
    return sliderValue;
  }
}
