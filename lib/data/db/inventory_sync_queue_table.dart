import 'package:drift/drift.dart';

/// Các mutation kho chưa gửi được lên server.
///
/// Hàng đợi chỉ giữ metadata của thao tác; snapshot mới nhất luôn nằm ở
/// `inventory_items`. Nhờ vậy nhiều lần sửa khi offline được coalesce thành
/// một thao tác, và app có thể khôi phục hàng đợi sau khi bị đóng.
class InventorySyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get householdId => text()();
  TextColumn get itemId => text()();
  TextColumn get operation => text()(); // CREATE | UPDATE | DELETE
  IntColumn get baseVersion => integer()();
  TextColumn get deleteReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
