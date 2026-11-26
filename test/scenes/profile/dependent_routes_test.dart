import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_allergen_select_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_detail_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_health_profile_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_list_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/profile_family_bindings.dart';
import 'package:smart_kitchen_mobile/scenes/profile/profile_family_routes.dart';

/// #125 §16.8/§16.14 — route `/dependents/**` top-level + `backToDependentList`.
void main() {
  tearDown(Get.reset);

  GetPage<dynamic> pageOf(String name) =>
      profileFamilyPages.where((p) => p.name == name).single;

  group('Khai báo route', () {
    test('4 route dependent đúng màn + `/dependents/add` không còn', () {
      expect(profileFamilyPages.where((p) => p.name == '/dependents/add'), isEmpty);
      expect(pageOf(AppRoutes.dependents).page(), isA<DependentListScreen>());
      expect(pageOf(AppRoutes.dependentDetail).page(), isA<DependentDetailScreen>());
      expect(pageOf(AppRoutes.dependentHealth).page(), isA<DependentHealthProfileScreen>());
      expect(pageOf(AppRoutes.dependentAllergens).page(),
          isA<DependentAllergenSelectScreen>());
      expect(AppRoutes.dependentDetail, '/dependents/:dependentId');
      expect(AppRoutes.dependentHealth, '/dependents/:dependentId/health');
    });

    test('route dependent + /family mang FamilyBinding + DependentBinding (deep-link an toàn)', () {
      for (final name in <String>[
        AppRoutes.family,
        AppRoutes.dependents,
        AppRoutes.dependentDetail,
        AppRoutes.dependentHealth,
        AppRoutes.dependentAllergens,
      ]) {
        final bindings = pageOf(name).bindings;
        expect(bindings.whereType<FamilyBinding>(), hasLength(1), reason: name);
        expect(bindings.whereType<DependentBinding>(), hasLength(1), reason: name);
      }
    });
  });

  Future<void> pumpApp(WidgetTester tester, {String initial = '/'}) async {
    Widget text(String t) => Scaffold(body: Text(t));
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: initial,
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/', page: () => text('home')),
        GetPage<dynamic>(
            name: AppRoutes.memberDetail,
            page: () => text('member-${Get.parameters['userId']}')),
        GetPage<dynamic>(name: AppRoutes.dependents, page: () => text('list-page')),
        GetPage<dynamic>(
            name: AppRoutes.dependentDetail,
            page: () => text('detail-${Get.parameters['dependentId']}')),
        GetPage<dynamic>(
            name: AppRoutes.dependentHealth,
            page: () => text('health-${Get.parameters['dependentId']}')),
      ],
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('/dependents/abc/health → màn health, dependentId == abc', (tester) async {
    await pumpApp(tester);
    Get.toNamed<void>('/dependents/abc/health');
    await tester.pumpAndSettle();
    expect(find.text('health-abc'), findsOneWidget);
  });

  testWidgets('/dependents không bị /family/:userId bắt nhầm', (tester) async {
    await pumpApp(tester);
    Get.toNamed<void>(AppRoutes.dependents);
    await tester.pumpAndSettle();
    expect(find.text('list-page'), findsOneWidget);
    expect(find.textContaining('member-'), findsNothing);
  });

  testWidgets('MEDIUM-3 (a): stack có /dependents → pop về đúng nó', (tester) async {
    await pumpApp(tester);
    Get.toNamed<void>(AppRoutes.dependents);
    await tester.pumpAndSettle();
    Get.toNamed<void>('/dependents/x');
    await tester.pumpAndSettle();
    Get.toNamed<void>('/dependents/x/health');
    await tester.pumpAndSettle();
    backToDependentList();
    await tester.pumpAndSettle();
    expect(find.text('list-page'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.dependents);
    // pop tiếp về home — list không bị nhân đôi.
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('MEDIUM-3 (b): cold deep-link /dependents/x/health → kết thúc ở /dependents, không màn đen', (tester) async {
    await pumpApp(tester, initial: '/dependents/x/health');
    expect(find.text('health-x'), findsOneWidget);
    backToDependentList();
    await tester.pumpAndSettle();
    expect(find.text('list-page'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.dependents);
  });
}
