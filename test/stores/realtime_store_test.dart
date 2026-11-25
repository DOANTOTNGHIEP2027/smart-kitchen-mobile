import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/realtime/realtime_service.dart';
import 'package:smart_kitchen_mobile/data/realtime/ws_event_envelope.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/stores/realtime_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../helpers/secure_storage_channel.dart';
import '../scenes/inventory/fake_connectivity_service.dart';

/// Transport giả: ghi lại connect/disconnect, tự phát state/event.
class _FakeRealtimeService extends RealtimeService {
  _FakeRealtimeService()
      : super(
            tokenStorage: TokenStorage(),
            wsBaseUrl: 'ws://test',
            enabled: false);

  final List<String> connects = <String>[];
  int disconnects = 0;
  bool disposed = false;
  final StreamController<WsConnectionState> stateCtrl =
      StreamController<WsConnectionState>.broadcast();
  final StreamController<WsEventEnvelope> eventCtrl =
      StreamController<WsEventEnvelope>.broadcast();

  @override
  Stream<WsConnectionState> get connectionState => stateCtrl.stream;

  @override
  Stream<WsEventEnvelope> get events => eventCtrl.stream;

  @override
  Future<void> connect(String householdId) async => connects.add(householdId);

  @override
  Future<void> disconnect() async => disconnects++;

  @override
  Future<void> dispose() async {
    disposed = true;
    await stateCtrl.close();
    await eventCtrl.close();
  }
}

/// #93 §10.3 — RealtimeStore chưa có test. Phủ hành vi hiện tại + T1.1/T1.2
/// của §5.4 (init sau runApp, idempotent).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(storage.uninstall);

  late _FakeRealtimeService service;
  late FakeConnectivityService connectivity;
  late SessionStore session;
  late RealtimeStore store;

  setUp(() {
    service = _FakeRealtimeService();
    connectivity = FakeConnectivityService(online: false);
    session = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
    );
    store = RealtimeStore(
      realtimeService: service,
      connectivityService: connectivity,
      sessionStore: session,
    );
  });

  tearDown(() => store.dispose());

  void authenticate(String? householdId) {
    session.status = AuthStatus.authenticated;
    if (householdId != null) {
      session.applyHouseholdContext(householdId: householdId, role: 'OWNER');
    }
  }

  WsEventEnvelope event(String id) => WsEventEnvelope(
        eventId: id,
        eventType: 'INVENTORY_ITEM_CREATED',
        householdId: 'h1',
        occurredAt: DateTime.parse('2026-11-25T00:00:00Z'),
        actorId: null,
        data: const <String, dynamic>{},
      );

  test('T1.1 listen events TRƯỚC init → vẫn nhận đúng 1 event sau init',
      () async {
    final received = <WsEventEnvelope>[];
    final sub = store.events.listen(received.add);
    addTearDown(sub.cancel);

    await store.init();
    service.eventCtrl.add(event('e1'));
    await Future<void>.delayed(Duration.zero);

    expect(received.map((e) => e.eventId), <String>['e1']);
    expect(store.lastEvent?.eventId, 'e1');
  });

  test('T1.2 init() 2 lần + đổi household 1 lần → chỉ 1 lần connect',
      () async {
    session.status = AuthStatus.authenticated;
    final first = store.init();
    final second = store.init();
    expect(identical(first, second), isTrue, reason: 'single-flight');
    await first;
    await store.init();
    expect(service.connects, isEmpty, reason: 'chưa có Nhà');

    session.applyHouseholdContext(householdId: 'h1', role: 'OWNER');
    await Future<void>.delayed(Duration.zero);
    expect(service.connects, <String>['h1'], reason: 'reaction không nhân đôi');
  });

  test('init khi đã đăng nhập + có Nhà → connect đúng household 1 lần',
      () async {
    authenticate('h1');
    await store.init();
    expect(service.connects, <String>['h1']);
  });

  test('init khi chưa đăng nhập → không connect; đăng nhập sau → connect',
      () async {
    await store.init();
    expect(service.connects, isEmpty);

    authenticate('h1');
    await Future<void>.delayed(Duration.zero);
    expect(service.connects, contains('h1'));
  });

  test('đăng xuất → disconnect', () async {
    authenticate('h1');
    await store.init();

    session.status = AuthStatus.unauthenticated;
    await Future<void>.delayed(Duration.zero);
    expect(service.disconnects, greaterThanOrEqualTo(1));
  });

  test('connectionState của service được phản ánh vào store', () async {
    await store.init();
    expect(store.connectionState, WsConnectionState.disconnected);

    service.stateCtrl.add(WsConnectionState.connected);
    await Future<void>.delayed(Duration.zero);
    expect(store.connectionState, WsConnectionState.connected);
  });

  test('mạng khôi phục: chưa connected → connect lại; đã connected → bỏ qua',
      () async {
    authenticate('h1');
    await store.init();
    service.connects.clear();

    connectivity.set(true);
    await Future<void>.delayed(Duration.zero);
    expect(service.connects, <String>['h1']);

    service.stateCtrl.add(WsConnectionState.connected);
    await Future<void>.delayed(Duration.zero);
    connectivity.set(false);
    connectivity.set(true);
    await Future<void>.delayed(Duration.zero);
    expect(service.connects, <String>['h1'], reason: 'đã connected');
  });

  test('mạng khôi phục khi chưa có Nhà → không connect', () async {
    await store.init();
    connectivity.set(true);
    await Future<void>.delayed(Duration.zero);
    expect(service.connects, isEmpty);
  });

  test('dispose → dừng reaction auth và dispose service', () async {
    await store.init();
    await store.dispose();
    expect(service.disposed, isTrue);

    authenticate('h1');
    await Future<void>.delayed(Duration.zero);
    expect(service.connects, isEmpty, reason: 'reaction đã huỷ');
  });
}
