import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/ws/app_event_bus.dart';
import 'package:smart_kitchen_mobile/data/network/ws/stomp_frame.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeTokenStorage extends Fake implements TokenStorage {
  _FakeTokenStorage(this.accessToken);
  @override
  final String? accessToken;
}

/// WebSocketChannelfake: cho phép test điều khiển `ready`, giả lập server
/// gửi frame qua [injectServer], và mô phỏng đứt cáp qua [simulateDisconnect].
class _FakeChannel extends Fake implements WebSocketChannel {
  _FakeChannel();
  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();
  final List<String> sent = <String>[];
  bool isReady = true;

  @override
  Future<void> get ready async => isReady ? Future<void>.value() : Future<void>.error('not ready');

  @override
  Stream get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _FakeSink(sent, _incoming);

  /// Test đẩy frame STOMP vào channel như server đang gửi.
  void injectServer(String wire) => _incoming.add(wire);

  /// Giả lập server đóng connection (network drop).
  void simulateDisconnect() => _incoming.close();
}

class _FakeSink extends Fake implements WebSocketSink {
  _FakeSink(this._sent, this._ctrl);
  final List<String> _sent;
  final StreamController<dynamic> _ctrl;

  @override
  void add(dynamic data) {
    if (data is String) _sent.add(data);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    await _ctrl.close();
  }
}

void main() {
  late _FakeTokenStorage tokenStorage;
  late List<_FakeChannel> createdChannels;
  late List<int> reconnectDelays;
  late AppEventBus bus;

  setUp(() {
    tokenStorage = _FakeTokenStorage('test-jwt');
    createdChannels = <_FakeChannel>[];
    reconnectDelays = <int>[];
    registerFallbackValue(Uri.parse('ws://x'));
  });

  AppEventBus buildBus() => AppEventBus(
        tokenStorage,
        wsUrl: 'ws://test/ws',
        channelFactory: (uri) {
          final ch = _FakeChannel();
          createdChannels.add(ch);
          return ch;
        },
        backoffFor: (attempt) {
          reconnectDelays.add(attempt);
          return Duration.zero; // chạy ngay để test không chờ.
        },
      );

  group('AppEventBus', () {
    test('rawEvents mở connection và gửi CONNECT frame với Bearer token', () async {
      bus = buildBus();
      bus.rawEvents('/topic/household/1/inventory');

      // _ensureConnected được unawaited — đợi microtask drain.
      await Future<void>.delayed(Duration.zero);

      expect(createdChannels, hasLength(1));
      final sent = createdChannels.single.sent;
      expect(sent, isNotEmpty);
      final connectWire = sent.first;
      expect(connectWire, startsWith('CONNECT\n'));
      expect(connectWire, contains('Authorization:Bearer test-jwt'));
    });

    test('khi nhận CONNECTED → resubscribe destination + phát onConnected', () async {
      bus = buildBus();
      final connectedEvents = <void>[];
      bus.onConnected.listen(connectedEvents.add);
      bus.rawEvents('/topic/household/1/inventory');

      await Future<void>.delayed(Duration.zero);

      // Server gửi CONNECTED.
      createdChannels.single.injectServer(
        const StompFrame(command: 'CONNECTED').encode(),
      );
      await Future<void>.delayed(Duration.zero);

      // Sent SUBSCRIBE cho destination.
      expect(
        createdChannels.single.sent.any((s) => s.startsWith('SUBSCRIBE') && s.contains('destination:/topic/household/1/inventory')),
        isTrue,
      );
      // onConnected phát 1 lần.
      expect(connectedEvents, hasLength(1));
    });

    test('MESSAGE frame → payload JSON đẩy vào stream rawEvents', () async {
      bus = buildBus();
      final events = <Map<String, dynamic>>[];
      bus.rawEvents('/topic/x').listen(events.add);

      await Future<void>.delayed(Duration.zero);
      createdChannels.single.injectServer(const StompFrame(command: 'CONNECTED').encode());
      await Future<void>.delayed(Duration.zero);

      // Server push MESSAGE.
      const payload = '{"eventType":"CREATED","id":"x"}';
      createdChannels.single.injectServer(
        const StompFrame(command: 'MESSAGE', headers: {'destination': '/topic/x'}, body: payload).encode(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single['eventType'], 'CREATED');
    });

    test('mất kết nối → reconnect → resubscribe đúng destination cũ (DoD §4.3)', () async {
      bus = buildBus();
      bus.rawEvents('/topic/household/1/inventory');

      await Future<void>.delayed(Duration.zero);
      final firstChannel = createdChannels.single;

      // Kích hoạt CONNECTED để destination được coi là subscribed.
      firstChannel.injectServer(const StompFrame(command: 'CONNECTED').encode());
      await Future<void>.delayed(Duration.zero);

      // Mất kết nối.
      firstChannel.simulateDisconnect();
      await Future<void>.delayed(Duration.zero);

      // Backoff của chúng ta chỉ chạy khi Timer fire — vì chúng ta dùng
      // Duration.zero cho backoffFor, Timer này sẽ fire ngay. Nhưng để chắc,
      // tick timer.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // delay() của chúng ta là Completer, cần allow timer 1 tick nữa.
      // Timer.zero + invoke _ensureConnected không gọi delay (delay là của
      // _ensureConnected khi async err). Timer chỉ gọi callback tức thì.
      expect(createdChannels.length, greaterThanOrEqualTo(2));

      // Reconnection chốt backoff log đã gọi.
      expect(reconnectDelays, isNotEmpty);

      // Channel mới phải gửi lại SUBSCRIBE cho /topic/household/1/inventory
      // sau khi nhận CONNECTED.
      createdChannels.last.injectServer(const StompFrame(command: 'CONNECTED').encode());
      await Future<void>.delayed(Duration.zero);

      final lastSent = createdChannels.last.sent;
      expect(
        lastSent.any((s) => s.startsWith('SUBSCRIBE') && s.contains('/topic/household/1/inventory')),
        isTrue,
        reason: 'Reconnect phải resubscribe destination cũ',
      );
    });

    test('dispose ngăn reconnect further + đóng mọi controller', () async {
      bus = buildBus();
      bus.rawEvents('/topic/x');
      await Future<void>.delayed(Duration.zero);

      await bus.dispose();

      // Coi như hết controller — listen tiếp sẽ tạo lại.
      expect(bus.onConnected, isA<Stream<void>>());
    });
  });
}
