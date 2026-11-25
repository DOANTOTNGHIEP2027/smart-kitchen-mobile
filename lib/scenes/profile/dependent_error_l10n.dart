import '../../data/network/api_exception.dart';
import '../../l10n/app_localizations.dart';

/// Copy lỗi cho mọi màn/sheet hồ sơ phụ thuộc (dependent-profile-screens.md
/// §16.5). So khớp theo [ApiException.code]; KHÔNG BAO GIỜ trả
/// `error.message` của BE (Guard 16) — mã lạ rơi về [fallback] hoặc
/// `genericRetryError`.
String dependentErrorMessage(
  AppLocalizations l10n,
  ApiException? error, {
  String? fallback,
}) {
  if (error is AuthExpiredException) return l10n.sessionExpiredError;
  return switch (error?.code) {
    'ERR_NETWORK' => l10n.networkError,
    'ERR_DEP_001' => l10n.dependentNotFoundTitle,
    'ERR_DEP_002' || 'ERR_DEP_003' || 'ERR_DEP_006' =>
      l10n.dependentErrorForbidden,
    'ERR_DEP_004' => l10n.dependentErrorInvalidGuardian,
    'ERR_DEP_005' => l10n.dependentErrorNoHousehold,
    'ERR_ALLERGEN_NOT_FOUND' => l10n.allergenSaveError,
    _ => fallback ?? l10n.genericRetryError,
  };
}
