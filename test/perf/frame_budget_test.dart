import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/perf/frame_budget.dart';

/// #93 §6.8 — bằng chứng logic đo đúng dù chưa có thiết bị.
void main() {
  test('(a) đúng 16 667µs → không jank; 16 668µs → jank', () {
    final ok = summarizeFrames(<int>[16667], <int>[16667], <int>[16667]);
    expect(ok.jankFrames, 0);
    expect(ok.pass, isTrue);

    final over = summarizeFrames(<int>[16668], <int>[1000], <int>[17668]);
    expect(over.jankFrames, 1);
    expect(over.pass, isFalse);
  });

  test('(b) raster vượt, build không → jank', () {
    final r = summarizeFrames(<int>[5000], <int>[20000], <int>[25000]);
    expect(r.jankFrames, 1);
    expect(r.worstRasterMs, 20.0);
  });

  test('(c) list rỗng → pass == false (không PASS giả)', () {
    final r = summarizeFrames(<int>[], <int>[], <int>[]);
    expect(r.frameCount, 0);
    expect(r.pass, isFalse);
  });

  test('(d) 3 list lệch độ dài → ArgumentError', () {
    expect(
      () => summarizeFrames(<int>[1, 2], <int>[1], <int>[1, 2]),
      throwsArgumentError,
    );
  });

  test('(e) totalSpan vượt, build/raster không → jank 0, spanOver 1', () {
    final r = summarizeFrames(<int>[10000], <int>[10000], <int>[30000]);
    expect(r.jankFrames, 0);
    expect(r.totalSpanOverBudget, 1);
    expect(r.pass, isTrue);
  });

  test('p90 theo nearest-rank + toJson đủ key', () {
    final build = List<int>.generate(10, (i) => (i + 1) * 1000);
    final r = summarizeFrames(build, build, build);
    expect(r.p90BuildMs, 9.0);
    expect(r.worstBuildMs, 10.0);
    expect(r.toJson().keys,
        containsAll(<String>['frame_count', 'jank_frames', 'pass']));
  });
}
