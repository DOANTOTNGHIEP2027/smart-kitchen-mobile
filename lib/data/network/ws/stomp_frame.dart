/// STOMP frame tối thiểu (FE-4 §7).
///
/// Chỉ hỗ trợ 5 loại frame cần dùng: `CONNECT`, `CONNECTED`, `SUBSCRIBE`,
/// `MESSAGE`, `ERROR`. Không implement `DISCONNECT`/`ACK`/transaction vì
/// use-case chỉ subscribe read-only (Decision D7 — không dùng package STOMP
/// đầy đủ, tự viết frame layer tối thiểu).
///
/// Format text (RFC-ish, theo STOMP 1.2 spec rút gọn):
/// ```
/// COMMAND\n
/// key1:value1\n
/// key2:value2\n
/// \n
/// body\u0000
/// ```
class StompFrame {
  const StompFrame({
    required this.command,
    this.headers = const <String, String>{},
    this.body = '',
  });

  /// Một trong: `CONNECT`, `CONNECTED`, `SUBSCRIBE`, `MESSAGE`, `ERROR`.
  final String command;

  /// Map thứ tự giữ nguyên không quan trọng — caller đọc theo key.
  final Map<String, String> headers;

  /// JSON string thô (chưa parse) cho MESSAGE/ERROR; rỗng nếu frame không body.
  final String body;

  /// Frame CONNECT — client mở phiên STOMP sau khi WS đã connected.
  ///
  /// Header `Authorization` mang access token (theo inventory-core.md
  /// §"Transport & Handshake"). `accept-version: 1.2` bắt buộc theo spec.
  /// `host` theo STOMP 1.2 §"CONNECT" (virtual host) — truyền authority của
  /// WS endpoint. Mặc định `localhost` chỉ phù hợp dev local.
  factory StompFrame.connect({
    required String authorizationHeader,
    String host = 'localhost',
  }) =>
      StompFrame(
        command: 'CONNECT',
        headers: <String, String>{
          'accept-version': '1.2',
          'host': host,
          'Authorization': authorizationHeader,
        },
      );

  /// Frame SUBSCRIBE — đăng ký nhận MESSAGE ở destination.
  /// `id` dùng để unsub sau này (chưa cần), mặc định trùng destination cho đơn giản.
  factory StompFrame.subscribe({required String destination, required String id}) =>
      StompFrame(
        command: 'SUBSCRIBE',
        headers: <String, String>{
          'id': id,
          'destination': destination,
        },
      );

  /// Encode thành chuỗi wire-format (kết thúc bằng `NULL` = `\x00`).
  String encode() {
    final buffer = StringBuffer()
      ..write(command)
      ..write('\n');
    headers.forEach((String key, String value) {
      buffer
        ..write(key)
        ..write(':')
        ..write(_escape(value))
        ..write('\n');
    });
    buffer
      ..write('\n')
      ..write(body)
      ..write('\x00');
    return buffer.toString();
  }

  /// Decode một frame text nhận được qua WS thành [StompFrame].
  ///
  /// Bỏ qua định dạng sai một cách khoan dung: thiếu command → ném
  /// [FormatException] (caller bắt và log, không crash transport).
  static StompFrame decode(String raw) {
    // Tách phần trước NULL làm frame; phần sau NULL (nếu có) bỏ qua.
    final nullIndex = raw.indexOf('\x00');
    final frameText = nullIndex >= 0 ? raw.substring(0, nullIndex) : raw;

    // Cắt theo `\n`. Dòng đầu = command, các dòng tiếp theo = headers
    // tới khi gặp dòng trống, phần còn lại = body.
    final lines = frameText.split('\n');
    if (lines.isEmpty || lines.first.isEmpty) {
      throw FormatException('STOMP frame rỗng hoặc thiếu command: $raw');
    }
    final command = lines.first.trim();

    final headers = <String, String>{};
    var i = 1;
    while (i < lines.length && lines[i].isNotEmpty) {
      final line = lines[i];
      final colon = line.indexOf(':');
      if (colon > 0) {
        final key = line.substring(0, colon);
        final value = _unescape(line.substring(colon + 1));
        headers[key] = value;
      }
      i++;
    }
    // Bỏ qua dòng trống phân tách, phần còn lại là body.
    final bodyStart = i + 1;
    final body = bodyStart < lines.length
        ? lines.sublist(bodyStart).join('\n')
        : '';

    return StompFrame(
      command: command,
      headers: headers,
      body: body,
    );
  }

  /// Escape ký tự đặc biệt trong header value (STOMP 1.2): `:` → `\c`, `\n` → `\n`.
  /// Body không escape — chỉ áp dụng cho header value.
  static String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll(':', r'\c').replaceAll('\n', r'\n');

  static String _unescape(String value) =>
      value.replaceAll(r'\n', '\n').replaceAll(r'\c', ':').replaceAll(r'\\', r'\');
}
