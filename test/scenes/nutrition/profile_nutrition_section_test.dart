import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/widgets/profile_nutrition_section.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';
import '../mealplan/fake_meal_plan_api.dart';
import 'nutrition_fakes.dart';

class _Storage implements TokenStorage {
  @override
  String? accessToken;
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<Map<String, dynamic>?> readUser() async => null;
  @override
  Future<void> saveTokens(String a, String r) async => accessToken = a;
  @override
  Future<void> saveUser(Map<String, dynamic> json) async {}
}

String _jwt(Map<String, dynamic> claims) =>
    'h.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.s';

void main() {
  late FakeMealPlanApi planApi;
  late NutritionStore store;
  late SessionStore session;
  late int getCurrentCalls;
  final week = DateTime.utc(2026, 11, 16);

  setUp(() async {
    getCurrentCalls = 0;
    planApi = FakeMealPlanApi()
      ..onGetCurrent = () async {
        getCurrentCalls++;
        return planOf(week, <MealPlanSlot>[plannedSlot(week, 0, 'LUNCH', <String>['a'])]);
      };
    store = NutritionStore(
      recipeApi: NutritionRecipeApi(<String, dynamic>{'a': kcal(1800)}.cast()),
      healthApi: NutritionHealthApi(target: 2000),
      mealPlanApi: planApi,
    );
    Get.put<NutritionStore>(store, tag: NutritionStore.profileTag);
    session = SessionStore(_Storage(), AuthRefreshUseCase(Dio()));
    Get.put<SessionStore>(session);
  });

  tearDown(() {
    store.onClose();
    Get.reset();
  });

  Future<void> signIn({String? householdId}) => session.setSession(
        accessToken: _jwt(<String, dynamic>{'household_id': householdId, 'role': 'OWNER'}),
        refreshToken: 'r',
        user: const UserSummary(id: 'u1', fullName: 'An'),
      );

  testWidgets('chỉ tải khi tab Cá nhân được chọn; chọn lại thì tải lại', (tester) async {
    await signIn(householdId: 'h1');
    final shell = AppShellStore();
    Get.put<AppShellStore>(shell);
    await tester.pumpAppWidget(const SingleChildScrollView(child: ProfileNutritionSection()));
    await tester.pump();
    expect(getCurrentCalls, 0, reason: 'đang ở tab Trang chủ');

    shell.selectTab(ProfileNutritionSection.profileTabIndex);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(getCurrentCalls, 1);
    expect(find.text('Dinh dưỡng tuần này'), findsOneWidget);
    expect(find.text('Chưa kiểm tra dị ứng — điểm chỉ dựa trên calo'), findsOneWidget);
    expect(find.text('Chi tiết theo ngày'), findsNothing, reason: 'compact');

    shell.selectTab(0);
    shell.selectTab(ProfileNutritionSection.profileTabIndex);
    await tester.pump();
    expect(getCurrentCalls, 2);
    expect(find.byKey(const ValueKey('nutrition-skeleton')), findsNothing,
        reason: 'giữ dữ liệu cũ khi tải lại, không nháy skeleton');

    await tester.ensureVisible(find.byKey(const ValueKey('nutrition-view-meal-plan')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nutrition-view-meal-plan')));
    expect(shell.selectedIndex, ProfileNutritionSection.mealPlanTabIndex);
  });

  testWidgets('chưa có household → ẩn hẳn', (tester) async {
    await signIn();
    await tester.pumpAppWidget(const ProfileNutritionSection());
    await tester.pump();
    expect(find.text('Dinh dưỡng tuần này'), findsNothing);
    expect(getCurrentCalls, 0, reason: 'không gọi API khi chưa có household');
  });

  testWidgets('không có AppShellStore (mở qua route riêng) → tải ngay', (tester) async {
    await signIn(householdId: 'h1');
    await tester.pumpAppWidget(const SingleChildScrollView(child: ProfileNutritionSection()));
    await tester.pump();
    await tester.pump();
    expect(getCurrentCalls, 1);
  });
}
