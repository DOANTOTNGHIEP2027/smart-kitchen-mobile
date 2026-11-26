import 'dart:convert';
import 'dart:io';

/// Đếm crash-free rate thật: trước mỗi phiên (load → infer → dispose) ghi
/// marker; xong phiên thì xoá. App khởi động lại mà marker còn ⇒ phiên trước
/// chết giữa chừng (crash native không bắt được bằng try/catch) ⇒ +1 crash.
class CrashLedger {
  CrashLedger(this._dir);

  final Directory _dir;

  File get _ledger => File('${_dir.path}/crash_ledger.json');
  File get _marker => File('${_dir.path}/session_in_progress');

  Map<String, dynamic> _read() => _ledger.existsSync()
      ? jsonDecode(_ledger.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};

  void _write(Map<String, dynamic> m) => _ledger.writeAsStringSync(jsonEncode(m));

  Map<String, int> _entry(Map<String, dynamic> all, String key) =>
      Map<String, int>.from(
          (all[key] as Map?) ?? {'sessions': 0, 'crashes': 0, 'errors': 0});

  /// Gọi 1 lần lúc app khởi động — quy marker sót lại thành crash.
  void reconcileOnStartup() {
    if (!_marker.existsSync()) return;
    final key = _marker.readAsStringSync();
    final all = _read();
    final e = _entry(all, key);
    e['crashes'] = e['crashes']! + 1;
    all[key] = e;
    _write(all);
    _marker.deleteSync();
  }

  /// Chạy [body] như một phiên của cấu hình [key]. Exception Dart tính là
  /// `errors` (không phải crash), vẫn ném lại cho caller hiển thị.
  Future<T> session<T>(String key, Future<T> Function() body) async {
    _marker.writeAsStringSync(key, flush: true);
    final all = _read();
    final e = _entry(all, key);
    e['sessions'] = e['sessions']! + 1;
    try {
      return await body();
    } catch (_) {
      e['errors'] = e['errors']! + 1;
      rethrow;
    } finally {
      all[key] = e;
      _write(all);
      if (_marker.existsSync()) _marker.deleteSync();
    }
  }

  /// `{key: {sessions, crashes, errors, crashFreeRate}}`. Phiên crash không
  /// kịp ghi `sessions` nên mẫu số = sessions + crashes.
  Map<String, dynamic> summary() => _read().map((k, v) {
        final e = Map<String, int>.from(v as Map);
        final total = e['sessions']! + e['crashes']!;
        return MapEntry(k, {
          ...e,
          'crashFreeRate': total == 0 ? null : 1 - e['crashes']! / total,
        });
      });

  void reset() {
    if (_ledger.existsSync()) _ledger.deleteSync();
    if (_marker.existsSync()) _marker.deleteSync();
  }
}
