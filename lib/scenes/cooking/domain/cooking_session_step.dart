/// Một bước của recipe (FE-6 §5 — nguồn `recipes.steps` #75, KHÔNG phải
/// cooking_sessions).
///
/// Quan trọng (Implementation Guard #10): `durationSeconds` đã được quy đổi
/// từ phút sang GIÂY tại tầng mapper — `recipes.steps[].duration_minutes` của
/// #75 là PHÚT. Gán thẳng `duration_minutes` vào đây = timer chạy nhanh × 60.
class CookingSessionStep {
  const CookingSessionStep({
    required this.stepNumber,
    required this.instruction,
    this.durationSeconds,
  });

  final int stepNumber;
  final String instruction;

  /// Đơn vị GIÂY. `null` khi recipe không khai báo `duration_minutes`.
  final int? durationSeconds;
}
