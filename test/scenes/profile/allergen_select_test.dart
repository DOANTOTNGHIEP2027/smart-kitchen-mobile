import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/profile/allergen_select_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/stale_data_banner.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import 'health_test_fakes.dart';

void main() {
  late FakeHealthApi api;
  late MemoryReadCache cache;
  late ProfileStore store;

  setUp(() {
    api = FakeHealthApi();
    cache = MemoryReadCache();
    store = putProfileStore(api, cache);
  });
  tearDown(Get.reset);

  bool checked(WidgetTester tester, int id) =>
      tester.widget<CheckboxListTile>(byKey('allergen-$id')).value!;

  // Guard 12 / invariant I-ALG — test chống hồi quy an toàn dị ứng, KHÔNG XOÁ.
  group('Anti-wipe: không bao giờ PUT [] từ trạng thái chưa biết', () {
    testWidgets(
        'health lỗi → không checklist, không nút Lưu; store từ chối saveAllergens',
        (tester) async {
      api.readError = ServerException('ERR_INTERNAL', 'down');
      await pumpHealthScreen(tester, const AllergenSelectScreen());
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được dị ứng hiện tại'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(byKey('allergens-save'), findsNothing);
      expect(await store.saveAllergens(const <int>[]), isFalse);
      expect(api.allergenWrites, isEmpty);
    });

    testWidgets('health đang tải → spinner, không checklist/Lưu',
        (tester) async {
      api.readGate = Completer<void>();
      await pumpHealthScreen(tester, const AllergenSelectScreen());
      expect(find.byType(AppLoadingView), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(byKey('allergens-save'), findsNothing);
      expect(await store.saveAllergens(const <int>[]), isFalse);
      api.readGate!.complete();
      await tester.pumpAndSettle();
      expect(api.allergenWrites, isEmpty);
    });

    testWidgets(
        'health từ cache → chip chỉ đọc + cần mạng; không checklist/Lưu',
        (tester) async {
      api.profile = healthProfile(
          allergens: const <Allergen>[Allergen(id: 1, name: 'Gluten')]);
      await store.loadHealthProfile(); // ghi cache
      api.readError = NetworkException();
      await store.loadHealthProfile(); // mất mạng → fallback cache
      await pumpHealthScreen(tester, const AllergenSelectScreen());
      await tester.pumpAndSettle();
      expect(store.healthProfileIsFromCache, isTrue);
      expect(find.byType(StaleDataBanner), findsOneWidget);
      expect(find.text('Cần kết nối mạng để sửa dị ứng.'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Gluten'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(byKey('allergens-save'), findsNothing);
      expect(await store.saveAllergens(const <int>[]), isFalse);
      expect(api.allergenWrites, isEmpty);
      expect(store.healthProfileIsFromCache, isTrue);
    });

    testWidgets('lỗi → Thử lại thành công → checklist seed đúng từ server',
        (tester) async {
      api.profile = healthProfile(
          allergens: const <Allergen>[Allergen(id: 2, name: 'Trứng')]);
      api.readError = NetworkException();
      await pumpHealthScreen(tester, const AllergenSelectScreen());
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      api.readError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(checked(tester, 2), isTrue);
      expect(checked(tester, 1), isFalse);
      expect(find.text('1 đã chọn'), findsOneWidget);
    });
  });

  testWidgets('A3: seed sẵn + bộ đếm trực tiếp + Lưu gửi toàn bộ lựa chọn',
      (tester) async {
    api.profile = healthProfile(
        allergens: const <Allergen>[Allergen(id: 1, name: 'Gluten')]);
    await pumpHealthScreen(tester, const AllergenSelectScreen());
    await tester.pumpAndSettle();
    expect(find.text('3 chất gây dị ứng phổ biến'), findsOneWidget);
    expect(find.text('1 đã chọn'), findsOneWidget);
    expect(checked(tester, 1), isTrue);

    await tester.tap(byKey('allergen-3'));
    await tester.pump();
    expect(find.text('2 đã chọn'), findsOneWidget);

    await tapKey(tester, 'allergens-save');
    await tester.pumpAndSettle();
    expect(api.allergenWrites.single, <int>[1, 3]);
    final state = store.healthProfileState as SuccessState<HealthProfile>;
    expect(state.data.allergens.map((a) => a.id), <int>[1, 3]);
    expect(find.text('Đã cập nhật dị ứng'), findsOneWidget);
  });

  testWidgets('bỏ tick hết rồi Lưu ở A3 → gửi [] (lựa chọn thật của user)',
      (tester) async {
    api.profile = healthProfile(
        allergens: const <Allergen>[Allergen(id: 1, name: 'Gluten')]);
    await pumpHealthScreen(tester, const AllergenSelectScreen());
    await tester.pumpAndSettle();
    await tester.tap(byKey('allergen-1'));
    await tester.pump();
    expect(find.text('0 đã chọn'), findsOneWidget);
    await tapKey(tester, 'allergens-save');
    await tester.pumpAndSettle();
    expect(api.allergenWrites.single, isEmpty);
  });

  testWidgets(
      'lỗi lưu ERR_ALLERGEN_NOT_FOUND → hiện lỗi l10n, reload catalog, giữ lựa chọn',
      (tester) async {
    api.allergenWriteError =
        BusinessException('ERR_ALLERGEN_NOT_FOUND', 'Allergen not found');
    await pumpHealthScreen(tester, const AllergenSelectScreen());
    await tester.pumpAndSettle();
    expect(api.catalogReads, 1);
    await tester.tap(byKey('allergen-2'));
    await tester.pump();
    await tapKey(tester, 'allergens-save');
    await tester.pumpAndSettle();
    expect(find.text('Có lỗi khi lưu, vui lòng thử lại.'), findsOneWidget);
    expect(find.text('Allergen not found'), findsNothing);
    expect(api.catalogReads, 2);
    expect(checked(tester, 2), isTrue);
    expect(find.text('1 đã chọn'), findsOneWidget);
  });

  testWidgets('lỗi mạng khi lưu → hiện lỗi mạng, không tự retry',
      (tester) async {
    api.allergenWriteError = NetworkException();
    await pumpHealthScreen(tester, const AllergenSelectScreen());
    await tester.pumpAndSettle();
    await tapKey(tester, 'allergens-save');
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra kết nối và thử lại'), findsOneWidget);
    expect(api.allergenWrites, hasLength(1));
    expect(byKey('allergens-save'), findsOneWidget);
  });
}
