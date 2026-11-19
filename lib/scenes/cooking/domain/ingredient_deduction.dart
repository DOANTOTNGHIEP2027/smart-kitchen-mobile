/// Kết quả trừ kho cho 1 ingredient sau khi complete() (#76, OAS
/// `IngredientDeduction`).
///
/// `shortfallQuantity > 0` chỉ xuất hiện khi người dùng đã xác nhận
/// "Hoàn tất dù thiếu" (`allowShortfall=true`) — BE FIFO nearest-expiry trừ
/// đến đâu hết rồi dừng. Không xác nhận thì BE trả 409 và không trừ gì
/// (OD-36). FE dùng [hasShortfall] để badge cảnh báo trên UI kết quả.
class IngredientDeduction {
  const IngredientDeduction({
    required this.ingredientName,
    required this.requiredQuantity,
    required this.requiredUnit,
    required this.deductedQuantity,
    required this.shortfallQuantity,
    required this.matchedItemCount,
  });

  final String ingredientName;
  final double requiredQuantity;
  final String requiredUnit;
  final double deductedQuantity;
  final double shortfallQuantity;
  final int matchedItemCount;

  bool get hasShortfall => shortfallQuantity > 0;
}
