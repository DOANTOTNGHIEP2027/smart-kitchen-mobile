import '../../data/network/api_exception.dart';
import '../../l10n/app_localizations.dart';

/// Copy lỗi cho mutation/đọc của Gia đình (profile-family-screens.md §12).
///
/// So khớp theo [ApiException.code], KHÔNG theo `toString()`. Không bao giờ
/// trả `error.message` của BE (câu tiếng Anh kỹ thuật) — mã lạ rơi về
/// `genericRetryError`.
String familyErrorMessage(AppLocalizations l10n, ApiException? error) {
  if (error is AuthExpiredException) return l10n.sessionExpiredError;
  return switch (error?.code) {
    'ERR_NETWORK' => l10n.networkError,
    'ERR_HH_004' => l10n.familyErrorNotOwner,
    'ERR_HH_006' => l10n.familyErrorInviteLimit,
    'ERR_HH_007' => l10n.familyErrorCannotRemove,
    'ERR_HEALTH_FORBIDDEN' => l10n.memberHealthForbidden,
    _ => l10n.genericRetryError,
  };
}
