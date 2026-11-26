import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_list_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';

import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart';

/// #125 §16.14 — DependentListScreen (thay dependent_age_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(() {
    storage.uninstall();
    Get.reset();
  });
  final l = lookupAppLocalizations(const Locale('vi'));

  Future<DepFixture> pumpList(
    WidgetTester tester, {
    String role = 'OWNER',
    List<DependentSummary> items = const <DependentSummary>[],
  }) async {
    final f = await makeDepFixture(role: role, register: true);
    f.api.items = items;
    await pumpDependentScreen(tester, const DependentListScreen());
    return f;
  }

  group('OD-18 — ngày sinh tương lai không hiện tuổi âm', () {
    testWidgets('ngày sinh tương lai → chỉ hiện ngày, không có tuổi âm', (tester) async {
      final future = DateTime.now().add(const Duration(days: 400));
      await pumpList(tester, items: <DependentSummary>[
        dep('d1', name: 'Bé Na', dob: DateTime(future.year, future.month, 1)),
      ]);
      expect(find.text('Bé Na'), findsOneWidget);
      expect(find.textContaining('tuổi'), findsNothing);
      expect(find.textContaining('-1'), findsNothing);
      expect(find.textContaining('Sinh '), findsOneWidget);
    });

    testWidgets('ngày sinh hợp lệ → vẫn hiện "<n> tuổi · Sinh …"', (tester) async {
      await pumpList(tester, items: <DependentSummary>[
        dep('d1', name: 'Bé Na', dob: DateTime(2020, 1, 1)),
      ]);
      expect(find.textContaining('tuổi · Sinh'), findsOneWidget);
    });
  });

  group('Nút "+ Thêm" theo role (KHÔNG render, không chỉ disabled)', () {
    for (final role in <String>['OWNER', 'MEMBER']) {
      testWidgets('$role thấy nút thêm', (tester) async {
        await pumpList(tester, role: role, items: <DependentSummary>[dep('d1')]);
        expect(byKey('dependent-add'), findsOneWidget);
      });
    }

    testWidgets('REMOTE_VIEWER không có nút thêm, row vẫn hiện', (tester) async {
      await pumpList(tester, role: 'REMOTE_VIEWER', items: <DependentSummary>[dep('d1')]);
      expect(byKey('dependent-add'), findsNothing);
      expect(byKey('dependent-row-d1'), findsOneWidget);
    });

    testWidgets('REMOTE_VIEWER + rỗng → không có CTA thêm', (tester) async {
      await pumpList(tester, role: 'REMOTE_VIEWER');
      expect(byKey('dependent-empty'), findsOneWidget);
      expect(byKey('dependent-add'), findsNothing);
    });

    testWidgets('list từ cache → ẩn nút thêm + StaleDataBanner', (tester) async {
      final f = await makeDepFixture(register: true);
      f.api.items = <DependentSummary>[dep('d1')];
      await f.store.loadDependents(); // ghi cache
      f.api.listError = NetworkException();
      await pumpDependentScreen(tester, const DependentListScreen());
      expect(byKey('dependent-row-d1'), findsOneWidget);
      expect(find.text(l.staleDataBanner), findsOneWidget);
      expect(byKey('dependent-add'), findsNothing);
    });
  });

  testWidgets('badge "Cần đổi giám hộ" chỉ trên dòng !guardianActive', (tester) async {
    await pumpList(tester, items: <DependentSummary>[
      dep('d1'),
      dep('d2', name: 'Ông Nội', guardian: 'x', active: false),
    ]);
    expect(byKey('dependent-inactive-tag-d2'), findsOneWidget);
    expect(byKey('dependent-inactive-tag-d1'), findsNothing);
    expect(find.text(l.dependentGuardianInactiveTag), findsOneWidget);
  });

  testWidgets('dị ứng rỗng → chip "Chưa ghi nhận dị ứng", KHÔNG "Không có dị ứng"; >2 dị ứng → "+N"', (tester) async {
    await pumpList(tester, items: <DependentSummary>[
      dep('d1'),
      dep('d2', name: 'Bé Bo', diet: DietType.vegetarian, allergens: const <Allergen>[
        Allergen(id: 1, name: 'Gluten'),
        Allergen(id: 2, name: 'Trứng'),
        Allergen(id: 3, name: 'Cá'),
      ]),
    ]);
    expect(find.text('Chưa ghi nhận dị ứng'), findsOneWidget);
    expect(find.text('Không có dị ứng'), findsNothing);
    expect(find.text(l.dependentMoreChip(1)), findsOneWidget);
    expect(find.text(l.dietTypeVegetarian), findsOneWidget);
    // dietType null → chip mờ "Chưa chọn chế độ ăn".
    expect(find.text(l.healthProfileDietUnset), findsOneWidget);
  });

  testWidgets('lỗi không cache → AppErrorView (không in message BE) + thử lại', (tester) async {
    final f = await makeDepFixture(register: true);
    f.api.listError = BusinessException('ERR_SERVER_X', 'Internal english message');
    await pumpDependentScreen(tester, const DependentListScreen());
    expect(find.text(l.dependentLoadFailed), findsOneWidget);
    expect(find.textContaining('Internal english'), findsNothing);
    f.api.listError = null;
    f.api.items = <DependentSummary>[dep('d1')];
    await tester.tap(find.text(l.commonRetry));
    await tester.pump();
    await tester.pump();
    expect(byKey('dependent-row-d1'), findsOneWidget);
  });

  testWidgets('L6: list rỗng vẫn kéo làm mới được', (tester) async {
    final f = await pumpList(tester);
    expect(byKey('dependent-empty'), findsOneWidget);
    final before = f.api.count('list');
    f.api.items = <DependentSummary>[dep('d1')];
    await tester.fling(byKey('dependent-empty'), const Offset(0, 500), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(f.api.count('list'), before + 1);
    expect(byKey('dependent-row-d1'), findsOneWidget);
  });
}
