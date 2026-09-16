import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/ws/stomp_frame.dart';

void main() {
  group('StompFrame', () {
    group('encode', () {
      test('CONNECT frame chứa accept-version + Authorization header', () {
        final frame = StompFrame.connect(authorizationHeader: 'Bearer abc');
        final wire = frame.encode();

        expect(wire, startsWith('CONNECT\n'));
        expect(wire, contains('accept-version:1.2\n'));
        expect(wire, contains('Authorization:Bearer abc\n'));
        // Kết thúc bằng NULL byte theo STOMP spec.
        expect(wire.endsWith('\x00'), isTrue);
      });

      test('SUBSCRIBE frame có id + destination', () {
        final frame = StompFrame.subscribe(
          destination: '/topic/household/123/inventory',
          id: '/topic/household/123/inventory',
        );
        final wire = frame.encode();

        expect(wire, startsWith('SUBSCRIBE\n'));
        expect(wire, contains('id:/topic/household/123/inventory\n'));
        expect(wire, contains('destination:/topic/household/123/inventory\n'));
      });

      test('header value có dấu ":" được escape thành \\c', () {
        const frame = StompFrame(
          command: 'MESSAGE',
          headers: <String, String>{'x-test': 'a:b:c'},
        );
        expect(frame.encode(), contains('x-test:a\\cb\\cc'));
      });
    });

    group('decode', () {
      test('CONNECTED frame chuẩn', () {
        const wire = 'CONNECTED\nversion:1.2\nheart-beat:0,0\n\n\x00';
        final frame = StompFrame.decode(wire);

        expect(frame.command, 'CONNECTED');
        expect(frame.headers['version'], '1.2');
        expect(frame.headers['heart-beat'], '0,0');
        expect(frame.body, '');
      });

      test('MESSAGE frame tách đúng destination + body JSON', () {
        const body = '{"eventType":"INVENTORY_CREATED","data":{"id":"x1"}}';
        final wire =
            'MESSAGE\ndestination:/topic/household/1/inventory\n\n$body\x00';
        final frame = StompFrame.decode(wire);

        expect(frame.command, 'MESSAGE');
        expect(frame.headers['destination'], '/topic/household/1/inventory');
        expect(frame.body, body);
      });

      test('ERROR frame với body', () {
        const wire = 'ERROR\nmessage:bad request\n\n{"detail":"oops"}\x00';
        final frame = StompFrame.decode(wire);

        expect(frame.command, 'ERROR');
        expect(frame.headers['message'], 'bad request');
        expect(frame.body, '{"detail":"oops"}');
      });

      test('frame rỗng ném FormatException', () {
        expect(() => StompFrame.decode(''), throwsFormatException);
        expect(() => StompFrame.decode('\n\n\x00'), throwsFormatException);
      });

      test('round-trip encode → decode giữ nguyên command + headers', () {
        const original = StompFrame(
          command: 'MESSAGE',
          headers: <String, String>{
            'destination': '/topic/x',
            'id': 'sub-1',
          },
          body: '{"k":"v"}',
        );
        final decoded = StompFrame.decode(original.encode());

        expect(decoded.command, original.command);
        expect(decoded.headers, original.headers);
        expect(decoded.body, original.body);
      });
    });
  });
}
