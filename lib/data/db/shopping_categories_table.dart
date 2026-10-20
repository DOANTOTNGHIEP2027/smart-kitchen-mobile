import 'package:drift/drift.dart';

/// Category đi chợ LOCAL-ONLY (#69, shopping-share-category.md §6): BE không có
/// category CRUD — preference hiển thị trên THIẾT BỊ NÀY, không sync, không có
/// sync-queue (Guard #3). Row đổi tên để không trùng model domain.
@DataClassName('ShoppingCategoryRow')
class ShoppingCategories extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  /// 1 trong [categoryColorPalette] — không nhập hex tự do (Guard #5).
  TextColumn get colorHex => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
