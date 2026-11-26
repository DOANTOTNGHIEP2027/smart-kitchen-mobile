import 'dart:io';

import 'crash_ledger.dart';
import 'runners.dart';
import 'stats.dart';

/// Đo 1 cấu hình (§4.3): cold load = tạo runtime → xong lần suy luận đầu
/// (ML Kit nạp model lười ở lần processImage đầu, nên gộp cả hai cho công bằng);
/// warm = [warmup] lần bỏ qua rồi [warmRuns] lần tính giờ.
Future<Map<String, dynamic>> benchOne(
  RuntimeRunner r,
  CrashLedger ledger, {
  int warmup = 3,
  int warmRuns = 50,
}) async {
  try {
    return await ledger.session(r.id, () async {
      final sw = Stopwatch()..start();
      await r.load();
      await r.inferOnce();
      final coldMs = sw.elapsedMicroseconds / 1000;

      for (var i = 0; i < warmup; i++) {
        await r.inferOnce();
      }
      final samples = <double>[];
      for (var i = 0; i < warmRuns; i++) {
        sw
          ..reset()
          ..start();
        await r.inferOnce();
        samples.add(sw.elapsedMicroseconds / 1000);
      }
      await r.dispose();
      return {
        'id': r.id,
        'ok': true,
        'coldLoadMs': (coldMs * 100).roundToDouble() / 100,
        'warm': WarmStats(samples).toJson(),
      };
    });
  } catch (e) {
    await r.dispose().catchError((_) {});
    // Delegate/EP không hỗ trợ cũng rơi vào đây — ghi nguyên văn, không suy diễn.
    return {'id': r.id, 'ok': false, 'error': e.toString()};
  }
}

/// Tổng hợp báo cáo: delegate speedup = p50 CPU / p50 delegate cùng runtime.
Map<String, dynamic> buildReport({
  required String device,
  required List<Map<String, dynamic>> results,
  required CrashLedger ledger,
}) {
  double? p50(String id) {
    final r = results.where((e) => e['id'] == id && e['ok'] == true);
    return r.isEmpty ? null : (r.first['warm'] as Map)['p50Ms'] as double;
  }

  final speedup = <String, double?>{};
  for (final r in results) {
    final id = r['id'] as String;
    final runtime = id.split('/').first;
    if (id.endsWith('/cpu') || runtime == 'mlkit') continue;
    final cpu = p50('$runtime/cpu');
    final del = p50(id);
    speedup[id] = (cpu == null || del == null)
        ? null
        : ((cpu / del) * 100).roundToDouble() / 100;
  }

  return {
    'device': device,
    'os': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    'measuredAt': DateTime.now().toIso8601String(),
    'results': results,
    'delegateSpeedupVsCpu': speedup,
    'crashLedger': ledger.summary(),
  };
}
