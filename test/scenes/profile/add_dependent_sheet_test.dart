import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_list_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/add_dependent_sheet.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart';

/// #125 §16.9/§16.14 — AddDependentSheet (chỉ tên + DOB tuỳ chọn).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(() {
    storage.uninstall();
    Get.reset();
  });
  final l = lookupAppLocalizations(const Locale('vi'));

  Future<DepFixture> openSheet(WidgetTester tester) async {
    final f = await makeDepFixture(register: true);
    await pumpDependentScreen(tester, const DependentListScreen());
    await tester.tap(byKey('dependent-add'));
    await tester.pumpAndSettle();
    expect(find.byType(AddDependentSheet), findsOneWidget);
    return f;
  }

  AppButton save(WidgetTester tester) =>
      tester.widget<AppButton>(byKey('add-dependent-save'));

  testWidgets('tên rỗng/khoảng trắng → nút Lưu disabled', (tester) async {
    await openSheet(tester);
    expect(save(tester).onPressed, isNull);
    await tester.enterText(byKey('add-dependent-name'), '   ');
    await tester.pump();
    expect(save(tester).onPressed, isNull);
  });

  testWidgets('L1: > 255 code unit UTF-16 (≤ 255 grapheme) → dependentNameTooLong, API không gọi', (tester) async {
    final f = await openSheet(tester);
    final name = '${'a' * 250}😀😀😀'; // 253 grapheme, 256 code unit
    await tester.enterText(byKey('add-dependent-name'), name);
    await tester.pump();
    expect(find.text(l.dependentNameTooLong), findsOneWidget);
    await tester.tap(byKey('add-dependent-save'));
    await tester.pump();
    expect(f.api.count('create'), 0);
    // Không có maxLength cắt chữ: toàn bộ ký tự vẫn nằm trong ô.
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text.length, 256);
  });

  testWidgets('không chọn DOB → tạo với dateOfBirth null; thành công → đóng sheet + toast + list có item', (tester) async {
    final f = await openSheet(tester);
    await tester.enterText(byKey('add-dependent-name'), ' Bé Na ');
    await tester.pump();
    await tester.tap(byKey('add-dependent-save'));
    await tester.pumpAndSettle();
    expect(f.api.creates.single.$1, 'Bé Na');
    expect(f.api.creates.single.$2, isNull);
    expect(find.byType(AddDependentSheet), findsNothing);
    expect(find.text(l.dependentCreatedToast), findsOneWidget);
    expect(find.text('Bé Na'), findsOneWidget);
  });

  testWidgets('lỗi ERR_DEP_003 → banner inline, sheet ở lại', (tester) async {
    final f = await openSheet(tester);
    f.api.createError = BusinessException('ERR_DEP_003', 'remote viewer');
    await tester.enterText(byKey('add-dependent-name'), 'Bé Na');
    await tester.pump();
    await tester.tap(byKey('add-dependent-save'));
    await tester.pumpAndSettle();
    expect(byKey('add-dependent-error'), findsOneWidget);
    expect(find.text(l.dependentErrorForbidden), findsOneWidget);
    expect(find.byType(AddDependentSheet), findsOneWidget);
  });
}
