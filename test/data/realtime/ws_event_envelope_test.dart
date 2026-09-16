import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/realtime/ws_event_envelope.dart';

/// Unit test cho WsEventEnvelope parsing (không cần device/network).
void main() {
  group('WsEventEnvelope.tryParse', () {
    test('parse JSON hợp lệ đầy đủ field', () {
      const raw = '{'
          '"eventId":"evt-001",'
          '"eventType":"INVENTORY_ITEM_CREATED",'
          '"householdId":"hh-abc",'
          '"occurredAt":"2026-09-16T10:00:00.000Z",'
          '"actorId":"user-123",'
          '"data":{"id":"item-1","name":"Cà chua"}'
          '}';
      final env = WsEventEnvelope.tryParse(raw);
      expect(env, isNotNull);
      expect(env!.eventId, 'evt-001');
      expect(env.eventType, 'INVENTORY_ITEM_CREATED');
      expect(env.householdId, 'hh-abc');
      expect(env.occurredAt.isUtc, isTrue);
      expect(env.actorId, 'user-123');
      expect(env.data, isA<Map>());
    });

    test('parse JSON với actorId null (event từ scheduler)', () {
      const raw = '{'
          '"eventId":"evt-002",'
          '"eventType":"INVENTORY_EXPIRY_ALERT",'
          '"householdId":"hh-abc",'
          '"occurredAt":"2026-09-16T10:00:00.000Z",'
          '"actorId":null,'
          '"data":null'
          '}';
      final env = WsEventEnvelope.tryParse(raw);
      expect(env, isNotNull);
      expect(env!.actorId, isNull);
      expect(env.data, isNull);
    });

    test('trả null khi JSON không hợp lệ', () {
      expect(WsEventEnvelope.tryParse('not json'), isNull);
      expect(WsEventEnvelope.tryParse(''), isNull);
      expect(WsEventEnvelope.tryParse('[]'), isNull);
    });

    test('trả null khi thiếu field bắt buộc', () {
      // Thiếu eventId
      const raw = '{'
          '"eventType":"INVENTORY_ITEM_CREATED",'
          '"householdId":"hh-abc",'
          '"occurredAt":"2026-09-16T10:00:00.000Z"'
          '}';
      expect(WsEventEnvelope.tryParse(raw), isNull);
    });
  });
}
