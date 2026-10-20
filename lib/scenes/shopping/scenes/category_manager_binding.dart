import 'package:get/get.dart';

import '../stores/category_store.dart';

/// KHÔNG đăng ký lại `CategoryStore` — đã có ở `ShoppingListBinding` (Guard #11);
/// chỉ nạp lại (idempotent).
class CategoryManagerBinding extends Bindings {
  @override
  void dependencies() {
    Get.find<CategoryStore>().loadCategories();
  }
}
