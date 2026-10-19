import '../data/network/api_exception.dart';
import '../l10n/app_localizations.dart';

/// Câu báo lỗi hiển thị cho người dùng từ [ApiException].
///
/// `ERR_NETWORK`, `ERR_UNKNOWN` (lỗi không đến từ BE: mất mạng, parse hỏng…)
/// và `ERR_INTERNAL` (5xx/không envelope — interceptor tự điền 'Server error')
/// mang message kỹ thuật tiếng Anh — thay bằng copy l10n. [AuthExpiredException]
/// (mọi 401) → câu hết phiên. Mã nghiệp vụ khác giữ message BE trả về.
String apiErrorMessage(AppLocalizations l10n, ApiException? error,
    {String? fallback}) {
  if (error == null) return fallback ?? l10n.genericRetryError;
  // 401 sau khi refresh thất bại (ERR_AUTH_001/ERR_AUTH_UNAUTHORIZED/không
  // envelope): ở màn đã đăng nhập luôn là hết phiên. Màn auth dùng
  // `errorCopyKey` riêng, không đi qua helper này.
  if (error is AuthExpiredException) return l10n.sessionExpiredError;
  return switch (error.code) {
    'ERR_NETWORK' => l10n.networkError,
    'ERR_UNKNOWN' || 'ERR_INTERNAL' => fallback ?? l10n.genericRetryError,
    _ => error.message,
  };
}
