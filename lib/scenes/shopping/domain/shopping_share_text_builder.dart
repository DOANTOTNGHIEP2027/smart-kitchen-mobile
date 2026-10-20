import 'shopping_item.dart';

class ShoppingCategoryGroup {
  const ShoppingCategoryGroup({required this.category, required this.items});

  /// `null` = chưa phân loại (luôn đứng cuối).
  final String? category;
  final List<ShoppingItem> items;
}

/// Chuỗi cố định của share text — do widget lấy từ l10n truyền vào, builder
/// không đụng `BuildContext` (Guard #7).
class ShoppingShareLabels {
  const ShoppingShareLabels({
    required this.header,
    required this.progress,
    required this.uncategorized,
    required this.footer,
  });

  final String header;
  final String Function(int checked, int total) progress;
  final String uncategorized;
  final String footer;
}

/// Pure function — không I/O, không Clipboard, không BuildContext (#69 §11, Guard #7).
class ShoppingShareTextBuilder {
  const ShoppingShareTextBuilder._();

  /// Group TOÀN BỘ [allItems] — KHÔNG theo filter UI nào đang bật trên màn
  /// danh sách (Guard #12, Fix HIGH-1). Category `null` cuối; trong nhóm: chưa
  /// mua trước, rồi tên tăng dần.
  static List<ShoppingCategoryGroup> groupAllForShare(List<ShoppingItem> allItems) {
    final byCategory = <String?, List<ShoppingItem>>{};
    for (final item in allItems) {
      (byCategory[item.category] ??= <ShoppingItem>[]).add(item);
    }
    final categories = byCategory.keys.toList()
      ..sort((a, b) {
        if (a == null) return b == null ? 0 : 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });
    return <ShoppingCategoryGroup>[
      for (final c in categories)
        ShoppingCategoryGroup(
          category: c,
          items: byCategory[c]!
            ..sort((x, y) {
              final byStatus = _done(x).compareTo(_done(y));
              return byStatus != 0 ? byStatus : x.name.compareTo(y.name);
            }),
        ),
    ];
  }

  static int _done(ShoppingItem i) => i.status == ShoppingItemStatus.completed ? 1 : 0;

  /// [memberNamesById] = `userId → tên` do widget dựng từ roster. Hậu tố
  /// ` — @Tên` CHỈ khi giải được tên thật — không in UUID/"Thành viên cũ"
  /// (Guard #14). KHÔNG in giá (Guard #13).
  static String build({
    required List<ShoppingCategoryGroup> groups,
    required int checkedCount,
    required int totalCount,
    required ShoppingShareLabels labels,
    Map<String, String> memberNamesById = const <String, String>{},
  }) {
    final buffer = StringBuffer()
      ..writeln(labels.header)
      ..writeln(labels.progress(checkedCount, totalCount))
      ..writeln();
    for (final group in groups) {
      buffer.writeln('📌 ${group.category ?? labels.uncategorized}');
      for (final item in group.items) {
        final mark = item.status == ShoppingItemStatus.completed ? '☑' : '☐';
        final assignee = item.assignedTo == null ? null : memberNamesById[item.assignedTo];
        final suffix = assignee == null ? '' : ' — @$assignee';
        buffer.writeln('$mark ${item.name} — ${_formatQuantity(item.displayQuantity)}${item.displayUnit}$suffix');
      }
      buffer.writeln();
    }
    buffer.write(labels.footer);
    return buffer.toString();
  }

  static String _formatQuantity(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
}
