import 'dart:convert';

Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return const {};

  try {
    final normalized = base64Url.normalize(parts[1]);
    final json = utf8.decode(base64Url.decode(normalized));
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> ? decoded : const {};
  } on FormatException {
    return const {};
  }
}
