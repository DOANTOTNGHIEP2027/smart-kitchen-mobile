import 'meal_suggestion.dart';

/// Interface tối thiểu nối missing ingredients của Meal plan sang Shopping.
///
/// Đăng ký no-op khi chưa có ShoppingStore — bấm nút "Thêm vào ds mua sắm"
/// hiển thị snackbar thay vì im lặng không phản hồi.
abstract class ShoppingListSink {
  Future<void> addItems(List<IngredientItem> items);
}

/// Fallback an toàn khi ShoppingStore chưa được đăng ký (ví dụ route độc lập).
class NoOpShoppingListSink implements ShoppingListSink {
  const NoOpShoppingListSink();

  @override
  Future<void> addItems(List<IngredientItem> items) async {
    // Caller check sentinel qua `runtimeType` hoặc注册 riêng — không throw.
  }
}
