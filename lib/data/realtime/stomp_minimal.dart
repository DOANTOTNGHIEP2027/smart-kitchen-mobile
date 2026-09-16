/// Parser/builder STOMP frame tối thiểu cho FE-3 (#49).
///
/// Backend dùng raw WebSocket endpoint `/api/ws` — KHÔNG có SockJS (quyết định
/// D3 trong `redis-cache-ws-baseline.md`). Chỉ cần 3 frame gửi đi (CONNECT,
/// SUBSCRIBE, DISCONNECT) và xử lý 4 frame nhận về (CONNECTED, MESSAGE, ERROR,
/// HEARTBEAT). Frame phải kết thúc bằng null byte `\0` theo đặc tả STOMP 1.2.
///
/// REF: `WebSocketConfig.java` — heartbeat tắt (0,0), không SockJS,
/// broker prefix `/topic`, KHÔNG có `/app` prefix.
library;

/// Gửi: CONNECT với Bearer token trong native header `Authorization`.
///
/// Backend doc (redis-cache-ws-baseline.md §3.2 bước 2):
/// "STOMP CONNECT header: Authorization: Bearer `<access_token>`"
/// Đây là STOMP native header, KHÔNG phải HTTP header.
String buildConnect(String accessToken) {
  return 'CONNECT\naccept-version:1.2\nheart-beat:0,0\nAuthorization:Bearer $accessToken\n\n\x00';
}

/// Gửi: SUBSCRIBE một topic.
String buildSubscribe({required String id, required String destination}) {
  return 'SUBSCRIBE\nid:$id\ndestination:$destination\n\n\x00';
}

/// Gửi: DISCONNECT.
String buildDisconnect() => 'DISCONNECT\n\n\x00';

/// Frame được parse từ raw text nhận từ server.
sealed class StompFrame {}

/// Server đã chấp nhận CONNECT — session đã ready.
class StompConnected extends StompFrame {}

/// Server gửi message tới topic đang subscribe.
class StompMessage extends StompFrame {
  StompMessage({required this.destination, required this.body});
  final String destination;
  final String body;
}

/// Server báo lỗi (ví dụ JWT không hợp lệ, household không khớp).
class StompError extends StompFrame {
  StompError(this.message);
  final String message;
}

/// Frame không nhận diện được — có thể là heartbeat ký tự newline.
class StompUnknown extends StompFrame {}

/// Parse một raw string nhận từ WebSocket channel thành [StompFrame].
///
/// STOMP frame format: COMMAND\n[headers\n]*\nbody\0
/// Heartbeat là ký tự `\n` trần (hoặc `\r\n`) — không có COMMAND.
StompFrame parseFrame(String raw) {
  // Strip null byte cuối
  final text = raw.endsWith('\x00') ? raw.substring(0, raw.length - 1) : raw;

  // Tìm header block (kết thúc bằng \n\n) và body
  final blankLine = text.indexOf('\n\n');
  if (blankLine == -1) {
    // Heartbeat hoặc frame trống
    return StompUnknown();
  }

  final headerBlock = text.substring(0, blankLine);
  final body = text.substring(blankLine + 2);
  final lines = headerBlock.split('\n');
  final command = lines.isEmpty ? '' : lines[0].trim();
  final headers = <String, String>{};
  for (int i = 1; i < lines.length; i++) {
    final colon = lines[i].indexOf(':');
    if (colon == -1) continue;
    final key = lines[i].substring(0, colon).trim();
    final value = lines[i].substring(colon + 1).trim();
    headers[key] = value;
  }

  return switch (command) {
    'CONNECTED' => StompConnected(),
    'MESSAGE' => StompMessage(
        destination: headers['destination'] ?? '',
        body: body,
      ),
    'ERROR' => StompError(headers['message'] ?? body),
    _ => StompUnknown(),
  };
}
