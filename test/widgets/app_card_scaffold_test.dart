import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/widgets/app_scaffold.dart';
import 'package:smart_kitchen_mobile/widgets/cards/app_card.dart';

import '../helpers/pump_app.dart';

void main() {
  BoxDecoration cardBorderDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(find.descendant(
      of: find.byType(AppCard),
      matching: find.byType(Container),
    ));
    return container.decoration! as BoxDecoration;
  }

  BoxDecoration cardShadowDecoration(WidgetTester tester) => tester
      .widget<DecoratedBox>(find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(DecoratedBox),
          )
          .first)
      .decoration as BoxDecoration;

  group('AppCard', () {
    testWidgets('normal: viền hairline, không bóng', (tester) async {
      await tester.pumpAppWidget(const AppCard(child: Text('A')));
      final border = cardBorderDecoration(tester).border! as Border;
      expect(border.top.color, AppColors.border);
      expect(border.top.width, 1);
      expect(cardShadowDecoration(tester).boxShadow, isNull);
    });

    testWidgets('highlighted: viền primary 1.5dp', (tester) async {
      await tester
          .pumpAppWidget(const AppCard(highlighted: true, child: Text('A')));
      final border = cardBorderDecoration(tester).border! as Border;
      expect(border.top.color, AppColors.primary);
      expect(border.top.width, 1.5);
    });

    testWidgets('elevation > 0: có bóng mềm; dark: bóng trong suốt',
        (tester) async {
      await tester.pumpAppWidget(const AppCard(elevation: 1, child: Text('A')));
      final shadow = cardShadowDecoration(tester).boxShadow!.single;
      expect(shadow.color, AppColors.ambientShadow);
      expect(shadow.blurRadius, 14);

      await tester.pumpAppWidget(
        const AppCard(elevation: 5, child: Text('A')),
        theme: AppTheme.dark,
      );
      await tester.pumpAndSettle(); // chờ AnimatedTheme lerp xong
      final darkShadow = cardShadowDecoration(tester).boxShadow!.single;
      expect(darkShadow.color, AppColors.darkAmbientShadow);
      expect(darkShadow.blurRadius, 28, reason: 'elevation bị kẹp tối đa 2');
    });

    testWidgets('onTap được gọi đúng 1 lần', (tester) async {
      var taps = 0;
      await tester
          .pumpAppWidget(AppCard(onTap: () => taps++, child: const Text('A')));
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('AppScaffold', () {
    Future<void> pushSecond(WidgetTester tester, Widget second) async {
      await tester.pumpAppWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => second)),
            child: const Text('go'),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('title + actions + FAB, mặc định có nút back', (tester) async {
      await pushSecond(
        tester,
        AppScaffold(
          title: 'Kho',
          actions: const <Widget>[Icon(Icons.search)],
          floatingActionButton: FloatingActionButton(
              onPressed: () {}, child: const Icon(Icons.add)),
          body: const Text('body'),
        ),
      );
      expect(find.text('Kho'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('showBackButton: false ẩn nút back', (tester) async {
      await pushSecond(
        tester,
        const AppScaffold(
            title: 'Kho', showBackButton: false, body: Text('body')),
      );
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('không title → không AppBar', (tester) async {
      await tester.pumpAppWidget(const AppScaffold(body: Text('body')),
          wrapInScaffold: false);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('body'), findsOneWidget);
    });
  });
}
