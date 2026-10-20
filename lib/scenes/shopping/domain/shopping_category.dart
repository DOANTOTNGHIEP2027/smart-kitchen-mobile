import 'package:flutter/painting.dart';

/// Category đi chợ local-only (#69 §7) — không `syncStatus`/`version`: mọi ghi
/// là SQLite cục bộ, không có network round-trip để "pending".
class ShoppingCategory {
  const ShoppingCategory({
    required this.id,
    required this.householdId,
    required this.name,
    required this.colorHex,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String name;
  final String colorHex;
  final int sortOrder;
  final DateTime createdAt;

  ShoppingCategory copyWith({String? name, String? colorHex, int? sortOrder}) =>
      ShoppingCategory(
        id: id,
        householdId: householdId,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}

/// 8 màu cố định — KHÔNG cho nhập hex tự do (Decision D5, Guard #5).
const List<String> categoryColorPalette = <String>[
  '#FF7A45',
  '#34A853',
  '#4285F4',
  '#B58900',
  '#E5484D',
  '#7C3AED',
  '#00A3A3',
  '#8E8E93',
];

/// Màu xám cho category đã dùng trên item nhưng chưa đặt màu local.
const String categoryDefaultColorHex = '#8E8E93';

/// Gợi ý category cho sheet thêm món (#69 §10): category local (có màu, theo
/// thứ tự người dùng xếp) TRƯỚC, rồi category đã dùng trên món (xám), rồi bộ
/// mặc định — không trùng tên (không phân biệt hoa/thường).
List<({String name, String colorHex})> categorySuggestions({
  required List<ShoppingCategory> local,
  required Iterable<String?> used,
  required List<String> defaults,
}) {
  final seen = <String>{};
  final result = <({String name, String colorHex})>[];
  void add(String? name, String colorHex) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) return;
    result.add((name: trimmed, colorHex: colorHex));
  }

  for (final c in local) {
    add(c.name, c.colorHex);
  }
  for (final name in used) {
    add(name, categoryDefaultColorHex);
  }
  for (final name in defaults) {
    add(name, categoryDefaultColorHex);
  }
  return result;
}

Color categoryColor(String hex) =>
    Color(int.parse('FF${hex.substring(1)}', radix: 16));
