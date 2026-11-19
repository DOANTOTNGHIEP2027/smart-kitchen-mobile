/// 1 nguyên liệu thiếu trong `error.details.missingIngredients` của 409
/// `ERR_INSUFFICIENT_STOCK_FOR_RECIPE` (OAS `InsufficientStockDetails`, OD-36).
///
/// Nhận được nghĩa là BE đã rollback toàn bộ — kho CHƯA bị trừ gì, session
/// vẫn `IN_PROGRESS`. Số lượng ở đơn vị chuẩn sau `UnitNormalizer` của BE.
class MissingIngredient {
  const MissingIngredient({
    required this.ingredientName,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.shortfallQuantity,
    required this.unit,
  });

  final String ingredientName;
  final double requiredQuantity;
  final double availableQuantity;
  final double shortfallQuantity;

  /// `GRAM` | `MILLILITER` | `PIECE` | `UNIT` — giữ nguyên chuỗi wire như
  /// `IngredientDeduction.requiredUnit`.
  final String unit;
}
