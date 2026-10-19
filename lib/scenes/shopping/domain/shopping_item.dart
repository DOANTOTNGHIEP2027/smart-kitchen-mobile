enum ShoppingItemStatus { pending, completed }
enum ShoppingItemSource { manual, auto }
enum ShoppingSyncStatus { synced, pendingCreate, pendingToggle }

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.householdId,
    this.shoppingListId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.displayQuantity,
    required this.displayUnit,
    this.category,
    required this.status,
    required this.source,
    required this.version,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = ShoppingSyncStatus.synced,
    this.price,
    this.assignedTo,
  });

  final String id;
  final String householdId;
  final String? shoppingListId;
  final String name;
  final double quantity;
  final String unit;
  final double displayQuantity;
  final String displayUnit;
  final String? category;
  final ShoppingItemStatus status;
  final ShoppingItemSource source;
  final int version;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShoppingSyncStatus syncStatus;

  /// Giá VND nhập khi tick (#133). `null` = chưa nhập — KHÁC `0` (miễn phí).
  /// Sticky ở BE khi bỏ tick, nên FE không bao giờ xoá giá trị này.
  final double? price;

  /// UUID người được giao mua (#134). KHÔNG BAO GIỜ hiển thị thô (Guard #15).
  final String? assignedTo;

  bool get isPendingSync => syncStatus != ShoppingSyncStatus.synced;

  /// Đang giao cho [userId] — 1 định nghĩa dùng chung cho badge và filter
  /// "Của tôi".
  bool isAssignedTo(String? userId) => userId != null && assignedTo == userId;
  bool get canToggle => syncStatus != ShoppingSyncStatus.pendingCreate;

  ShoppingItem copyWith({
    String? id,
    String? shoppingListId,
    String? name,
    double? quantity,
    String? unit,
    double? displayQuantity,
    String? displayUnit,
    String? category,
    ShoppingItemStatus? status,
    ShoppingItemSource? source,
    int? version,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    ShoppingSyncStatus? syncStatus,
    double? price,
    String? assignedTo,
  }) => ShoppingItem(
    id: id ?? this.id,
    householdId: householdId,
    shoppingListId: shoppingListId ?? this.shoppingListId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    displayQuantity: displayQuantity ?? this.displayQuantity,
    displayUnit: displayUnit ?? this.displayUnit,
    category: category ?? this.category,
    status: status ?? this.status,
    source: source ?? this.source,
    version: version ?? this.version,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    price: price ?? this.price,
    assignedTo: assignedTo ?? this.assignedTo,
  );
}
