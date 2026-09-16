import 'sync_status.dart';

/// Một mặt hàng trong kho household (FE-5 §6).
///
/// Tên class cố tình có hậu tố `Model` để tránh ambiguous import với Drift
/// generated `InventoryItem` DataClass (cùng tên vì Drift sinh class theo tên
/// table). `InventoryItemModel` là domain object dùng khắp store/scene/widget;
/// Drift row chỉ xuất hiện nội bộ [InventoryDao] + [InventoryMapper].
///
/// Vì sao có riêng [displayQuantity]/[displayUnit]: BE lưu hai mốc — canonical
/// (`quantity`/`unit`) để tính toán, và `display*` để hiển thị nguyên văn cái
/// người dùng gõ (vd `1.5 kg` thay vì `1500 GRAM`). FE KHÔNG tự quy đổi — chỉ
/// BE quyết định canonical (Decision D3).
class InventoryItemModel {
  InventoryItemModel({
    required this.id,
    required this.householdId,
    required this.name,
    this.category,
    required this.quantity,
    required this.unit,
    this.displayQuantity,
    this.displayUnit,
    this.lowStockThreshold,
    this.expiryDate,
    this.note,
    required this.version,
    required this.isLowStock,
    required this.isExpiringSoon,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  final String id;
  final String householdId;
  final String name;
  final String? category;
  final double quantity;
  final String unit;
  final double? displayQuantity;
  final String? displayUnit;
  final double? lowStockThreshold;
  final DateTime? expiryDate;
  final String? note;
  final int version;
  final bool isLowStock;
  final bool isExpiringSoon;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  bool get isPendingSync =>
      syncStatus == SyncStatus.pendingCreate ||
      syncStatus == SyncStatus.pendingUpdate;
  bool get hasConflict => syncStatus == SyncStatus.conflict;

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? displayQuantity,
    String? displayUnit,
    double? lowStockThreshold,
    DateTime? expiryDate,
    String? note,
    int? version,
    bool? isLowStock,
    bool? isExpiringSoon,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      householdId: householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      displayQuantity: displayQuantity ?? this.displayQuantity,
      displayUnit: displayUnit ?? this.displayUnit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expiryDate: expiryDate ?? this.expiryDate,
      note: note ?? this.note,
      version: version ?? this.version,
      isLowStock: isLowStock ?? this.isLowStock,
      isExpiringSoon: isExpiringSoon ?? this.isExpiringSoon,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
