import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/dev/dev_routes.dart';
import 'package:smart_kitchen_mobile/scenes/dev/widget_showcase_scene.dart';
import 'package:smart_kitchen_mobile/stores/theme_store.dart';

/// Issue #17 — integration test: điều hướng tới màn showcase → mọi section
/// hiện ra, đổi theme không crash (design-system.md §10).
///
/// Chạy trên thiết bị/emulator:
/// `flutter test integration_test/widget_showcase_test.dart -d <device>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const sections = <String>[
    'colors',
    'typography',
    'buttons',
    'cards',
    'inputs',
    'states',
    'overlay',
    'dialog',
  ];

  testWidgets('mở /dev/widgets → đủ 8 section, toggle dark không crash',
      (tester) async {
    final themeStore = ThemeStore();
    Get.put<ThemeStore>(themeStore, permanent: true);
    addTearDown(Get.reset);

    await tester.pumpWidget(Observer(
      builder: (_) => GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeStore.themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey<String>('open-showcase'),
                onPressed: () => Get.toNamed(DevRoutes.widgetShowcase),
                child: const Text('showcase'),
              ),
            ),
          ),
        ),
        getPages: devPages,
      ),
    ));
    await tester.tap(find.byKey(const ValueKey<String>('open-showcase')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(WidgetShowcaseScene), findsOneWidget);

    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey<String>('showcase-list')),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> visitAll() async {
      for (final id in sections) {
        final section = find.byKey(ValueKey<String>('showcase-$id'));
        await tester.scrollUntilVisible(section, 300, scrollable: scrollable);
        expect(section, findsOneWidget, reason: id);
      }
    }

    await visitAll();

    await tester.tap(find.byKey(const ValueKey<String>('showcase-toggle-theme')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(themeStore.themeMode, ThemeMode.dark);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('showcase-colors')), -300,
        scrollable: scrollable);
    await visitAll();
    expect(tester.takeException(), isNull);
  });
}
