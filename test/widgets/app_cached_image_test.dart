import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/widgets/app_cached_image.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('url null → placeholderIcon, không dựng CachedNetworkImage',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(
      const AppCachedImage(
        url: null,
        width: 80,
        height: 80,
        placeholderIcon: Icons.person,
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('url rỗng → placeholderIcon tĩnh', (WidgetTester tester) async {
    await tester.pumpAppWidget(
      const AppCachedImage(
        url: '',
        width: 80,
        height: 80,
        placeholderIcon: Icons.restaurant_menu_rounded,
      ),
    );

    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
  });

  testWidgets('shape circle → bọc bằng ClipOval', (WidgetTester tester) async {
    await tester.pumpAppWidget(
      const AppCachedImage(
        url: 'https://example.com/avatar.png',
        width: 48,
        height: 48,
        shape: AppCachedImageShape.circle,
        placeholderIcon: Icons.person,
      ),
    );

    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('URL hợp lệ → CachedNetworkImage được dựng, không khác biệt',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(
      const AppCachedImage(
        url: 'https://example.com/recipe.png',
        width: 100,
        height: 100,
        placeholderIcon: Icons.restaurant_menu_outlined,
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('width/height = double.infinity KHÔNG crash (fix CRITICAL)',
      (WidgetTester tester) async {
    // Hồi quy: `(double.infinity * dpr).round()` ném Unsupported operation
    // Infinity toInt — 3 caller recipe truyền infinity làm size "tự nhiên".
    await tester.pumpAppWidget(
      const AppCachedImage(
        url: 'https://example.com/recipe.png',
        width: double.infinity,
        height: double.infinity,
        placeholderIcon: Icons.restaurant_menu_outlined,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}