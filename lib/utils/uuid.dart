import 'dart:math';

/// UUID v4 ngẫu nhiên — `X-Idempotency-Key` (scan kho, scan hoá đơn, cất đồ vào
/// kho #239) và `clientTurnId` của trợ lý bếp (#204). `uuid` chỉ là dependency
/// bắc cầu, không khai trong pubspec, nên tự viết.
String createUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String pair(int value) => value.toRadixString(16).padLeft(2, '0');
  final hex = bytes.map(pair).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
