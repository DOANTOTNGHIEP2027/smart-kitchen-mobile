import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/insights/widgets/chart_gap_utils.dart';

void main() {
  group('buildGapSegments', () {
    test('gap ở giữa (index 2-4 null) → 2 segment, x KHÔNG renumber', () {
      final segments = buildGapSegments(
        7,
        (i) => i >= 2 && i <= 4 ? null : (i * 10).toDouble(),
      );

      expect(segments.length, 2);
      expect(segments[0].map((s) => s.x.toInt()).toList(), <int>[0, 1]);
      expect(segments[1].map((s) => s.x.toInt()).toList(), <int>[5, 6]);
    });

    test('toàn bộ null → 0 segment', () {
      final segments = buildGapSegments(5, (_) => null);
      expect(segments, isEmpty);
    });

    test('toàn bộ có giá trị → đúng 1 segment', () {
      final segments = buildGapSegments(4, (i) => i.toDouble());
      expect(segments.length, 1);
      expect(segments.single.length, 4);
    });

    test('null ở đầu/cuối giữ index gốc cho segment sau', () {
      final segments = buildGapSegments(
        5,
        (i) => i == 0 || i == 4 ? null : i.toDouble(),
      );
      expect(segments.length, 1);
      expect(segments.single.map((s) => s.x.toInt()).toList(), <int>[1, 2, 3]);
    });

    test('segment thứ 2 bắt đầu đúng index 5 (không phải 0)', () {
      final segments = buildGapSegments(
        8,
        (i) => i < 5 ? null : i.toDouble(),
      );
      expect(segments.length, 1);
      expect(segments.single.first.x, 5);
    });
  });

  group('FlSpot', () {
    test('giữ nguyên x index gốc trong từng segment', () {
      final segments = buildGapSegments(
        10,
        (i) => i.isOdd ? i.toDouble() : null,
      );
      final xs = segments
          .expand((s) => s)
          .map((s) => s.x.toInt())
          .toList();
      // Các index lẻ: 1,3,5,7,9 — không segment nào bắt đầu lại từ 0.
      expect(xs, <int>[1, 3, 5, 7, 9]);
    });
  });
}