// Giữ dấu liên kết trong note của API hiện hữu, không hiện mã nội bộ trong form.
final _shoppingMarker = RegExp(r'\[shopping-item:[^\]\r\n]+\]');

String? shoppingMarkerIn(String? note) =>
    note == null ? null : _shoppingMarker.firstMatch(note)?.group(0);

String visibleInventoryNote(String? note) =>
    (note ?? '').replaceAll(_shoppingMarker, '').trim();

String preserveShoppingMarker(String? original, String edited) {
  final marker = shoppingMarkerIn(original);
  return [edited.trim(), if (marker != null) marker]
      .where((part) => part.isNotEmpty)
      .join('\n');
}
