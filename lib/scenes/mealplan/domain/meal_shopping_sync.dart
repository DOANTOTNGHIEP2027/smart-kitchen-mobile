import 'meal_suggestion.dart';

/// 1 dòng đi chợ do 1 món của thực đơn sinh ra (BE `sources`).
class SlotShoppingLine {
  const SlotShoppingLine({
    required this.id,
    required this.dishId,
    this.recipeName,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.bought,
  });

  final String id;
  final String dishId;

  /// Công thức của món lúc tạo dòng; `null` = BE không gửi (coi như còn khớp).
  final String? recipeName;
  final String name;
  final double quantity;
  final String unit;

  /// Đã tick mua — tiền đã tiêu, "Hoàn thành thêm món" không được xoá.
  final bool bought;
}

/// Nối nút "Hoàn thành thêm món" của 1 buổi với Đi chợ mà mealplan không phụ
/// thuộc module shopping (impl ở `shopping/domain/shopping_list_sink_impl.dart`).
abstract interface class MealShoppingSync {
  /// Dòng đi chợ gắn món của buổi [slotDate] + [mealTime], đọc từ bản server
  /// MỚI NHẤT. `null` = không tải được (offline / lỗi) — caller báo, không
  /// đoán trên cache cũ.
  Future<List<SlotShoppingLine>?> linesOfSlot(DateTime slotDate, String mealTime);

  /// Đẩy đồ thiếu của MỘT món (gộp `name|unit` trong món). Trả số dòng đã thêm.
  Future<int> addForDish(String dishId, List<IngredientItem> items);

  /// Xoá các dòng; dòng lỗi bỏ qua. Trả số dòng đã xoá.
  Future<int> remove(List<String> ids);
}
