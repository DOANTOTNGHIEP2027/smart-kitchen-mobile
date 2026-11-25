import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/realtime/realtime_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// TokenStorage có sẵn access token — `_connect()` bỏ qua nếu thiếu token.
class _TokenStorageWithAccess extends TokenStorage {
  @override
  String? get accessToken => 'tok';
}

class _FakeSink implements WebSocketSink {
  _FakeSink({this.hangClose = false});

  /// LOW-1 (review v3): `close()` của `web_socket_channel` thật chỉ xong SAU
  /// khi kết nối mở thành công — channel chưa mở thì future treo mãi. Bật cờ
  /// này để fake trả future KHÔNG BAO GIỜ xong, buộc service không được await.
  final bool hangClose;
  bool closed = false;
  final List<Object?> added = <Object?>[];

  @override
  void add(dynamic data) => added.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    closed = true;
    if (hangClose) return Completer<void>().future;
    return Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.ready, {bool hangClose = false})
      : sink = _FakeSink(hangClose: hangClose);

  @override
  final Future<void> ready;

  @override
  final _FakeSink sink;

  final StreamController<dynamic> _incoming = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// #93 §5.4 bất biến 6 (single-flight) + §5.5 F2 (timeout `ready`, guard
/// `identical` sau await).
void main() {
  late List<_FakeChannel> channels;
  late Completer<void> ready;
  RealtimeService? service;

  RealtimeService build({
    Duration readyTimeout = kWsReadyTimeout,
    bool hangClose = false,
  }) {
    final s = RealtimeService(
      tokenStorage: _TokenStorageWithAccess(),
      wsBaseUrl: 'ws://test/api',
      channelFactory: (uri) {
        final c = _FakeChannel(ready.future, hangClose: hangClose);
        channels.add(c);
        return c;
      },
      readyTimeout: readyTimeout,
    );
    service = s;
    return s;
  }

  bool isFrame(Object? f, String command) =>
      f is String && f.startsWith('$command\n');

  setUp(() {
    channels = <_FakeChannel>[];
    ready = Completer<void>();
  });

  // Giới hạn thời gian dispose: nếu service còn await `close()` của channel
  // chưa mở thì tearDown fail nhanh thay vì treo tới timeout 30s của test.
  const noHang = Duration(seconds: 2);

  tearDown(() async {
    await service?.dispose().timeout(noHang);
    service = null;
  });

  test('T1.3 hai connect(h1) liên tiếp khi ready chưa xong → factory gọi 1 lần',
      () async {
    final s = build();
    final first = s.connect('h1');
    final second = s.connect('h1');
    await Future<void>.delayed(Duration.zero);

    expect(channels, hasLength(1));

    ready.complete();
    await Future.wait<void>(<Future<void>>[first, second]);
    expect(channels, hasLength(1));
    expect(channels.single.sink.added.where((f) => isFrame(f, 'CONNECT')),
        hasLength(1));
  });

  test(
      'T2.1 ready treo quá readyTimeout → đóng sink, không connected, '
      'chưa reconnect ngay', () async {
    final s = build(readyTimeout: const Duration(milliseconds: 20));
    unawaited(s.connect('h1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(channels, hasLength(1), reason: 'timer reconnect ≥ 2s chưa chạy');
    expect(channels.single.sink.closed, isTrue, reason: 'socket mồ côi');
    expect(s.currentState, isNot(WsConnectionState.connected));
    expect(channels.single.sink.added, isEmpty);
  });

  test('T2.2 kWsReadyTimeout = 10s (bằng connectTimeout của DioClient)', () {
    expect(kWsReadyTimeout, const Duration(seconds: 10));
  });

  test(
      'T2.3 disconnect() khi ready đang chờ → ready xong muộn: không lỗi zone, '
      'đóng sink, vẫn disconnected, không gửi CONNECT/SUBSCRIBE', () async {
    final errors = <Object>[];
    final done = Completer<void>();
    late RealtimeService s;

    runZonedGuarded(() async {
      s = build();
      final pending = s.connect('h1');
      await Future<void>.delayed(Duration.zero);
      await s.disconnect();
      ready.complete();
      await pending;
      await Future<void>.delayed(Duration.zero);
      done.complete();
    }, (e, _) {
      errors.add(e);
      if (!done.isCompleted) done.complete();
    });
    await done.future;

    expect(errors, isEmpty);
    expect(channels, hasLength(1));
    expect(channels.single.sink.closed, isTrue);
    expect(s.currentState, WsConnectionState.disconnected);
    final frames = channels.single.sink.added;
    expect(frames.where((f) => isFrame(f, 'CONNECT')), isEmpty);
    expect(frames.where((f) => isFrame(f, 'SUBSCRIBE')), isEmpty);
  });

  test(
      'HIGH-1 connect(h1) → disconnect() → connect(h1) khi ready đang chờ → '
      'mở channel mới, gửi đúng 1 CONNECT trên channel mới, channel cũ đã đóng',
      () async {
    final s = build();
    final first = s.connect('h1');
    await Future<void>.delayed(Duration.zero);
    await s.disconnect(); // logout trong lúc handshake
    final second = s.connect('h1'); // login lại cùng Nhà
    await Future<void>.delayed(Duration.zero);

    ready.complete();
    await Future.wait<void>(<Future<void>>[first, second]).timeout(noHang);

    expect(channels, hasLength(2), reason: 'không được dùng lại lần đã huỷ');
    expect(channels.first.sink.closed, isTrue);
    expect(channels.first.sink.added.where((f) => isFrame(f, 'CONNECT')),
        isEmpty);
    expect(channels.last.sink.added.where((f) => isFrame(f, 'CONNECT')),
        hasLength(1));
    expect(s.currentState, WsConnectionState.connecting,
        reason: 'đang chờ CONNECTED từ server, không kẹt ở disconnected');
  });

  test(
      'MEDIUM-1 disconnect()/dispose() khi channel chưa mở và close() treo → '
      'vẫn xong, state disconnected', () async {
    final s = build(hangClose: true);
    unawaited(s.connect('h1'));
    await Future<void>.delayed(Duration.zero);

    await s.disconnect().timeout(noHang);
    expect(s.currentState, WsConnectionState.disconnected);
    expect(channels.single.sink.closed, isTrue, reason: 'vẫn yêu cầu đóng');

    await s.dispose().timeout(noHang);
    service = null;
  });

  test(
      'MEDIUM-1 ready xong trong lúc close() đang treo → guard identical giữ: '
      'không gửi CONNECT/SUBSCRIBE lên channel đang đóng', () async {
    final s = build(hangClose: true);
    final pending = s.connect('h1');
    await Future<void>.delayed(Duration.zero);

    final disconnecting = s.disconnect(); // không await: close() treo
    ready.complete();
    await pending.timeout(noHang);
    await Future<void>.delayed(Duration.zero);

    final frames = channels.single.sink.added;
    expect(frames.where((f) => isFrame(f, 'CONNECT')), isEmpty);
    expect(frames.where((f) => isFrame(f, 'SUBSCRIBE')), isEmpty);
    await disconnecting.timeout(noHang);
    expect(s.currentState, WsConnectionState.disconnected);
  });

  test(
      'MEDIUM-1 connect(h2) khi h1 đang chờ và close() treo → mở channel h2 '
      'ngay, CONNECT chỉ trên channel h2', () async {
    final s = build(hangClose: true);
    final first = s.connect('h1');
    await Future<void>.delayed(Duration.zero);
    final second = s.connect('h2');
    await Future<void>.delayed(Duration.zero);

    expect(channels, hasLength(2), reason: 'F2 không kẹt ở _closeChannel');
    ready.complete();
    await Future.wait<void>(<Future<void>>[first, second]).timeout(noHang);

    expect(channels.first.sink.closed, isTrue);
    expect(channels.first.sink.added.where((f) => isFrame(f, 'CONNECT')),
        isEmpty);
    expect(channels.last.sink.added.where((f) => isFrame(f, 'CONNECT')),
        hasLength(1));
  });
}
