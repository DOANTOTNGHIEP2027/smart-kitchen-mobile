import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mobx/mobx.dart' show runInAction;
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/home/stores/home_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/profile_avatar.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';

class _MockMealPlanApi extends Mock implements MealPlanApi {}

/// R3 mục 8: header Home đọc `SessionStore.currentUser` trong Observer —
/// đổi tên/ảnh ở Hồ sơ phải hiện ngay, ảnh qua ProfileAvatar.
void main() {
  late SessionStore session;

  setUp(() {
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()));
    Get.put<SessionStore>(session);
    final mealPlanApi = _MockMealPlanApi();
    when(mealPlanApi.getCurrent).thenThrow(NetworkException());
    Get.put<HomeStore>(HomeStore(mealPlanApi: mealPlanApi));
  });
  tearDown(Get.reset);

  ProfileAvatar avatar(WidgetTester tester) => tester.widget<ProfileAvatar>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('home-header-avatar')),
          matching: find.byType(ProfileAvatar),
        ),
      );

  testWidgets('đổi currentUser → tên + avatar header cập nhật ngay',
      (tester) async {
    runInAction(() =>
        session.currentUser = const UserSummary(id: 'u1', fullName: 'An'));
    await tester.pumpAppWidget(const HomeTab(), wrapInScaffold: false);
    await tester.pump();

    expect(find.text('An'), findsOneWidget);
    // Chưa có ảnh → chữ cái đầu.
    expect(avatar(tester).avatarUrl, isNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('home-header-avatar')),
        matching: find.text('A'),
      ),
      findsOneWidget,
    );

    runInAction(() => session.currentUser = const UserSummary(
        id: 'u1',
        fullName: 'Bình',
        avatarUrl: 'https://example.com/avatar.png'));
    await tester.pump();

    expect(find.text('Bình'), findsOneWidget);
    expect(find.text('An'), findsNothing);
    expect(avatar(tester).avatarUrl, 'https://example.com/avatar.png');
    expect(avatar(tester).fullName, 'Bình');
  });
}
