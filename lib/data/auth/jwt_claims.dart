import 'dart:convert';

/// Decode read-only, **không verify**, phần payload của một JWT
/// (fe-app-shell.md §8.1, quyết định D8).
///
/// Không phải một ranh giới bảo mật. Chỉ dùng cho quyết định routing/UX phía
/// client — BE tự kiểm tra chữ ký trên mọi request mới là ranh giới phân quyền
/// thật sự. Trả về `{}` cho token dị dạng thay vì throw, để token hỏng suy
/// biến thành "không có claim" thay vì crash.
///
/// Claim giữ `snake_case` (`household_id`) theo
/// `docs/contracts/naming-convention.md` §4 — claim JWT nằm ngoài phạm vi quy
/// ước camelCase của JSON body.
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return const {};
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return const {};
    return decoded;
  } catch (_) {
    return const {};
  }
}
