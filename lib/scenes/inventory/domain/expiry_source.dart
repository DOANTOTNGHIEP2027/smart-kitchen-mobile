/// Nguồn của hạn dùng gợi ý (#239) — khớp enum `ExpirySource` của BE.
enum ExpirySource {
  /// AI đọc được hạn trên ảnh (chỉ scan kho).
  ai,

  /// Theo lô cùng tên household từng nhập.
  history,

  /// Theo bảng số ngày mặc định của nhóm đồ.
  categoryDefault,

  /// Không gợi ý được.
  none;

  /// Có ngày gợi ý (khác [none]).
  bool get isSuggested => this != ExpirySource.none;

  /// Giá trị lạ/thiếu (BE cũ) → [none].
  static ExpirySource fromJson(Object? raw) => switch (raw) {
        'AI' => ExpirySource.ai,
        'HISTORY' => ExpirySource.history,
        'CATEGORY_DEFAULT' => ExpirySource.categoryDefault,
        _ => ExpirySource.none,
      };
}
