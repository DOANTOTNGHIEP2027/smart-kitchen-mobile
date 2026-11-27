import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/calorie_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/health_profile_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/stale_data_banner.dart';

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

  Future<void> setSlider(WidgetTester tester, int value) async {
    tester
        .widget<Slider>(byKey('health-calorie-slider'))
        .onChanged!(value.toDouble());
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tapKey(tester, 'health-save');
    await tester.pumpAndSettle();
  }

  String calorieLabel(WidgetTester tester) =>
      tester.widget<Text>(byKey('health-calorie-label')).data!;

  testWidgets(
      'AC #29: kéo slider tới 1800 → "1800 kcal" → Lưu gửi đủ 4 field → view cập nhật ngay',
      (tester) async {
    api.profile = healthProfile(goal: 1500, diet: DietType.keto);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    expect(find.text('1500 kcal'), findsOneWidget);

    await tapKey(tester, 'health-edit');
    expect(calorieLabel(tester), '1500 kcal');
    await setSlider(tester, 1800);
    expect(calorieLabel(tester), '1800 kcal');

    await save(tester);
    expect(api.profileWrites.single, <String, dynamic>{
      'targetDailyCalories': 1800,
      'dietType': 'KETO',
      'heightCm': 170.0,
      'weightKg': 65.0,
      // #201: PUT thay toàn bộ — luôn gửi kể cả null.
      'gender': null,
      'birthDate': null,
      'activityLevel': null,
    });
    // Quay về chế độ xem, phản ánh ngay giá trị mới (không cần load lại).
    expect(byKey('health-edit'), findsOneWidget);
    expect(
        find.descendant(
            of: byKey('health-view-calories'),
            matching: find.text('1800 kcal')),
        findsOneWidget);
    expect(api.profileReads, 1);
  });

  testWidgets('#201 thiếu giới tính/ngày sinh/mức vận động → chỉ hiện hint',
      (tester) async {
    api.profile = healthProfile(goal: 1500);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    expect(byKey('health-calorie-suggestion-hint'), findsOneWidget);
    expect(byKey('health-calorie-apply'), findsNothing);
  });

  testWidgets('#201 đủ dữ liệu → Gợi ý + Áp dụng gửi giá trị gợi ý và 3 field mới',
      (tester) async {
    api.profile = HealthProfile(
      userId: 'me',
      targetDailyCalories: 1500,
      heightCm: 175,
      weightKg: 70,
      gender: Gender.male,
      birthDate: DateTime(1996, 1, 1),
      activityLevel: ActivityLevel.moderate,
      updatedAt: DateTime.utc(2026, 11, 15),
      allergens: const <Allergen>[],
    );
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    final expected = suggestDailyCalories(
        weightKg: 70,
        heightCm: 175,
        gender: Gender.male,
        birthDate: DateTime(1996, 1, 1),
        activityLevel: ActivityLevel.moderate)!;
    expect(find.text('Gợi ý: $expected kcal'), findsOneWidget);
    await tapKey(tester, 'health-calorie-apply');
    expect(calorieLabel(tester), '$expected kcal');
    await save(tester);
    expect(api.profileWrites.single['targetDailyCalories'], expected);
    expect(api.profileWrites.single['gender'], 'MALE');
    expect(api.profileWrites.single['birthDate'], '1996-01-01');
    expect(api.profileWrites.single['activityLevel'], 'MODERATE');
  });

  testWidgets('kéo slider bằng cử chỉ thật: nhãn và payload khớp nhau',
      (tester) async {
    api.profile = healthProfile(goal: 2000);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    await tester.drag(byKey('health-calorie-slider'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    final label = calorieLabel(tester);
    final shown = int.parse(label.split(' ').first);
    expect(shown, lessThan(2000));
    expect(shown % 50, 0);
    await save(tester);
    expect(api.profileWrites.single['targetDailyCalories'], shown);
  });

  testWidgets(
      'giá trị cũ 6000 (ngoài khoảng) + chỉ đổi chế độ ăn → payload vẫn 6000',
      (tester) async {
    api.profile = healthProfile(goal: 6000, diet: DietType.keto);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    expect(find.text('6000 kcal'), findsOneWidget,
        reason: 'View in đúng giá trị lưu');
    await tapKey(tester, 'health-edit');
    expect(calorieLabel(tester), 'Hiện tại: 6000 kcal');
    expect(byKey('health-calorie-legacy-note'), findsOneWidget);
    expect(tester.widget<Slider>(byKey('health-calorie-slider')).value, 5000);

    await tapKey(tester, 'health-diet-VEGETARIAN');
    await tester.pumpAndSettle();
    await save(tester);
    expect(api.profileWrites.single['targetDailyCalories'], 6000);
    expect(api.profileWrites.single['dietType'], 'VEGETARIAN');
  });

  testWidgets('"Chưa đặt" (null): slider disabled; tắt toggle → gửi 2000',
      (tester) async {
    api.profile = healthProfile();
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    expect(calorieLabel(tester), 'Chưa đặt');
    expect(tester.widget<Slider>(byKey('health-calorie-slider')).onChanged,
        isNull);
    await tapKey(tester, 'health-calorie-notset');
    expect(calorieLabel(tester), '2000 kcal');
    await save(tester);
    expect(api.profileWrites.single['targetDailyCalories'], 2000);
  });

  testWidgets('bật "Chưa đặt" từ 1800 → gửi null', (tester) async {
    api.profile = healthProfile(goal: 1800);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    await tapKey(tester, 'health-calorie-notset');
    await save(tester);
    expect(api.profileWrites.single.containsKey('targetDailyCalories'), isTrue);
    expect(api.profileWrites.single['targetDailyCalories'], isNull);
  });

  testWidgets('chiều cao/cân nặng nhập dấu phẩy được gửi đúng số',
      (tester) async {
    api.profile = healthProfile(goal: 1800);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    await tester.enterText(byKey('health-weight'), '65,5');
    await tester.enterText(byKey('health-height'), '172,3');
    await save(tester);
    expect(api.profileWrites.single['weightKg'], 65.5);
    expect(api.profileWrites.single['heightCm'], 172.3);
  });

  testWidgets('S10.2 empty: mọi field "Chưa thiết lập" + CTA mở form',
      (tester) async {
    api.profile = healthProfile(empty: true, height: null, weight: null);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    expect(find.text('Chưa thiết lập hồ sơ sức khỏe'), findsOneWidget);
    expect(find.text('Chưa thiết lập'), findsNWidgets(3));
    await tapKey(tester, 'health-setup');
    expect(byKey('health-calorie-slider'), findsOneWidget);
    expect(byKey('health-save'), findsOneWidget);
  });

  testWidgets('S10.3 view: nhãn l10n của diet, không in wire value',
      (tester) async {
    api.profile = healthProfile(
        goal: 1800,
        diet: DietType.glutenFree,
        allergens: const <Allergen>[Allergen(id: 1, name: 'Gluten')]);
    await pumpHealthScreen(tester, const HealthProfileScreen());
    expect(find.text('Không gluten'), findsOneWidget);
    expect(find.text('GLUTEN_FREE'), findsNothing);
    expect(find.widgetWithText(Chip, 'Gluten (lúa mì)'), findsOneWidget);
  });

  testWidgets(
      'S10.5: fieldErrors của server map inline theo field, không banner chung',
      (tester) async {
    api.profile = healthProfile(goal: 1800);
    api.writeError = ValidationException(
        'ERR_VALIDATION_FAILED', 'Validation failed',
        fieldErrors: const <String, String>{'heightCm': 'must be <= 300'});
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    await save(tester);
    expect(
        find.descendant(
            of: byKey('health-height'),
            matching:
                find.text('Nhập chiều cao từ 1 đến 300 cm hoặc để trống')),
        findsOneWidget);
    expect(find.text('Validation failed'), findsNothing);
    expect(find.textContaining('must be <= 300'), findsNothing);
    // Sửa field → lỗi inline biến mất.
    await tester.enterText(byKey('health-height'), '171');
    await tester.pump();
    expect(find.text('Nhập chiều cao từ 1 đến 300 cm hoặc để trống'),
        findsNothing);
  });

  testWidgets('L3: lỗi lưu không bao giờ lộ message tiếng Anh của BE (§12)',
      (tester) async {
    api.profile = healthProfile(goal: 1800);
    api.writeError = ValidationException(
        'ERR_VALIDATION_FAILED', 'Validation failed',
        fieldErrors: const <String, String>{
          'dietType': 'must be one of NONE, VEGAN',
          'mysteryField': 'is weird',
        });
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tapKey(tester, 'health-edit');
    await save(tester);
    expect(find.text('Đã có lỗi xảy ra. Vui lòng thử lại'), findsOneWidget);
    expect(find.text('Validation failed'), findsNothing);
    expect(find.textContaining('must be one of'), findsNothing);
    expect(find.textContaining('mysteryField'), findsNothing);
    expect(find.text('• Chế độ ăn'), findsOneWidget);

    api.writeError =
        BusinessException('ERR_HEALTH_UNKNOWN', 'English BE message');
    await save(tester);
    expect(find.textContaining('English'), findsNothing);
    expect(find.text('Đã có lỗi xảy ra. Vui lòng thử lại'), findsOneWidget);
  });

  testWidgets(
      'S10.3c cache: banner + Thử lại; Chỉnh sửa/Sửa dị ứng disabled; store chặn lưu',
      (tester) async {
    api.profile = healthProfile(goal: 1800);
    await store.loadHealthProfile(); // ghi cache
    api.readError = NetworkException();
    await pumpHealthScreen(tester, const HealthProfileScreen());
    await tester.pumpAndSettle();
    expect(store.healthProfileIsFromCache, isTrue);
    expect(find.byType(StaleDataBanner), findsOneWidget);
    expect(find.text('Cần kết nối mạng để chỉnh sửa.'), findsOneWidget);
    expect(find.text('1800 kcal'), findsOneWidget);
    final edit = tester.widget<TextButton>(byKey('health-allergens-edit'));
    expect(edit.onPressed, isNull);
    await tester.tap(byKey('health-edit'), warnIfMissed: false);
    await tester.pump();
    expect(byKey('health-calorie-slider'), findsNothing);

    expect(await store.saveHealthProfile(targetDailyCalories: 1500), isFalse);
    expect(await store.saveAllergens(const <int>[]), isFalse);
    expect(api.profileWrites, isEmpty);
    expect(api.allergenWrites, isEmpty);

    // Thử lại khi có mạng → hết chế độ chỉ đọc.
    api.readError = null;
    await tapKey(tester, 'stale-data-retry');
    await tester.pumpAndSettle();
    expect(store.healthProfileIsFromCache, isFalse);
    expect(find.byType(StaleDataBanner), findsNothing);
  });
}
