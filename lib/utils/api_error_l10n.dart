import '../data/network/api_exception.dart';
import '../l10n/app_localizations.dart';

/// Câu báo lỗi hiển thị cho người dùng từ [ApiException].
///
/// `ERR_NETWORK`, `ERR_UNKNOWN` (lỗi không đến từ BE: mất mạng, parse hỏng…)
/// và `ERR_INTERNAL` (5xx/không envelope — interceptor tự điền 'Server error')
/// mang message kỹ thuật tiếng Anh — thay bằng copy l10n. Mã nghiệp vụ khác giữ
/// message BE trả về.
String apiErrorMessage(AppLocalizations l10n, ApiException? error,
    {String? fallback}) {
  if (error == null) return fallback ?? l10n.genericRetryError;
  return switch (error.code) {
    'ERR_NETWORK' => l10n.networkError,
    'ERR_UNKNOWN' || 'ERR_INTERNAL' => fallback ?? l10n.genericRetryError,
    _ => error.message,
  };
}
