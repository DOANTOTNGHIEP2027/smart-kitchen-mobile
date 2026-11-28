import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../data/db/app_database.dart';
import '../domain/shopping_item.dart';

ShoppingItem shoppingItemFromJson(Map<String, dynamic> json, String householdId) =>
    ShoppingItem(
      id: json['id'] as String,
      householdId: householdId,
      shoppingListId: json['shoppingListId'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      displayQuantity: (json['displayQuantity'] as num).toDouble(),
      displayUnit: json['displayUnit'] as String,
      category: json['category'] as String?,
      status: (json['status'] as String) == 'COMPLETED'
          ? ShoppingItemStatus.completed
          : ShoppingItemStatus.pending,
      source: (json['source'] as String) == 'AUTO'
          ? ShoppingItemSource.auto
          : ShoppingItemSource.manual,
      version: json['version'] as int,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      price: (json['price'] as num?)?.toDouble(),
      assignedTo: json['assignedTo'] as String?,
      // #239 additive — BE cũ không gửi thì coi như chưa vào kho.
      inInventory: json['inInventory'] as bool? ?? false,
      // BE đặt tên field là `sources` (cột `source_refs`, #201).
      sourceRefs: _sourceRefs(json['sources']),
    );

/// Additive — BE cũ không gửi / phần tử hỏng thì bỏ qua (không ném).
List<ShoppingSourceRef> _sourceRefs(Object? raw) => raw is List
    ? raw.map(ShoppingSourceRef.fromJson).whereType<ShoppingSourceRef>().toList()
    : const <ShoppingSourceRef>[];

ShoppingItem shoppingItemFromRow(ShoppingListItem row) => ShoppingItem(
      id: row.id,
      householdId: row.householdId,
      shoppingListId: row.shoppingListId,
      name: row.name,
      quantity: row.quantity,
      unit: row.unit,
      displayQuantity: row.displayQuantity,
      displayUnit: row.displayUnit,
      category: row.category,
      status: row.status == 'COMPLETED'
          ? ShoppingItemStatus.completed
          : ShoppingItemStatus.pending,
      source: row.source == 'AUTO' ? ShoppingItemSource.auto : ShoppingItemSource.manual,
      version: row.version,
      createdBy: row.createdBy,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
      syncStatus: switch (row.syncStatus) {
        'PENDING_CREATE' => ShoppingSyncStatus.pendingCreate,
        'PENDING_TOGGLE' => ShoppingSyncStatus.pendingToggle,
        _ => ShoppingSyncStatus.synced,
      },
      price: row.price,
      assignedTo: row.assignedTo,
      inInventory: row.inInventory,
      sourceRefs: row.sourceRefs == null ? const <ShoppingSourceRef>[] : _sourceRefs(jsonDecode(row.sourceRefs!)),
    );

ShoppingListItemsCompanion shoppingItemToRow(ShoppingItem item) =>
    ShoppingListItemsCompanion.insert(
      id: item.id,
      householdId: item.householdId,
      shoppingListId: Value(item.shoppingListId),
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      displayQuantity: item.displayQuantity,
      displayUnit: item.displayUnit,
      category: Value(item.category),
      status: item.status == ShoppingItemStatus.completed ? 'COMPLETED' : 'PENDING',
      source: item.source == ShoppingItemSource.auto ? 'AUTO' : 'MANUAL',
      version: item.version,
      createdBy: Value(item.createdBy),
      createdAt: item.createdAt.toUtc().toIso8601String(),
      updatedAt: item.updatedAt.toUtc().toIso8601String(),
      syncStatus: Value(item.syncStatus == ShoppingSyncStatus.pendingCreate
          ? 'PENDING_CREATE'
          : item.syncStatus == ShoppingSyncStatus.pendingToggle
              ? 'PENDING_TOGGLE'
              : 'SYNCED'),
      price: Value(item.price),
      assignedTo: Value(item.assignedTo),
      inInventory: Value(item.inInventory),
      sourceRefs: Value(item.sourceRefs.isEmpty
          ? null
          : jsonEncode(item.sourceRefs.map((r) => r.toJson()).toList())),
    );

Map<String, dynamic> shoppingCreatePayload(ShoppingItem item) => <String, dynamic>{
  'name': item.name,
  'quantity': item.quantity,
  'unit': item.unit,
  'category': item.category,
  // Gắn món thực đơn → BE ghi `sourceRefs`; xoá món rồi "Hoàn thành" thì dọn được.
  if (item.sourceRefs.isNotEmpty) 'sourceDishId': item.sourceRefs.first.dishId,
};
