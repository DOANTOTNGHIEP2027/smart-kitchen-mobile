import 'meal_suggestion.dart';

/// Interface tối thiểu — Epic 5 ShoppingStore implement interface này khi
/// ship (FE-7 §9.4, chưa có thiết kế).
///
/// Đăng ký no-op khi chưa có ShoppingStore — bấm nút "Thêm vào ds mua sắm"
/// hiển thị snackbar thay vì im lặng không phản hồi.
abstract class ShoppingListSink {
  Future<void> addItems(List<IngredientItem> items);
}

/// No-op sink cho demo — FE-7 §9.4 ghi rõ không được im lặng khi bấm nút
/// "Thêm vào ds mua sắm" mà Epic 5 chưa ship.
class NoOpShoppingListSink implements ShoppingListSink {
  const NoOpShoppingListSink();

  @override
  Future<void> addItems(List<IngredientItem> items) async {
    // Caller check sentinel qua `runtimeType` hoặc注册 riêng — không throw.
  }
}
