class InventoryTransactionModel {
  const InventoryTransactionModel({
    required this.id,
    required this.inventoryItemId,
    required this.actorId,
    required this.reason,
    required this.quantityDelta,
    required this.unit,
    required this.quantityAfter,
    this.note,
    this.wasteCause,
    required this.createdAt,
  });

  final String id;
  final String inventoryItemId;
  final String actorId;
  final String reason;
  final double quantityDelta;
  final String unit;
  final double quantityAfter;
  final String? note;
  final String? wasteCause;
  final DateTime createdAt;
}

InventoryTransactionModel inventoryTransactionFromJson(
  Map<String, dynamic> json,
) {
  return InventoryTransactionModel(
    id: json['id'] as String,
    inventoryItemId: json['inventoryItemId'] as String,
    actorId: json['actorId'] as String,
    reason: json['reason'] as String,
    quantityDelta: (json['quantityDelta'] as num).toDouble(),
    unit: json['unit'] as String,
    quantityAfter: (json['quantityAfter'] as num).toDouble(),
    note: json['note'] as String?,
    wasteCause: json['wasteCause'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
