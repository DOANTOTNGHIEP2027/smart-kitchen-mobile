import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/constants/app_colors_extension.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';

import 'legacy_light_theme.dart';

void main() {
  group('AppTheme', () {
    test('light giữ đúng toàn bộ ThemeData trước issue #17 (hồi quy)', () {
      final current = AppTheme.light
          .copyWith(extensions: const <ThemeExtension<dynamic>>[]);
      expect(current, legacyLightTheme());
    });

    test('light và dark có primary thương hiệu + đúng brightness', () {
      expect(AppTheme.light.colorScheme.primary, AppColors.primary);
      expect(AppTheme.dark.colorScheme.primary, AppColors.primary);
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
    });

    test('dark dùng palette tối', () {
      final dark = AppTheme.dark;
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(dark.colorScheme.surface, AppColors.darkSurface);
      expect(dark.colorScheme.onSurface, AppColors.darkTextPrimary);
      expect(dark.colorScheme.error, AppColors.darkError);
      expect(dark.textTheme.titleLarge?.color, AppColors.darkTextPrimary);
      expect(dark.textTheme.bodyMedium?.color, AppColors.darkTextSecondary);
      expect(dark.inputDecorationTheme.fillColor, AppColors.darkSurfaceSubtle);
    });

    test('gắn AppColorsExtension đúng bản light/dark', () {
      expect(AppTheme.light.extension<AppColorsExtension>(),
          AppColorsExtension.light);
      expect(AppTheme.dark.extension<AppColorsExtension>(),
          AppColorsExtension.dark);
    });
  });

  group('AppColorsExtension', () {
    test('copyWith chỉ đổi field được truyền', () {
      final copy = AppColorsExtension.light.copyWith(border: Colors.red);
      expect(copy.border, Colors.red);
      expect(copy.success, AppColors.success);
      expect(copy.scrim, AppColors.scrim);
      final same = AppColorsExtension.light.copyWith();
      expect(same.textSecondary, AppColors.textSecondary);
    });

    test('lerp ở hai đầu trả đúng palette, other khác kiểu trả this', () {
      const l = AppColorsExtension.light;
      const d = AppColorsExtension.dark;
      expect(l.lerp(d, 0).border, l.border);
      expect(l.lerp(d, 1).border, d.border);
      expect(l.lerp(d, 1).scrim, d.scrim);
      expect(l.lerp(null, 0.5), same(l));
    });

    testWidgets('context.appColors rơi về light khi theme thiếu extension',
        (tester) async {
      late AppColorsExtension resolved;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(),
        home: Builder(builder: (context) {
          resolved = context.appColors;
          return const SizedBox.shrink();
        }),
      ));
      expect(resolved, AppColorsExtension.light);
    });
  });
}
