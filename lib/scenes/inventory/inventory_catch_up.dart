import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:get/get.dart';

import '../../data/notification/bg_files.dart';
import 'stores/inventory_store.dart';

/// Thứ catch-up cần từ store — tách ra để test không phải dựng
/// `InventoryStore` thật.
class InventoryCatchUpTarget {
  const InventoryCatchUpTarget({required this.sync});

  /// `true` CHỈ khi đã thật sự đồng bộ xong household hiện tại (review #134
  /// L1): `syncFromServer` trả sớm khi chưa có household, `break` khi
  /// household đổi giữa chừng (epoch cũ), và NUỐT `ApiException` vào
  /// `syncError` — cả 3 trường hợp đều không được xoá cờ.
  InventoryCatchUpTarget.fromStore(InventoryStore store)
      : sync = (() async {
          if (store.householdId == null) return false;
          final epoch = store.householdEpoch;
          await store.syncFromServer();
          return store.syncError == null && !store.isStaleEpoch(epoch);
        });

  final Future<bool> Function() sync;
}

/// Đồng bộ kho ở UI isolate khi isolate nền đã đổi kho bằng quick-action
/// (inventory-management.md §20.3 Amendment #134 A8, Guard 18).
///
/// Gọi từ: `resumed`, ping port [inventoryCatchUpPortName], sau `runApp`.
class InventoryCatchUp {
  InventoryCatchUp({
    required BgFiles files,
    InventoryCatchUpTarget? Function()? target,
  })  : _files = files,
        _target = target ?? registeredStore;

  final BgFiles _files;
  final InventoryCatchUpTarget? Function() _target;
  Future<void>? _inFlight;
  ReceivePort? _port;

  /// Store do `InventoryListBinding` (qua `AppShellScene._ensureBindings()`)
  /// tạo — chưa có thì `init()` lần đầu sẽ full-sync, giữ cờ cho lần sau.
  static InventoryCatchUpTarget? registeredStore() =>
      Get.isRegistered<InventoryStore>()
          ? InventoryCatchUpTarget.fromStore(Get.find<InventoryStore>())
          : null;

  /// Số lượt tối đa trong 1 lần chạy khi cờ cứ bị ghi mới giữa chừng — hết
  /// lượt thì cờ còn nguyên cho lần resume/ping sau.
  static const int maxPasses = 3;

  /// Single-flight: gọi chồng ⇒ dùng chung 1 lần chạy. Ping đến giữa chừng
  /// KHÔNG bị mất: cờ chỉ bị xoá khi nội dung vẫn y như lúc đọc (so rồi xoá),
  /// nếu nền đã ghi cờ mới thì chạy thêm lượt (review #134 M1, A8).
  Future<void> run() => _inFlight ??= _run().whenComplete(() {
        _inFlight = null;
      });

  Future<void> _run() async {
    for (var pass = 0; pass < maxPasses; pass++) {
      if (!await _pass()) return;
    }
  }

  /// `true` ⇒ cờ đã bị ghi mới trong lúc sync, cần thêm 1 lượt.
  Future<bool> _pass() async {
    try {
      final marker = await _files.readInventoryPendingSync();
      if (marker == null) return false;
      final target = _target();
      if (target == null) return false; // giữ cờ
      // KHÔNG gọi init(): rebindHousehold trả sớm khi cùng household.
      if (!await target.sync()) return false; // giữ cờ cho lần sau
      return !await _files.clearInventoryPendingSyncIf(marker);
    } catch (error) {
      developer.log('Inventory catch-up failed: $error', name: 'inventory');
      return false;
    }
  }

  /// Đăng ký port để isolate nền ping khi app đang sống (best-effort).
  void listen() {
    if (_port != null) return;
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(inventoryCatchUpPortName);
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      inventoryCatchUpPortName,
    );
    port.listen((_) => unawaited(run()));
    _port = port;
  }

  void dispose() {
    final port = _port;
    if (port == null) return;
    IsolateNameServer.removePortNameMapping(inventoryCatchUpPortName);
    port.close();
    _port = null;
  }
}
