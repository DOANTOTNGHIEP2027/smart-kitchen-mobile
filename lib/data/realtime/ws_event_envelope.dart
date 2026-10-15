import 'dart:convert';

/// Envelope chuẩn của mọi event WebSocket từ backend (FE-3 #49).
///
/// Contract nguồn: `docs/design/backend-server/inventory-ws-events.md`
/// §"Tóm tắt hợp đồng WS" — 6 field cố định.
///
/// Delivery guarantee: **at-least-once** (outbox + reconciliation sweep).
/// Client phải dedupe theo [eventId] để đạt exactly-once semantics.
class WsEventEnvelope {
  const WsEventEnvelope({
    required this.eventId,
    required this.eventType,
    required this.householdId,
    required this.occurredAt,
    this.actorId,
    this.data,
  });

  /// UUID của event — dùng để dedupe (at-least-once delivery, xem contract).
  final String eventId;

  /// Loại event: ví dụ `INVENTORY_ITEM_CREATED`, `VOTE_CAST`, `SHOPPING_ITEM_ADDED`, ...
  final String eventType;

  /// UUID của household — bằng đúng household đang subscribe.
  final String householdId;

  /// Thời điểm event xảy ra ở server (ISO 8601, UTC).
  final DateTime occurredAt;

  /// UUID của actor (null với event do scheduler sinh ra, ví dụ alert).
  final String? actorId;

  /// Payload nghiệp vụ thô — type phụ thuộc [eventType], có thể null.
  final Object? data;

  factory WsEventEnvelope.fromJson(Map<String, dynamic> json) {
    return WsEventEnvelope(
      eventId: json['eventId'] as String,
      eventType: json['eventType'] as String,
      householdId: json['householdId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      actorId: json['actorId'] as String?,
      data: json['data'],
    );
  }

  /// Decode từ raw JSON string nhận được từ STOMP frame body.
  static WsEventEnvelope? tryParse(String rawJson) {
    try {
      final map = jsonDecode(rawJson);
      if (map is! Map<String, dynamic>) return null;
      return WsEventEnvelope.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Parse payload **phẳng** của destination `/vote` (thiết kế
  /// `meal-plan-voting-ws-events.md` §"Envelope & Event Schema" — KHÔNG bọc
  /// envelope `{eventId,eventType,data}` như destination `/inventory`).
  ///
  /// Backend gửi JSON dạng `{type, sessionId, timestamp, householdId, slotId, dishId, ...}`.
  /// Ta bọc toàn bộ map vào [data] (và lấy [eventId]/[eventType]/[householdId]/
  /// [occurredAt] từ các field chung) để event đi cùng một pipeline dedupe +
  /// forward như `/inventory`; consumer đọc thẳng `envelope.data['type']`.
  static WsEventEnvelope? tryParseFlat(String rawJson) {
    try {
      final map = jsonDecode(rawJson);
      if (map is! Map<String, dynamic>) return null;
      final type = map['type'];
      final householdId = map['householdId'];
      if (type is! String || householdId is! String) return null;
      final sessionId = map['sessionId']?.toString();
      final timestamp = map['timestamp']?.toString();
      final occurredAt = _tryParseInstant(timestamp) ?? DateTime.now().toUtc();
      return WsEventEnvelope(
        eventId: '$type:$sessionId:$timestamp',
        eventType: type,
        householdId: householdId,
        occurredAt: occurredAt,
        data: map,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _tryParseInstant(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
