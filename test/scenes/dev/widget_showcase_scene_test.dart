import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/constants/app_icons.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/dev/dev_routes.dart';
import 'package:smart_kitchen_mobile/scenes/dev/widget_showcase_scene.dart';
import 'package:smart_kitchen_mobile/stores/theme_store.dart';
import 'package:smart_kitchen_mobile/widgets/dialogs/confirm_dialog.dart';
import 'package:smart_kitchen_mobile/widgets/loading_overlay.dart';

const List<String> _sections = <String>[
  'colors',
  'typography',
  'buttons',
  'cards',
  'inputs',
  'states',
  'overlay',
  'dialog',
];

void main() {
  late ThemeStore themeStore;

  setUp(() {
    themeStore = ThemeStore();
    // permanent: GetX SmartManagement xoá dependency thường khi route bị huỷ.
    Get.put<ThemeStore>(themeStore, permanent: true);
  });

  tearDown(Get.reset);

  /// Host giống `SmartKitchenApp`: themeMode đọc từ ThemeStore.
  Future<void> pumpShowcase(WidgetTester tester) async {
    await tester.pumpWidget(Observer(
      builder: (_) => GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeStore.themeMode,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: DevRoutes.widgetShowcase,
        getPages: devPages,
      ),
    ));
    await tester.pump();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey<String>('showcase-list')),
            matching: find.byType(Scrollable),
          )
          .first, // Scrollable của ListView; TextField bên trong cũng có Scrollable
    );
    // Kéo hẳn vào giữa khung nhìn để tap không rơi ra mép.
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('render đủ 8 section ở $mode, không exception',
        (tester) async {
      themeStore.setThemeMode(mode);
      await pumpShowcase(tester);
      for (final id in _sections) {
        final section = find.byKey(ValueKey<String>('showcase-$id'));
        await scrollTo(tester, section);
        expect(section, findsOneWidget, reason: id);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('nút đổi theme: light → dark, icon đổi theo', (tester) async {
    await pumpShowcase(tester);
    expect(find.byIcon(AppIcons.darkMode), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey<String>('showcase-toggle-theme')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(themeStore.themeMode, ThemeMode.dark);
    expect(find.byIcon(AppIcons.lightMode), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(WidgetShowcaseScene))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('demo loading 2 giây rồi tự tắt', (tester) async {
    await pumpShowcase(tester);
    final demo = find.byKey(const ValueKey<String>('showcase-demo-loading'));
    await scrollTo(tester, demo);
    await tester.tap(demo);
    await tester.pump();
    expect(
        find.descendant(
            of: demo, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget);
    await tester.pump(WidgetShowcaseScene.demoDelay);
    await tester.pump();
    expect(
        find.descendant(
            of: demo, matching: find.byType(CircularProgressIndicator)),
        findsNothing);
  });

  testWidgets('bật overlay 2 giây', (tester) async {
    await pumpShowcase(tester);
    final button = find.byKey(const ValueKey<String>('showcase-show-overlay'));
    await scrollTo(tester, button);
    await tester.tap(button);
    await tester.pump();
    expect(
        tester.widget<LoadingOverlay>(find.byType(LoadingOverlay)).isLoading,
        isTrue);
    await tester.pump(WidgetShowcaseScene.demoDelay);
    await tester.pump();
    expect(
        tester.widget<LoadingOverlay>(find.byType(LoadingOverlay)).isLoading,
        isFalse);
  });

  /// Showcase có spinner chạy vô hạn → không dùng pumpAndSettle.
  Future<void> settleFrames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('mở dialog → xác nhận → toast hiện kết quả', (tester) async {
    await pumpShowcase(tester);
    final open = find.byKey(const ValueKey<String>('showcase-open-dialog'));
    await scrollTo(tester, open);
    await tester.tap(open);
    await settleFrames(tester);
    expect(find.byType(ConfirmDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-dialog-confirm')));
    await settleFrames(tester);
    expect(find.text('Kết quả: Xác nhận'), findsOneWidget);
  });

  testWidgets('mở dialog destructive → huỷ → kết quả false', (tester) async {
    await pumpShowcase(tester);
    final open = find
        .byKey(const ValueKey<String>('showcase-open-destructive-dialog'));
    await scrollTo(tester, open);
    await tester.tap(open);
    await settleFrames(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-dialog-cancel')));
    await settleFrames(tester);
    expect(find.text('Kết quả: Huỷ'), findsOneWidget);
  });

  testWidgets('màn 320dp không overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpShowcase(tester);
    for (final id in _sections) {
      await scrollTo(tester, find.byKey(ValueKey<String>('showcase-$id')));
    }
    expect(tester.takeException(), isNull);
  });
}
