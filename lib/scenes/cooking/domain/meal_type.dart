/// Loại bữa ăn — KHÔNG PHẢI field BE (Decision D2, meal-log-screen §6).
///
/// `meal_logs` không có cột `meal_type`; loại bữa được mã hoá vào tiền tố
/// `[<nhãn>]` của `description` để round-trip đúng qua GET /cooking/logs
/// (description LÀ 1 cột thật được persist).
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  static const Map<MealType, String> _labels = <MealType, String>{
    MealType.breakfast: 'Bữa sáng',
    MealType.lunch: 'Bữa trưa',
    MealType.dinner: 'Bữa tối',
    MealType.snack: 'Ăn vặt',
  };

  String get label => _labels[this]!;

  /// `[<nhãn>]` luôn có mặt kể cả khi `userText` rỗng — đảm bảo `description`
  /// LUÔN non-empty (Guard #9): rule "ít nhất 1 trong description/
  /// imageBase64" của #77 luôn thoả mãn tự nhiên.
  String composeDescription(String? userText) {
    final trimmed = userText?.trim();
    return (trimmed == null || trimmed.isEmpty)
        ? '[$label]'
        : '[$label] $trimmed';
  }
}

/// Thuần display-only — KHÔNG dùng cho filter/query nào (BE không có cột này).
/// Trả null nếu `description` không khớp tiền tố đã biết (không throw, không
/// đoán — Guard #2).
MealType? parseMealTypeFromDescription(String? description) {
  if (description == null) return null;
  for (final type in MealType.values) {
    if (description.startsWith('[${type.label}]')) return type;
  }
  return null;
}