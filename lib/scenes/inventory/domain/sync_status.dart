/// Trạng thái đồng bộ của một [InventoryItem] so với server (FE-5 §6).
///
/// - [synced]   : row local khớp với state mới nhất của server.
/// - [pendingCreate] : item được tạo optimistic cục bộ, chưa từng gửi lên server.
/// - [pendingUpdate] : item đã tồn tại ở server, người dùng vừa sửa cục bộ,
///   chưa gửi lên.
/// - [pendingDelete] : item đã bị xoá optimistic khỏi list (ẩn), chưa gửi lên.
/// - [conflict] : server trả 409 ERR_INVENTORY_VERSION_CONFLICT khi ta cố
///   update; cần GET lại và để người dùng xử lý bằng dialog.
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete, conflict }
