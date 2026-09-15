import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Truy cập chuỗi i18n: `context.l10n.appTitle`.
///
/// Không hardcode text ở bất kỳ widget nào — mọi chuỗi hiển thị phải đi qua
/// đây (CONTEXT_FE.md "Quy tắc bắt buộc khi thực thi FE").
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
