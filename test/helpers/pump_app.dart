import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';

/// Bọc widget đang test bằng đúng theme + delegate i18n của app, để widget
/// dùng `context.l10n` chạy được trong test.
extension PumpApp on WidgetTester {
  Future<void> pumpAppWidget(Widget child, {bool wrapInScaffold = true}) =>
      pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: wrapInScaffold ? Scaffold(body: child) : child,
        ),
      );
}
