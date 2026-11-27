import 'package:flutter/widgets.dart';

/// Viết hoa ký tự đầu, giữ nguyên phần còn lại — chỉ dùng khi HIỂN THỊ.
/// Tách theo grapheme (`characters`) để chữ có dấu tổ hợp như "đ", "ư", "ộ"
/// không bị cắt đôi. Chuỗi rỗng trả về rỗng.
String capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  final chars = text.characters;
  return chars.first.toUpperCase() + chars.skip(1).toString();
}
