/// Kết quả trừ kho cho 1 ingredient sau khi complete() (#76, OAS
/// `IngredientDeduction`).
///
/// `shortfallQuantity > 0` nghĩa là kho KHÔNG đủ để trừ hết lượng yêu cầu —
/// BE FIFO nearest-expiry trừ đến đâu hết rồi dừng, không raise lỗi
/// (complete() luôn trả 200 khi session hợp lệ, xem OAS POST /complete).
/// FE dùng [hasShortfall] để badge cảnh báo trên UI kết quả — đây là cách FE
/// biểu diễn "thiếu nguyên liệu" mà không văng lỗi đỏ.
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
