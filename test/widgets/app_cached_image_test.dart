import 'package:cached_network_image/cached_network_image.dart';
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

  // #93 F4 (app-performance-audit §7.2) — decode theo kích thước thật.
  Widget withDpr(double dpr, Widget child) => Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(devicePixelRatio: dpr),
          child: child,
        ),
      );

  CachedNetworkImage findImage(WidgetTester tester) =>
      tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

  testWidgets(
      'T4.1 width=infinity trong ô 200×120, DPR 2 → memCacheWidth 480 '
      '(max(200, 120×2)×2), memCacheHeight null', (WidgetTester tester) async {
    await tester.pumpAppWidget(
      withDpr(
        2,
        const Center(
          child: SizedBox(
            width: 200,
            height: 120,
            child: AppCachedImage(
              url: 'https://example.com/recipe.png',
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );

    final image = findImage(tester);
    expect(image.memCacheWidth, 480);
    expect(image.memCacheHeight, isNull);
  });

  testWidgets(
      'T4.2 caller hữu hạn 48×48, DPR 2 → memCacheWidth 192 (max(48, 48×2)×2)',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(
      withDpr(
        2,
        const Center(
          child: AppCachedImage(
            url: 'https://example.com/avatar.png',
            width: 48,
            height: 48,
            shape: AppCachedImageShape.circle,
          ),
        ),
      ),
    );

    final image = findImage(tester);
    expect(image.memCacheWidth, 192);
    expect(image.memCacheHeight, isNull);
  });

  testWidgets(
      'T4.3 ô không giới hạn chiều rộng → memCacheWidth null; lỗi duy nhất là '
      'lỗi bố cục "infinite width" của caller, không có exception nào khác',
      (WidgetTester tester) async {
    // Ô vô hạn + width infinity là lỗi bố cục CỦA CALLER (RenderBox infinite
    // size) — không thể tránh trong kịch bản này. Không nuốt lỗi: mọi lỗi thu
    // được phải thuộc đúng nhóm lỗi bố cục đó; bất kỳ exception nào khác
    // (vd `Infinity.toInt` khi tính cache size, Guard #5) đều làm test đỏ.
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    await tester.pumpAppWidget(
      const UnconstrainedBox(
        child: AppCachedImage(
          url: 'https://example.com/recipe.png',
          width: double.infinity,
          height: 50,
        ),
      ),
    );
    FlutterError.onError = previous;

    bool isCallerLayoutError(FlutterErrorDetails e) {
      final message = e.exceptionAsString();
      // Lỗi gốc + các assert dây chuyền do render object chưa layout được.
      return message.contains('forces an infinite width') ||
          message.contains('RenderBox was not laid out') ||
          message.contains('_needsLayout');
    }

    expect(errors, isNotEmpty, reason: 'kịch bản phải tái hiện lỗi bố cục');
    expect(
      errors.first.exceptionAsString(),
      contains('forces an infinite width'),
    );
    final unexpected = errors.where((e) => !isCallerLayoutError(e)).toList();
    expect(
      unexpected.map((e) => e.exceptionAsString()),
      isEmpty,
      reason: 'chỉ chấp nhận lỗi bố cục của caller — tính cache size không '
          'được ném (Guard #5)',
    );
    final image = findImage(tester);
    expect(image.memCacheWidth, isNull);
  });

  // HIGH-1 review #93: ảnh ngang (tới 2:1) trong ô vuông/dọc bị BoxFit.cover
  // co theo CHIỀU CAO → cache width phải đủ h×2, không chỉ w.
  testWidgets('T4.4 ô vuông 72×72, DPR 3 → memCacheWidth 432, height null',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(
      withDpr(
        3,
        const Center(
          child: AppCachedImage(
            url: 'https://example.com/recipe.png',
            width: 72,
            height: 72,
          ),
        ),
      ),
    );

    final image = findImage(tester);
    expect(image.memCacheWidth, 432);
    expect(image.memCacheHeight, isNull);
  });

  testWidgets(
      'T4.4b ô dọc 60×120 (width=infinity), DPR 2 → memCacheWidth 480',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(
      withDpr(
        2,
        const Center(
          child: SizedBox(
            width: 60,
            height: 120,
            child: AppCachedImage(
              url: 'https://example.com/recipe.png',
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );

    final image = findImage(tester);
    expect(image.memCacheWidth, 480);
    expect(image.memCacheHeight, isNull);
  });

  testWidgets('T4.4c ô ngang rộng 300×100, DPR 2 → memCacheWidth 600 (w thắng)',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(
      withDpr(
        2,
        const Center(
          child: AppCachedImage(
            url: 'https://example.com/recipe.png',
            width: 300,
            height: 100,
          ),
        ),
      ),
    );

    expect(findImage(tester).memCacheWidth, 600);
  });
}
