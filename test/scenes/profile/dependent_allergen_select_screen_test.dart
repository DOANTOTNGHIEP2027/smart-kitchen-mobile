import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_allergen_select_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';

import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart';

/// #125 §16.14 — DependentAllergenSelectScreen (S-A0..S-A4).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(() {
    storage.uninstall();
    Get.reset();
  });
  final l = lookupAppLocalizations(const Locale('vi'));

  Future<DepFixture> pumpAllergens(
    WidgetTester tester, {
    String role = 'OWNER',
    DependentSummary? d,
  }) async {
    final f = await makeDepFixture(role: role, register: true);
    f.api.items = <DependentSummary>[d ?? dep('d1')];
    f.api.health['d1'] = depHealth('d1',
        allergens: const <Allergen>[Allergen(id: 1, name: 'Gluten')]);
    await pumpDependentScreen(
        tester, const DependentAllergenSelectScreen(dependentId: 'd1'),
        pages: <GetPage<dynamic>>[
          GetPage<dynamic>(
              name: AppRoutes.dependents,
              page: () => const Scaffold(body: Text('list-page'))),
        ]);
    await tester.pump();
    return f;
  }

  bool? checked(WidgetTester tester, int id) =>
      tester.widget<CheckboxListTile>(byKey('allergen-$id')).value;

  testWidgets('S-A0: không quyền → Blocked, KHÔNG gọi health/catalog', (tester) async {
    final f = await pumpAllergens(tester, role: 'MEMBER', d: dep('d1', guardian: 'a'));
    expect(byKey('dependent-allergens-blocked'), findsOneWidget);
    expect(find.text(l.dependentNoAccessAllergens), findsOneWidget);
    expect(f.api.count('health:'), 0);
    expect(f.healthApi.catalogReads, 0);
  });

  testWidgets('cold deep-link: seed tick từ health của server', (tester) async {
    final f = await pumpAllergens(tester);
    expect(f.api.calls.first, 'get:d1');
    expect(checked(tester, 1), isTrue);
    expect(checked(tester, 2), isFalse);
    expect(find.text(l.dependentAllergensTitle('Bé Bo')), findsOneWidget);
  });

  testWidgets('S-A3: ERR_ALLERGEN_NOT_FOUND → nạp lại catalog + GIỮ tick', (tester) async {
    final f = await pumpAllergens(tester);
    await tester.tap(byKey('allergen-2'));
    await tester.pump();
    f.api.allergensError = BusinessException('ERR_ALLERGEN_NOT_FOUND', 'unknown');
    final before = f.healthApi.catalogReads;
    await tester.tap(byKey('allergens-save'));
    await tester.pumpAndSettle();
    expect(f.api.allergenWrites.single, <int>[1, 2]);
    expect(f.healthApi.catalogReads, before + 1);
    expect(find.text(l.allergenSaveError), findsOneWidget);
    expect(checked(tester, 1), isTrue);
    expect(checked(tester, 2), isTrue);
  });

  testWidgets('S-A4: lưu thành công → full-replace id đã sort + toast', (tester) async {
    final f = await pumpAllergens(tester);
    await tester.tap(byKey('allergen-3'));
    await tester.tap(byKey('allergen-1')); // bỏ tick
    await tester.pump();
    await tester.tap(byKey('allergens-save'));
    await tester.pumpAndSettle();
    expect(f.api.allergenWrites.single, <int>[3]);
    expect(find.text(l.allergensSavedToast), findsOneWidget);
  });

  testWidgets('L7: lưu → 404 ERR_DEP_001 → về danh sách + toast', (tester) async {
    final f = await pumpAllergens(tester);
    f.api.allergensError = BusinessException('ERR_DEP_001', 'gone');
    await tester.tap(byKey('allergens-save'));
    await tester.pumpAndSettle();
    expect(find.text('list-page'), findsOneWidget);
    expect(find.text(l.dependentNotFoundTitle), findsOneWidget);
  });
}
