import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/household/domain/invite_code.dart';

/// `parseInviteCode` — fe-onboarding.md §12b (D10).
void main() {
  const base = 'https://app.smartkitchen.vn';

  group('parseInviteCode', () {
    test('mã trơn: viết hoa, bỏ khoảng trắng / gạch ngang', () {
      expect(parseInviteCode('abc12345', baseUrl: base), 'ABC12345');
      expect(parseInviteCode('  ABC-1234 5 ', baseUrl: base), 'ABC12345');
    });

    test('link mời của app (kể cả / cuối, query, fragment, host hoa)', () {
      expect(parseInviteCode('$base/join/ABC12345', baseUrl: base), 'ABC12345');
      expect(parseInviteCode('$base/join/abc12345/', baseUrl: base), 'ABC12345');
      expect(parseInviteCode('$base/join/ABC12345?utm=qr#x', baseUrl: base),
          'ABC12345');
      expect(parseInviteCode('https://APP.SmartKitchen.vn/join/ABC12345',
          baseUrl: base), 'ABC12345');
    });

    test('scheme riêng smartkitchen://app/join/<CODE>', () {
      expect(parseInviteCode('smartkitchen://app/join/ABC12345', baseUrl: base),
          'ABC12345');
    });

    test('nguồn lạ → null (không gọi API)', () {
      for (final raw in <String>[
        '',
        '   ',
        'https://evil.example.com/join/ABC12345',
        'http://app.smartkitchen.vn/join/ABC12345', // khác scheme của base
        '$base/invite/ABC12345',
        '$base/join',
        '$base/join/ABC12345/extra',
        'smartkitchen://join/ABC12345', // thiếu host `app`
        'otherapp://app/join/ABC12345',
        'WIFI:S:home;T:WPA;P:secret;;',
      ]) {
        expect(parseInviteCode(raw, baseUrl: base), isNull, reason: raw);
      }
    });

    test('mã sai độ dài / ký tự → null', () {
      for (final raw in <String>[
        'ABC1234',
        'ABC123456',
        'ABC_2345',
        'ÁBC12345',
        '$base/join/ABC1234',
        '$base/join/ABC!2345',
      ]) {
        expect(parseInviteCode(raw, baseUrl: base), isNull, reason: raw);
      }
    });

    test('base URL theo môi trường (staging)', () {
      const staging = 'https://staging.smartkitchen.vn/';
      expect(parseInviteCode('https://staging.smartkitchen.vn/join/ABC12345',
          baseUrl: staging), 'ABC12345');
      expect(parseInviteCode('$base/join/ABC12345', baseUrl: staging), isNull);
    });
  });

  group('inviteLink', () {
    test('ghép base + /join/<code>, bỏ / thừa', () {
      expect(inviteLink('ABC12345', baseUrl: base), '$base/join/ABC12345');
      expect(inviteLink('ABC12345', baseUrl: '$base/'), '$base/join/ABC12345');
    });

    test('link sinh ra parse ngược lại đúng mã', () {
      expect(parseInviteCode(inviteLink('ABC12345', baseUrl: base), baseUrl: base),
          'ABC12345');
    });
  });
}
