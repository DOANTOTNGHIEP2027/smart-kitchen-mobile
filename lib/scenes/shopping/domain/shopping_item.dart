enum ShoppingItemStatus { pending, completed }
enum ShoppingItemSource { manual, auto }
enum ShoppingSyncStatus { synced, pendingCreate, pendingToggle }

/// Món trong thực đơn đã sinh ra dòng đi chợ này (BE `sources`). Dòng tạo
/// cục bộ chưa lên server chỉ biết [dishId].
class ShoppingSourceRef {
  const ShoppingSourceRef({
    required this.dishId,
    this.slotDate,
    this.mealTime,
    this.recipeName,
  });

  final String dishId;

  /// `yyyy-MM-dd` như BE trả.
  final String? slotDate;
  final String? mealTime;

  /// Công thức của món LÚC tạo dòng — món đổi công thức thì dòng cũ hết đúng.
  final String? recipeName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dishId': dishId,
        if (slotDate != null) 'slotDate': slotDate,
        if (mealTime != null) 'mealTime': mealTime,
        if (recipeName != null) 'recipeName': recipeName,
      };

  static ShoppingSourceRef? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final dishId = raw['dishId'];
    if (dishId is! String || dishId.isEmpty) return null;
    return ShoppingSourceRef(
      dishId: dishId,
      slotDate: raw['slotDate'] as String?,
      mealTime: raw['mealTime'] as String?,
      recipeName: raw['recipeName'] as String?,
    );
  }
}

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
    this.inInventory = false,
    this.sourceRefs = const <ShoppingSourceRef>[],
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

  /// #239: đã cất vào kho — status vẫn completed nhưng không toggle được nữa.
  final bool inInventory;

  /// Món thực đơn sinh ra dòng này — rỗng = thêm tay / BE cũ.
  final List<ShoppingSourceRef> sourceRefs;

  bool get isPendingSync => syncStatus != ShoppingSyncStatus.synced;

  /// Đang giao cho [userId] — 1 định nghĩa dùng chung cho badge và filter
  /// "Của tôi".
  bool isAssignedTo(String? userId) => userId != null && assignedTo == userId;
  bool get canToggle => syncStatus != ShoppingSyncStatus.pendingCreate && !inInventory;

  /// #239: đã mua, chưa vào kho — đếm cho nút "Cất vào kho (n)".
  bool get awaitsInventory => status == ShoppingItemStatus.completed && !inInventory;

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
    bool? inInventory,
    List<ShoppingSourceRef>? sourceRefs,
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
    inInventory: inInventory ?? this.inInventory,
    sourceRefs: sourceRefs ?? this.sourceRefs,
  );
}
