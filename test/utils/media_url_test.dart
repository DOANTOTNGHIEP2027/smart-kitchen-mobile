import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/utils/media_url.dart';

void main() {
  const base = 'http://192.168.1.20:8080';

  test('ảnh BE upload từ emulator/localhost → đổi sang host của máy đang xem', () {
    expect(normalizeMediaUrl('http://10.0.2.2:8080/api/files/a.jpg', baseUrl: base),
        'http://192.168.1.20:8080/api/files/a.jpg');
    expect(normalizeMediaUrl('http://localhost:8080/api/files/a.jpg', baseUrl: base),
        'http://192.168.1.20:8080/api/files/a.jpg');
  });

  test('base không có port / https → dùng đúng scheme + host của base', () {
    expect(normalizeMediaUrl('http://10.0.2.2:8080/api/files/a.jpg', baseUrl: 'https://api.bep.vn'),
        'https://api.bep.vn/api/files/a.jpg');
  });

  test('đường dẫn tương đối → ghép base', () {
    expect(normalizeMediaUrl('/api/files/a.jpg', baseUrl: base), 'http://192.168.1.20:8080/api/files/a.jpg');
  });

  test('URL ngoài (Google avatar, ảnh công thức CDN) giữ nguyên', () {
    const google = 'https://lh3.googleusercontent.com/a/abc=s96-c';
    expect(normalizeMediaUrl(google, baseUrl: base), google);
    const cdn = 'https://cdn.example.com/recipes/pho.jpg';
    expect(normalizeMediaUrl(cdn, baseUrl: base), cdn);
  });

  test('giữ query string của ảnh BE', () {
    expect(normalizeMediaUrl('http://localhost:8080/api/files/a.jpg?v=2', baseUrl: base),
        'http://192.168.1.20:8080/api/files/a.jpg?v=2');
  });
}
