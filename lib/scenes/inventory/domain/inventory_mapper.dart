import 'package:drift/drift.dart' show Value;

import '../../../data/db/app_database.dart';
import 'inventory_item.dart';
import 'sync_status.dart';

/// Parse một object JSON từ BE (camelCase — OAS v1.2.0) sang [InventoryItemModel].
///
/// Key JSON là **camelCase** (`householdId`, `createdAt`, `displayQuantity` …)
/// theo contract thật đã REVIEWED. Sai key trong Dart ném fail thường nhẹ —
/// field lặng lẽ về null — nên phải giữ khớp 100% OAS.
InventoryItemModel inventoryItemFromJson(Map<String, dynamic> json) {
  return InventoryItemModel(
    id: json['id'] as String,
    householdId: json['householdId'] as String,
    name: json['name'] as String,
    category: json['category'] as String?,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    displayQuantity: (json['displayQuantity'] as num?)?.toDouble(),
    displayUnit: json['displayUnit'] as String?,
    lowStockThreshold: (json['lowStockThreshold'] as num?)?.toDouble(),
    expiryDate: json['expiryDate'] == null
        ? null
        : DateTime.parse('${json['expiryDate']}T00:00:00Z'),
    note: json['note'] as String?,
    version: json['version'] as int,
    isLowStock: json['isLowStock'] as bool? ?? false,
    isExpiringSoon: json['isExpiringSoon'] as bool? ?? false,
    createdBy: json['createdBy'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// Đảo ngược: domain → JSON cho request body POST/PUT.
///
/// `displayQuantity`/`displayUnit` không gửi (BE chỉ nhận `quantity`/`unit`,
/// tự tính display* khi lưu). `version` cho PUT được ghép ở `InventoryApi`.
Map<String, dynamic> inventoryItemToPayload(InventoryItemModel item) {
  return <String, dynamic>{
    'name': item.name,
    'category': item.category,
    'quantity': item.quantity,
    'unit': item.unit,
    'lowStockThreshold': item.lowStockThreshold,
    'expiryDate': item.expiryDate?.toUtc().toIso8601String().split('T').first,
    'note': item.note,
  };
}

/// Drift row → domain. Khớp cột với [InventoryItems] table def.
///
/// Tham số `row` là Drift generated `InventoryItem` DataClass — tên trùng với
/// domain class cũ nên chú ý khi đọc: `InventoryItem` = Drift row,
/// `InventoryItemModel` = domain. Alias `as driftInventoryItem` không cần vì
/// import `app_database.dart` sẽ re-export Drift class.
InventoryItemModel inventoryItemFromRow(InventoryItem row) {
  return InventoryItemModel(
    id: row.id,
    householdId: row.householdId,
    name: row.name,
    category: row.category,
    quantity: row.quantity,
    unit: row.unit,
    displayQuantity: row.displayQuantity,
    displayUnit: row.displayUnit,
    lowStockThreshold: row.lowStockThreshold,
    expiryDate: row.expiryDate == null
        ? null
        : DateTime.parse('${row.expiryDate}T00:00:00Z'),
    note: row.note,
    version: row.version,
    isLowStock: row.isLowStock,
    isExpiringSoon: row.isExpiringSoon,
    createdBy: row.createdBy,
    createdAt: DateTime.parse(row.createdAt),
    updatedAt: DateTime.parse(row.updatedAt),
    syncStatus: _parseSyncStatus(row.syncStatus),
  );
}

/// Domain → Drift Companion (cho insertOnConflictUpdate).
InventoryItemsCompanion inventoryItemToRow(InventoryItemModel item) {
  return InventoryItemsCompanion.insert(
    id: item.id,
    householdId: item.householdId,
    name: item.name,
    category: Value<String?>(item.category),
    quantity: item.quantity,
    unit: item.unit,
    displayQuantity: Value<double?>(item.displayQuantity),
    displayUnit: Value<String?>(item.displayUnit),
    lowStockThreshold: Value<double?>(item.lowStockThreshold),
    expiryDate: Value<String?>(item.expiryDate?.toUtc().toIso8601String().split('T').first),
    note: Value<String?>(item.note),
    version: item.version,
    isLowStock: Value<bool>(item.isLowStock),
    isExpiringSoon: Value<bool>(item.isExpiringSoon),
    createdBy: item.createdBy,
    createdAt: item.createdAt.toUtc().toIso8601String(),
    updatedAt: item.updatedAt.toUtc().toIso8601String(),
    syncStatus: Value<String>(_syncStatusToString(item.syncStatus)),
  );
}

String _syncStatusToString(SyncStatus s) {
  switch (s) {
    case SyncStatus.synced:
      return 'SYNCED';
    case SyncStatus.pendingCreate:
      return 'PENDING_CREATE';
    case SyncStatus.pendingUpdate:
      return 'PENDING_UPDATE';
    case SyncStatus.pendingDelete:
      return 'PENDING_DELETE';
    case SyncStatus.conflict:
      return 'CONFLICT';
  }
}

SyncStatus _parseSyncStatus(String raw) {
  switch (raw) {
    case 'SYNCED':
      return SyncStatus.synced;
    case 'PENDING_CREATE':
      return SyncStatus.pendingCreate;
    case 'PENDING_UPDATE':
      return SyncStatus.pendingUpdate;
    case 'PENDING_DELETE':
      return SyncStatus.pendingDelete;
    case 'CONFLICT':
      return SyncStatus.conflict;
    default:
      return SyncStatus.synced;
  }
}
