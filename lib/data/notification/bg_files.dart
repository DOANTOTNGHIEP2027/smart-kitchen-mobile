import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show IsolateNameServer;

import 'package:path_provider/path_provider.dart';

import 'cross_isolate_lock.dart';

/// Tên port UI isolate đăng ký để isolate nền "ping" catch-up kho (A8).
const String inventoryCatchUpPortName = 'sk.inventory.catchup';

/// Ping best-effort: port chết / chưa đăng ký ⇒ rơi im lặng, cờ file vẫn còn
/// cho lần resume.
void pingInventoryCatchUp() {
  IsolateNameServer.lookupPortByName(inventoryCatchUpPortName)?.send(null);
}

/// File dùng chung giữa isolate nền và UI isolate trong
/// `<appSupport>/notification_bg/` (A1, A7, A8). Không dùng temp/cache — OS
/// có thể dọn. Không `SharedPreferences` (E6): file không có cache theo
/// isolate nên không cần `reload()`.
class BgFiles {
  BgFiles({
    required Future<Directory> Function() baseDirectory,
    int Function()? currentPid,
    DateTime Function()? now,
    this.inFlightTtl = const Duration(seconds: 15),
  })  : _baseDirectory = baseDirectory,
        _currentPid = currentPid ?? (() => pid),
        _now = now ?? DateTime.now;

  factory BgFiles.production() =>
      BgFiles(baseDirectory: getApplicationSupportDirectory);

  static const String directoryName = 'notification_bg';
  static const String pendingSyncFileName = 'inventory_pending_sync';

  final Future<Directory> Function() _baseDirectory;
  final int Function() _currentPid;
  final DateTime Function() _now;

  /// TTL guard in-flight 15 s > deadline 9 s của runner (A7).
  final Duration inFlightTtl;

  Future<Directory>? _directory;

  /// `<base>/notification_bg/`, tạo nếu chưa có. Lỗi ⇒ lần gọi sau thử lại.
  Future<Directory> directory() => _directory ??= _resolve();

  Future<Directory> _resolve() async {
    try {
      final base = await _baseDirectory();
      return await Directory(
        '${base.path}${Platform.pathSeparator}$directoryName',
      ).create(recursive: true);
    } catch (_) {
      _directory = null;
      rethrow;
    }
  }

  Future<File> _file(String name) async =>
      File('${(await directory()).path}${Platform.pathSeparator}$name');

  /// Isolate nền: sự tồn tại của file là cờ "kho đã đổi từ nền". Nội dung
  /// là marker DUY NHẤT mỗi lần ghi (thời điểm + số ngẫu nhiên) để UI isolate
  /// so rồi mới xoá (review #134 M1) — 2 lần bấm cùng mili-giây vẫn khác nhau.
  Future<void> markInventoryPendingSync() async {
    final file = await _file(pendingSyncFileName);
    final nonce = Random().nextInt(1 << 32).toRadixString(16);
    await file.writeAsString(
      '${_now().millisecondsSinceEpoch}-$nonce',
      flush: true,
    );
  }

  Future<bool> hasInventoryPendingSync() async =>
      (await _file(pendingSyncFileName)).exists();

  /// Marker hiện tại; `null` = không có cờ.
  Future<String?> readInventoryPendingSync() async {
    final file = await _file(pendingSyncFileName);
    try {
      return await file.readAsString();
    } on FileSystemException {
      if (!await file.exists()) return null;
      rethrow;
    }
  }

  /// So rồi xoá: chỉ xoá khi nội dung vẫn là [marker] đã đọc trước khi sync.
  /// `false` ⇒ nền đã ghi cờ mới trong lúc sync (hoặc xoá lỗi) — cờ còn,
  /// caller chạy thêm lượt.
  ///
  /// Còn 1 cửa sổ dưới mili-giây giữa lần đọc lại và `delete()` (file system
  /// không có compare-and-delete); nền ghi đúng lúc đó thì cờ mới bị xoá và
  /// thay đổi chỉ hiện ở lần sync kế tiếp (WS / pull-to-refresh / resume).
  Future<bool> clearInventoryPendingSyncIf(String marker) async {
    final file = await _file(pendingSyncFileName);
    await deleteIfOwned(file, (raw) => raw == marker);
    return !await file.exists();
  }

  /// Guard chống double-fire `qa_<itemId>.inflight` (A7, Guard 27). `null` ⇒
  /// đang có lần bấm khác cùng item (cùng pid, chưa quá TTL) ⇒ runner thoát.
  Future<InFlightGuard?> tryAcquireInFlight({
    required String itemId,
    required String action,
  }) async {
    final file = await _file('qa_${_safeName(itemId)}.inflight');
    late String written;
    final created = await createExclusiveOrSteal(
      file,
      content: () => written = jsonEncode(<String, Object>{
        'action': action,
        'pid': _currentPid(),
        'at': _now().millisecondsSinceEpoch,
      }),
      ttl: inFlightTtl,
      currentPid: _currentPid,
      now: _now,
    );
    return created ? InFlightGuard._(file, written) : null;
  }

  static String _safeName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}

class InFlightGuard {
  InFlightGuard._(this._file, this._content);

  final File _file;
  final String _content;

  /// Chỉ xoá khi nội dung vẫn là của mình (không xoá guard đã bị steal).
  /// Thử lại khi `delete()` lỗi (Windows sharing violation — review #134 H1).
  Future<void> release() async {
    await deleteIfOwned(_file, (raw) => raw == _content);
  }
}
