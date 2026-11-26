import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/widgets/app_bottom_nav.dart';

import '../helpers/pump_app.dart';

/// #134 — badge trên tab của [AppBottomNav] (shopping-list-screen §9.7(a)).
void main() {
  const badgeKey = ValueKey<String>('app-bottom-nav-badge');

  Widget nav(int count, {String? semantics}) => AppBottomNav(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: <AppBottomNavDestination>[
          const AppBottomNavDestination(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Nhà',
          ),
          AppBottomNavDestination(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart_rounded,
            label: 'Đi chợ',
            badgeCount: count,
            semanticsLabel: semantics,
          ),
        ],
      );

  testWidgets('badgeCount = 2 → hiện "2"', (tester) async {
    await tester.pumpAppWidget(nav(2));
    expect(find.byKey(badgeKey), findsOneWidget);
    expect(find.descendant(of: find.byKey(badgeKey), matching: find.text('2')),
        findsOneWidget);
  });

  testWidgets('badgeCount = 0 → KHÔNG có widget badge (không vẽ "0")',
      (tester) async {
    await tester.pumpAppWidget(nav(0));
    expect(find.byKey(badgeKey), findsNothing);
    expect(find.byType(Badge), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('badgeCount = 120 → "99+"', (tester) async {
    await tester.pumpAppWidget(nav(120));
    expect(
        find.descendant(of: find.byKey(badgeKey), matching: find.text('99+')),
        findsOneWidget);
    expect(find.text('120'), findsNothing);
  });

  testWidgets('có badge → đọc nhãn gộp; tap vẫn hoạt động', (tester) async {
    final handle = tester.ensureSemantics();
    var tapped = -1;
    await tester.pumpAppWidget(AppBottomNav(
      selectedIndex: 0,
      onDestinationSelected: (i) => tapped = i,
      destinations: const <AppBottomNavDestination>[
        AppBottomNavDestination(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Nhà',
        ),
        AppBottomNavDestination(
          icon: Icons.shopping_cart_outlined,
          activeIcon: Icons.shopping_cart_rounded,
          label: 'Đi chợ',
          badgeCount: 2,
          semanticsLabel: 'Đi chợ, 2 món được giao cho bạn',
        ),
      ],
    ));
    expect(find.bySemanticsLabel('Đi chợ, 2 món được giao cho bạn'),
        findsOneWidget);
    await tester.tap(find.byKey(badgeKey));
    expect(tapped, 1);
    handle.dispose();
  });

  testWidgets('không badge → không dùng nhãn gộp', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppWidget(nav(0, semantics: 'Đi chợ, 0 món'));
    expect(find.bySemanticsLabel('Đi chợ, 0 món'), findsNothing);
    handle.dispose();
  });
}
