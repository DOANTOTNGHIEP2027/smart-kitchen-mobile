import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_en.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/shell/home_greeting.dart';

void main() {
  test('lời chào đổi đúng tại ranh giới các buổi, cả hai ngôn ngữ', () {
    for (final l10n in [AppLocalizationsVi(), AppLocalizationsEn()]) {
      for (final (hour, expected) in [
        (0, l10n.homeGreetingNight),
        (4, l10n.homeGreetingNight),
        (5, l10n.homeGreeting),
        (11, l10n.homeGreeting),
        (12, l10n.homeGreetingAfternoon),
        (17, l10n.homeGreetingAfternoon),
        (18, l10n.homeGreetingEvening),
        (21, l10n.homeGreetingEvening),
        (22, l10n.homeGreetingNight),
        (23, l10n.homeGreetingNight),
      ]) {
        expect(
            homeGreetingForTime(l10n, DateTime(2026, 11, 28, hour)), expected,
            reason: '${l10n.localeName}, $hour');
      }
    }
  });
}
