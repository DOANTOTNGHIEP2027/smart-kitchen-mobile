import 'package:flutter/material.dart';

/// Danh sách phân loại chuẩn dùng chung kho + đi chợ + hoá đơn (#201).
///
/// `category` trên BE vẫn là free-text (inventory-core OAS v1.4.0) — đây là
/// bộ tên chuẩn để FE gợi ý/hiển thị thống nhất. Tên là DỮ LIỆU gửi lên BE
/// (không phải chữ UI), nên giữ nguyên tiếng Việt ở mọi locale.
enum FoodCategory {
  vegetables('Rau củ', Icons.eco_rounded, Color(0xFF22C55E), Color(0xFFEAF7EE)),
  meat('Thịt', Icons.kebab_dining_rounded, Color(0xFFE85F2A), Color(0xFFFFECE5)),
  seafood('Hải sản', Icons.set_meal_rounded, Color(0xFF0E7490), Color(0xFFE0F5F8)),
  eggsDairy('Trứng & sữa', Icons.egg_outlined, Color(0xFFE5A100), Color(0xFFFFF7E0)),
  spices('Gia vị', Icons.soup_kitchen_rounded, Color(0xFFD97706), Color(0xFFFFF0E6)),
  dryGoods('Đồ khô & ngũ cốc', Icons.grain_rounded, Color(0xFF78716C), Color(0xFFF1EEEA)),
  fruits('Trái cây', Icons.local_florist_rounded, Color(0xFFDB2777), Color(0xFFFDEBF3)),
  drinks('Đồ uống', Icons.local_cafe_rounded, Color(0xFF0284C7), Color(0xFFE8F4FD)),
  other('Khác', Icons.kitchen_outlined, Color(0xFF78716C), Color(0xFFF1EEEA));

  const FoodCategory(this.label, this.icon, this.iconColor, this.backgroundColor);

  /// Tên chuẩn — đúng chuỗi gửi lên BE trong field `category`.
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  /// Tên chuẩn theo đúng thứ tự hiển thị.
  static List<String> get labels =>
      FoodCategory.values.map((c) => c.label).toList(growable: false);

  /// Khớp lỏng tên phân loại (kể cả tên cũ "Thịt cá", "Trứng sữa",
  /// "Thực phẩm khô", "Ngũ cốc"…) về một [FoodCategory]. `null` khi không nhận
  /// ra hoặc rỗng — người gọi tự coi như [other].
  static FoodCategory? match(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';
    if (s.isEmpty) return null;
    for (final c in FoodCategory.values) {
      if (c.label.toLowerCase() == s) return c;
    }
    bool has(String k) => s.contains(k);
    // Thứ tự có ý nghĩa: "Thịt cá" (tên cũ) phải về Thịt, không về Hải sản.
    if (has('rau') || has('củ') || has('nấm')) return vegetables;
    if (has('thịt')) return meat;
    if (has('hải sản') || has('cá') || has('tôm') || has('mực') || has('cua')) {
      return seafood;
    }
    if (has('trứng') || has('sữa')) return eggsDairy;
    if (has('gia vị') || has('nước chấm') || has('nước mắm')) return spices;
    if (has('khô') || has('ngũ cốc') || has('gạo') || has('hạt') || has('mì')) {
      return dryGoods;
    }
    if (has('trái cây') || has('hoa quả') || has('quả')) return fruits;
    if (has('uống') || has('nước')) return drinks;
    if (has('khác')) return other;
    return null;
  }

  /// Style hiển thị cho mọi chuỗi phân loại — không nhận ra thì [other].
  static FoodCategory styleOf(String? raw) => match(raw) ?? other;

  /// Sắp xếp danh sách tên phân loại: tên chuẩn theo thứ tự chuẩn trước, tên
  /// tự do còn lại theo bảng chữ cái sau.
  static List<String> sortNames(Iterable<String> names) {
    final canonical = labels;
    final list = names.toSet().toList();
    list.sort((a, b) {
      final ia = canonical.indexOf(a), ib = canonical.indexOf(b);
      if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
      if (ia >= 0) return -1;
      if (ib >= 0) return 1;
      return a.compareTo(b);
    });
    return list;
  }
}
