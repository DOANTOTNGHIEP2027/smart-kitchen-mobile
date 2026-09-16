import 'package:smart_kitchen_mobile/services/connectivity_service.dart';

/// [ConnectivityService] fake cho test — tránh gọi `connectivity_plus` platform
/// channel (không chạy được ngoài Flutter test binding).
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool online = true}) : _online = online;

  bool _online;

  void set(bool online) => _online = online;

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<void> get onConnectivityRestored => const Stream<void>.empty();

  @override
  bool get isListening => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
