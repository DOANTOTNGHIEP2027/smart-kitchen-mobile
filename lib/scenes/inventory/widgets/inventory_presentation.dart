import 'package:flutter/material.dart';

import '../domain/inventory_item.dart';

/// Keep depleted records available for sync/history, outside the visible stock.
List<InventoryItemModel> stockedInventoryItems(
        Iterable<InventoryItemModel> items) =>
    items.where((item) => item.quantity > 0).toList(growable: false);

String inventoryDisplayName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return trimmed;
  final first = trimmed.characters.first;
  return '${first.toUpperCase()}${trimmed.substring(first.length)}';
}
