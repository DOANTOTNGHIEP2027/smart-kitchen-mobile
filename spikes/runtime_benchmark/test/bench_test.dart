import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:runtime_benchmark/bench/crash_ledger.dart';
import 'package:runtime_benchmark/bench/stats.dart';

void main() {
  group('percentile nearest-rank', () {
    final s = List<double>.generate(100, (i) => (i + 1).toDouble()); // 1..100

    test('p50/p95 của 1..100', () {
      expect(percentile(s, 50), 50);
      expect(percentile(s, 95), 95);
      expect(percentile(s, 100), 100);
    });

    test('không phụ thuộc thứ tự đầu vào, không nội suy', () {
      expect(percentile([30, 10, 20], 50), 20);
      expect(percentile([10, 20], 95), 20);
    });

    test('đầu vào sai → ArgumentError', () {
      expect(() => percentile([], 50), throwsArgumentError);
      expect(() => percentile([1], 0), throwsArgumentError);
    });

    test('delegateSpeedup null khi delegate không có', () {
      final cpu = WarmStats([10, 10]);
      expect(delegateSpeedup(cpu: cpu), isNull);
      expect(delegateSpeedup(cpu: cpu, delegate: WarmStats([5, 5])), 2);
    });
  });

  group('CrashLedger', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('ledger_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('phiên thành công / lỗi Dart / crash giữa phiên', () async {
      final l = CrashLedger(dir);
      await l.session('tflite/cpu', () async => 1);
      await expectLater(
          l.session('tflite/cpu', () async => throw StateError('x')),
          throwsStateError);

      // Mô phỏng process chết giữa phiên: marker còn, khởi động lại.
      File('${dir.path}/session_in_progress').writeAsStringSync('tflite/cpu');
      CrashLedger(dir).reconcileOnStartup();

      final e = CrashLedger(dir).summary()['tflite/cpu'] as Map;
      expect(e['sessions'], 2);
      expect(e['errors'], 1);
      expect(e['crashes'], 1);
      expect(e['crashFreeRate'], closeTo(2 / 3, 1e-9));
    });
  });
}
