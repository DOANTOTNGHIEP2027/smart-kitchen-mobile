// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Kitchen';

  @override
  String get commonRetry => 'Retry';

  @override
  String get stateEmptyDefault => 'Nothing here yet';

  @override
  String get stateErrorDefault => 'Something went wrong';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get navHome => 'Home';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navPlanning => 'Planning';

  @override
  String get navShopping => 'Shopping';

  @override
  String get navProfile => 'Profile';

  @override
  String get devLoginTitle => 'Sign in';

  @override
  String get devLoginSubtitle =>
      'The real sign-in flow (Google / OTP / QR join) ships with fe-onboarding.';

  @override
  String get devLoginCta => 'Continue as demo user';

  @override
  String get devLoginBanner => 'App shell demo — no backend call is made';
}
