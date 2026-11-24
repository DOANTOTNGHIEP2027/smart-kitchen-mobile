import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/auth/domain/auth_validators.dart';
import 'package:smart_kitchen_mobile/scenes/auth/widgets/auth_frame.dart';
import 'package:smart_kitchen_mobile/utils/l10n_x.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AuthValidators', () {
    test('email', () {
      expect(AuthValidators.email('a@b.co'), isNull);
      expect(AuthValidators.email('  a@b.co  '), isNull);
      for (final bad in <String?>[null, '', 'a', 'a@b', 'a b@c.d', '@b.co']) {
        expect(AuthValidators.email(bad), 'auth_email_invalid', reason: '$bad');
      }
    });

    test('password tối thiểu 8 ký tự', () {
      expect(AuthValidators.password('12345678'), isNull);
      expect(AuthValidators.password('1234567'), 'auth_password_short');
      expect(AuthValidators.password(null), 'auth_password_short');
    });

    test('fullName bắt buộc / tuỳ chọn, tối đa 100', () {
      expect(AuthValidators.fullName('An'), isNull);
      expect(AuthValidators.fullName('   '), 'auth_name_required');
      expect(AuthValidators.fullName('', required: false), isNull);
      expect(AuthValidators.fullName('a' * 100), isNull);
      expect(AuthValidators.fullName('a' * 101), 'auth_name_too_long');
      expect(AuthValidators.fullName('a' * 101, required: false),
          'auth_name_too_long');
    });

    test('householdName 1–255', () {
      expect(AuthValidators.householdName('Nhà An'), isNull);
      expect(AuthValidators.householdName(' '), 'household_name_required');
      expect(AuthValidators.householdName('a' * 256), 'household_name_too_long');
    });
  });

  /// Chống tái phát lỗi #28: key lỗi lên UI dạng thô (`auth_bad_credentials`).
  /// Quét mọi key mà store/scene onboarding gán vào `fieldErrors`, mọi key
  /// validator và mọi key của `errorCopyKey` — tất cả phải có bản dịch.
  testWidgets('mọi key lỗi onboarding đều có bản dịch', (tester) async {
    final keys = <String>{};
    final pattern = RegExp(r"""=\s*'([a-z_]+)'|=>\s*'([a-z_]+)'|\?\s*'([a-z_]+)'""");
    for (final dir in <String>['lib/scenes/auth', 'lib/scenes/household']) {
      for (final file in Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        for (final line in source.split('\n')) {
          if (!line.contains('fieldErrors[') &&
              !line.contains('=>') &&
              !line.contains('?')) {
            continue;
          }
          for (final m in pattern.allMatches(line)) {
            final key = m.group(1) ?? m.group(2) ?? m.group(3);
            if (key != null && key.contains('_')) keys.add(key);
          }
        }
      }
    }
    for (final code in <String>[
      'ERR_NETWORK', 'ERR_AUTH_FIREBASE_UNAVAILABLE', 'ERR_AUTH_GOOGLE_EMAIL_REQUIRED',
      'ERR_AUTH_001', 'ERR_AUTH_GOOGLE_TOKEN_MISSING', 'ERR_AUTH_RATE_LIMIT',
      'ERR_AUTH_OTP_INVALID', 'ERR_AUTH_OTP_LIMIT', 'ERR_HH_002', 'ERR_HH_003',
      'CLIENT_ALREADY_IN_HOUSEHOLD', 'ERR_HH_005', 'ERR_AUTH_INVITE_INVALID',
      'ERR_HOUSEHOLD_FULL', 'ERR_UNKNOWN',
    ]) {
      keys.add(errorCopyKey(code));
    }
    keys.addAll(<String>['auth_bad_credentials', 'auth_email_exists', 'join_rate_limited', 'invite_qr_invalid']);
    // Bỏ các literal không phải key l10n (route, field name, mã định danh).
    keys.removeWhere((k) => const <String>{'profile_tab'}.contains(k));

    late BuildContext ctx;
    await tester.pumpAppWidget(Builder(builder: (c) {
      ctx = c;
      return const SizedBox.shrink();
    }));
    final missing = keys.where((k) => k.localized(ctx) == k).toList()..sort();
    expect(keys.length, greaterThan(20), reason: 'quét không ra key nào');
    expect(missing, isEmpty, reason: 'Key chưa có bản dịch: $missing');
  });
}
