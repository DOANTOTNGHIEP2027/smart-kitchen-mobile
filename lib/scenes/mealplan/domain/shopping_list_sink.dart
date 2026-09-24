import 'meal_suggestion.dart';

/// Interface tối thiểu nối missing ingredients của Meal plan sang Shopping.
///
/// Đăng ký no-op khi chưa có ShoppingStore — bấm nút "Thêm vào ds mua sắm"
/// hiển thị snackbar thay vì im lặng không phản hồi.
abstract class ShoppingListSink {
  /// Số nguyên liệu đã được chuyển sang Shopping. Giá trị 0 cho biết sink
  /// không khả dụng hoặc không có item hợp lệ để thêm.
  Future<int> addItems(List<IngredientItem> items);
}

/// Fallback an toàn khi ShoppingStore chưa được đăng ký (ví dụ route độc lập).
class NoOpShoppingListSink implements ShoppingListSink {
  const NoOpShoppingListSink();

  @override
  Future<int> addItems(List<IngredientItem> items) async => 0;
}
