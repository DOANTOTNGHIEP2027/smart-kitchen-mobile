import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/realtime/stomp_minimal.dart';

/// Unit test cho STOMP frame parser/builder (không cần device/network).
void main() {
  group('stomp_minimal — buildConnect', () {
    test('tạo frame CONNECT đúng format với Authorization header', () {
      final frame = buildConnect('test_token_123');
      expect(frame, startsWith('CONNECT\n'));
      expect(frame, contains('Authorization:Bearer test_token_123'));
      expect(frame, contains('heart-beat:0,0'));
      expect(frame, contains('accept-version:1.2'));
      expect(frame, endsWith('\x00'));
    });
  });

  group('stomp_minimal — buildSubscribe', () {
    test('tạo frame SUBSCRIBE đúng format', () {
      final frame = buildSubscribe(
        id: 'sub-0',
        destination: '/topic/household/abc/inventory',
      );
      expect(frame, startsWith('SUBSCRIBE\n'));
      expect(frame, contains('id:sub-0'));
      expect(frame, contains('destination:/topic/household/abc/inventory'));
      expect(frame, endsWith('\x00'));
    });
  });

  group('stomp_minimal — parseFrame', () {
    test('parse CONNECTED frame', () {
      final raw = 'CONNECTED\nversion:1.2\n\n\x00';
      final frame = parseFrame(raw);
      expect(frame, isA<StompConnected>());
    });

    test('parse MESSAGE frame với body', () {
      const body = '{"eventId":"123","eventType":"INVENTORY_ITEM_CREATED"}';
      final raw = 'MESSAGE\ndestination:/topic/household/xyz/inventory\n'
          'content-type:application/json\n\n$body\x00';
      final frame = parseFrame(raw);
      expect(frame, isA<StompMessage>());
      final msg = frame as StompMessage;
      expect(msg.destination, '/topic/household/xyz/inventory');
      expect(msg.body, body);
    });

    test('parse ERROR frame', () {
      final raw = 'ERROR\nmessage:ERR_WS_UNAUTHORIZED\n\n\x00';
      final frame = parseFrame(raw);
      expect(frame, isA<StompError>());
      expect((frame as StompError).message, 'ERR_WS_UNAUTHORIZED');
    });

    test('parse heartbeat (newline trần) thành StompUnknown', () {
      final frame = parseFrame('\n');
      expect(frame, isA<StompUnknown>());
    });

    test('parse frame không rõ command thành StompUnknown', () {
      final frame = parseFrame('UNKNOWN\n\n\x00');
      expect(frame, isA<StompUnknown>());
    });

    test('frame không có null byte vẫn parse được', () {
      // Server đôi khi gửi không có null terminator
      final raw = 'CONNECTED\nversion:1.2\n\n';
      final frame = parseFrame(raw);
      expect(frame, isA<StompConnected>());
    });
  });
}
