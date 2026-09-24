import 'package:smart_kitchen_mobile/services/connectivity_service.dart';

/// [ConnectivityService] fake cho test — tránh gọi `connectivity_plus` platform
/// channel (không chạy được ngoài Flutter test binding).
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool online = true}) : _online = online;

  bool _online;
  final StreamController<void> _restored = StreamController<void>.broadcast();

  void set(bool online) {
    final wasOffline = !_online;
    _online = online;
    if (wasOffline && online) _restored.add(null);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<void> get onConnectivityRestored => _restored.stream;

  @override
  bool get isListening => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() => _restored.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
import 'dart:async';
