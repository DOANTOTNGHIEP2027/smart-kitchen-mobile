import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/change_guardian_sheet.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart';
import 'family_test_fakes.dart' as ff;

/// #125 §16.14 — ChangeGuardianSheet (OWNER only).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(() {
    storage.uninstall();
    Get.reset();
  });
  final l = lookupAppLocalizations(const Locale('vi'));

  Future<DepFixture> pumpSheet(
    WidgetTester tester,
    DependentSummary d, {
    List<HouseholdMember>? members,
  }) async {
    final f = await makeDepFixture(members: members, register: true);
    f.api.items = <DependentSummary>[d];
    await pumpDependentScreen(
        tester, Scaffold(body: ChangeGuardianSheet(store: f.store, dependent: d)));
    return f;
  }

  AppButton confirm(WidgetTester tester) =>
      tester.widget<AppButton>(byKey('change-guardian-confirm'));

  testWidgets('lọc candidate: loại REMOTE_VIEWER + guardian đang active', (tester) async {
    await pumpSheet(tester, dep('d1', guardian: 'a'), members: <HouseholdMember>[
      ff.member('me', 'OWNER'),
      ff.member('a', 'MEMBER'),
      ff.member('b', 'MEMBER'),
      ff.member('v', 'REMOTE_VIEWER'),
    ]);
    expect(byKey('change-guardian-me'), findsOneWidget);
    expect(byKey('change-guardian-b'), findsOneWidget);
    expect(byKey('change-guardian-a'), findsNothing);
    expect(byKey('change-guardian-v'), findsNothing);
    expect(find.text(l.dependentChangeGuardianTitle('Bé Bo')), findsOneWidget);
    expect(confirm(tester).onPressed, isNull); // chưa chọn
  });

  testWidgets('rỗng → thông báo, nút Xác nhận disabled', (tester) async {
    await pumpSheet(tester, dep('d1', guardian: 'me'), members: <HouseholdMember>[
      ff.member('me', 'OWNER'),
      ff.member('v', 'REMOTE_VIEWER'),
    ]);
    expect(byKey('change-guardian-empty'), findsOneWidget);
    expect(confirm(tester).onPressed, isNull);
  });

  testWidgets('submitting → nút loading; ERR_DEP_004 → banner lỗi', (tester) async {
    final f = await pumpSheet(tester, dep('d1', guardian: 'me'));
    final gate = Completer<void>();
    f.api.guardianGate = gate;
    f.api.guardianError = BusinessException('ERR_DEP_004', 'invalid');
    await tester.tap(byKey('change-guardian-a'));
    await tester.pump();
    await tester.tap(byKey('change-guardian-confirm'));
    await tester.pump();
    expect(confirm(tester).isLoading, isTrue);
    gate.complete();
    await tester.pumpAndSettle();
    expect(byKey('change-guardian-error'), findsOneWidget);
    expect(find.text(l.dependentErrorInvalidGuardian), findsOneWidget);
    expect(f.api.count('guardian:d1:a'), 1);
  });
}
