import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/app/realtime_startup.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/realtime/realtime_service.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/stores/realtime_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../helpers/secure_storage_channel.dart';
import '../scenes/inventory/fake_connectivity_service.dart';

class _TokenStorageWithAccess extends TokenStorage {
  @override
  String? get accessToken => 'tok';
}

class _FakeSink implements WebSocketSink {
  bool closed = false;

  @override
  void add(dynamic data) {}

  /// Giống `web_socket_channel` thật: channel chưa mở thì `close()` không bao
  /// giờ xong (LOW-1 review v3) — service không được await nó.
  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    closed = true;
    return Completer<void>().future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Channel có `ready` KHÔNG BAO GIỜ xong — mô phỏng WS treo handshake.
class _HangingChannel implements WebSocketChannel {
  @override
  final Future<void> ready = Completer<void>().future;

  @override
  final _FakeSink sink = _FakeSink();

  @override
  Stream<dynamic> get stream => const Stream<dynamic>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Service mà `connect` ném lỗi — để `RealtimeStore.init()` thất bại.
class _ThrowingService extends RealtimeService {
  _ThrowingService()
      : super(
            tokenStorage: TokenStorage(), wsBaseUrl: 'ws://t', enabled: false);

  @override
  Future<void> connect(String householdId) async => throw StateError('ws hỏng');
}

class _LogEntry {
  _LogEntry(this.message, this.name, this.error);
  final String message;
  final String name;
  final Object? error;
}

/// #93 §5.4 F1 — realtime init sau frame đầu (T1.4 + chứng minh WS treo
/// không chặn first frame).
void main() {
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(storage.uninstall);

  SessionStore authenticatedSession() {
    final session = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
    );
    session.status = AuthStatus.authenticated;
    session.applyHouseholdContext(householdId: 'h1', role: 'OWNER');
    return session;
  }

  const firstFrame = Directionality(
    textDirection: TextDirection.ltr,
    child: Text('first frame'),
  );

  testWidgets(
      'WS ready treo mãi → frame đầu vẫn render; init chỉ chạy SAU frame đầu',
      (tester) async {
    final channels = <_HangingChannel>[];
    final service = RealtimeService(
      tokenStorage: _TokenStorageWithAccess(),
      wsBaseUrl: 'ws://test/api',
      channelFactory: (_) {
        final c = _HangingChannel();
        channels.add(c);
        return c;
      },
    );
    final store = RealtimeStore(
      realtimeService: service,
      connectivityService: FakeConnectivityService(online: true),
      sessionStore: authenticatedSession(),
    );

    startRealtimeAfterFirstFrame(store);
    expect(channels, isEmpty, reason: 'chưa có frame → chưa init');

    await tester.pumpWidget(firstFrame);
    expect(find.text('first frame'), findsOneWidget);
    expect(channels, hasLength(1), reason: 'init chạy sau frame đầu');
    expect(service.currentState, WsConnectionState.connecting);

    // Frame tiếp theo vẫn chạy dù `ready` chưa bao giờ xong.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('first frame'), findsOneWidget);

    // Dọn bằng store.dispose() thật, chạy trong `tester.runAsync`. Lý do cần
    // runAsync (LOW-2): `testWidgets` chạy body trong FakeAsync; `cancel()` của
    // subscription trên broadcast stream trả `_nullFuture` thuộc root zone nên
    // KHÔNG BAO GIỜ xong trong FakeAsync (artifact của môi trường test, không
    // phải lỗi production). runAsync chạy bằng event loop thật nên future đó
    // xong. Phần "treo thật" ở production — await `sink.close()` của channel
    // chưa mở — đã bị loại ở `_closeChannel` (MEDIUM-1); fake `close()` ở trên
    // treo vĩnh viễn để chứng minh: nếu service còn await nó, timeout bên dưới
    // sẽ ném lỗi.
    await tester.runAsync(
      () => store.dispose().timeout(const Duration(seconds: 2)),
    );
    expect(service.currentState, WsConnectionState.disconnected);
    // Cho timer timeout `ready` (10s) chạy hết: guard `identical` → không lỗi.
    await tester.pump(const Duration(seconds: 11));
    expect(channels.single.sink.closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('T1.4 init() ném lỗi → log name bootstrap, không lỗi chưa xử lý',
      (tester) async {
    final logs = <_LogEntry>[];
    final store = RealtimeStore(
      realtimeService: _ThrowingService(),
      connectivityService: FakeConnectivityService(online: true),
      sessionStore: authenticatedSession(),
    );

    startRealtimeAfterFirstFrame(
      store,
      log: (message, {name = '', error, stackTrace}) =>
          logs.add(_LogEntry(message, name, error)),
    );
    await tester.pumpWidget(firstFrame);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(logs, hasLength(1));
    expect(logs.single.name, 'bootstrap');
    expect(logs.single.error, isA<StateError>());
    expect(find.text('first frame'), findsOneWidget);
  });
}
