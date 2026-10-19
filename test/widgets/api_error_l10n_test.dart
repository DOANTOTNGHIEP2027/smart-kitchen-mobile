import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/utils/api_error_l10n.dart';

void main() {
  final l10n = AppLocalizationsVi();

  test('ERR_NETWORK / ERR_UNKNOWN → copy l10n, không lộ message tiếng Anh nội bộ', () {
    expect(apiErrorMessage(l10n, NetworkException()), l10n.networkError);
    expect(apiErrorMessage(l10n, ServerException('ERR_UNKNOWN', 'Unexpected response')), l10n.genericRetryError);
    expect(apiErrorMessage(l10n, ServerException('ERR_UNKNOWN', 'x'), fallback: 'F'), 'F');
    expect(apiErrorMessage(l10n, ServerException('ERR_INTERNAL', 'Server error')), l10n.genericRetryError);
    expect(apiErrorMessage(l10n, null), l10n.genericRetryError);
  });

  test('mã nghiệp vụ khác → giữ message BE', () {
    expect(apiErrorMessage(l10n, BusinessException('ERR_HH_004', 'Chỉ chủ hộ')), 'Chỉ chủ hộ');
  });
}
