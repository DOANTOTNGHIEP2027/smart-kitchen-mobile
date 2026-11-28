import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/jwt_claims.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/demo/demo_backend_adapter.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_session_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_session_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/meal_log_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/recipe_api.dart';
import 'package:smart_kitchen_mobile/scenes/household/api/household_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_suggestion_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/family_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/monthly_recap_api.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/recap_api.dart';
import 'package:smart_kitchen_mobile/utils/dio_exception_x.dart';

import '../helpers/secure_storage_channel.dart';

/// `DemoBackendAdapter` chỉ hữu ích nếu payload nó trả về parse được bằng
/// **chính** model production. Nếu một model đổi tên field mà demo không đổi
/// theo, bản demo sẽ vỡ lúc trình diễn chứ không phải lúc chạy test — nên
/// khoá lại ở đây.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late AuthApi authApi;
  late HouseholdApi householdApi;
  late HealthApi healthApi;
  late InventoryApi inventoryApi;
  late MealPlanApi mealPlanApi;
  late MealSuggestionApi suggestionApi;
  late RecipeApi recipeApi;
  late CookingSessionApi cookingApi;
  late RecapApi recapApi;
  late MealLogApi mealLogApi;
  late MonthlyRecapApi monthlyRecapApi;
  late DioClient client;

  setUp(() {
    storageChannel.install();
    client = DioClient.build(
      tokenStorage: TokenStorage(),
      dio: Dio(BaseOptions(baseUrl: 'https://demo.local')),
    )..dio.httpClientAdapter = DemoBackendAdapter();
    authApi = AuthApiImpl(client);
    householdApi = HouseholdApiImpl(client);
    healthApi = HealthApiImpl(client);
    inventoryApi = InventoryApiImpl(client);
    mealPlanApi = MealPlanApiImpl(client);
    suggestionApi = MealSuggestionApi(client);
    recipeApi = RecipeApiImpl(client);
    cookingApi = CookingSessionApiImpl(client);
    recapApi = RecapApi(client);
    mealLogApi = MealLogApiImpl(client);
    monthlyRecapApi = MonthlyRecapApi(client);
  });

  tearDown(storageChannel.uninstall);

  test('đăng ký → OTP đúng trả session parse được', () async {
    final registered = await authApi.register(
      email: 'a@demo.local',
      password: 'password123',
      fullName: 'Demo',
    );
    expect(registered.requiresOtp, isTrue);

    final session = await authApi.verifyOtp(
      email: 'a@demo.local',
      otp: DemoBackendAdapter.correctOtp,
    );

    expect(session.accessToken, isNotEmpty);
    expect(session.user.id, isNotEmpty);
    // JWT giả phải decode được, nếu không thì điều hướng household sẽ sai.
    expect(decodeJwtPayload(session.accessToken), isNotEmpty);
  });

  test('email đã tồn tại trả ERR_AUTH_003 có kiểu', () async {
    ApiException? caught;
    try {
      await authApi.register(
        email: DemoBackendAdapter.takenEmail,
        password: 'password123',
        fullName: 'Demo',
      );
    } on DioException catch (e) {
      caught = e.apiException;
    }

    expect(caught?.code, 'ERR_AUTH_003');
  });

  test('OTP sai trả ERR_AUTH_OTP_INVALID', () async {
    ApiException? caught;
    try {
      await authApi.verifyOtp(email: 'a@demo.local', otp: '000000');
    } on DioException catch (e) {
      caught = e.apiException;
    }

    expect(caught?.code, 'ERR_AUTH_OTP_INVALID');
  });

  test('sai mật khẩu 3 lần → khoá 429', () async {
    Future<String?> attempt() async {
      try {
        await authApi.login(email: 'a@demo.local', password: 'sai');
        return null;
      } on DioException catch (e) {
        return e.apiException?.code;
      }
    }

    expect(await attempt(), 'ERR_AUTH_004');
    expect(await attempt(), 'ERR_AUTH_004');
    expect(await attempt(), 'ERR_AUTH_004');
    expect(await attempt(), 'ERR_AUTH_RATE_LIMIT');
  });

  test('tạo Nhà trả inviteCode, và mã đó preview được ngay', () async {
    final created = await householdApi.create('Nhà demo');

    expect(created.inviteCode.length, 8);

    final preview = await householdApi.preview(created.inviteCode);

    expect(preview.isValid, isTrue);
    expect(preview.householdName, isNotEmpty);
  });

  test('mã mời có sẵn: hợp lệ, hết hạn, bị dùng mất', () async {
    final valid =
        await householdApi.preview(DemoBackendAdapter.validInviteCode);
    expect(valid.isValid, isTrue);

    Future<String?> previewCode(String code) async {
      try {
        await householdApi.preview(code);
        return null;
      } on DioException catch (e) {
        return e.apiException?.code;
      }
    }

    expect(
        await previewCode(DemoBackendAdapter.expiredInviteCode), 'ERR_HH_002');

    String? joinCode;
    try {
      await householdApi.join(DemoBackendAdapter.racedInviteCode);
    } on DioException catch (e) {
      joinCode = e.apiException?.code;
    }
    expect(joinCode, 'ERR_HH_005');
  });

  test('guest join trả session kèm cờ hoàn tất hồ sơ', () async {
    final result = await authApi.joinAsGuest(
      inviteCode: DemoBackendAdapter.validInviteCode,
      displayName: 'Bé Na',
    );

    expect(result.requiresProfileCompletion, isTrue);
    // JWT của qr-join phải mang sẵn household_id (S8.10 — không cần refresh).
    final claims = decodeJwtPayload(result.session.accessToken);
    expect(claims['household_id'], isNotNull);
  });

  test('hồ sơ sức khoẻ và dị ứng demo có thể cập nhật', () async {
    final profile = await healthApi.getMyHealthProfile();
    expect(profile.targetDailyCalories, 1800);
    expect(profile.allergens, isNotEmpty);

    final allergens = await healthApi.getAllergenCatalog();
    final selected = await healthApi.updateMyAllergens(<int>[allergens[1].id]);

    expect(selected.single.name, 'Sữa');
    final refreshed = await healthApi.getMyHealthProfile();
    expect(refreshed.allergens.single.name, 'Sữa');
  });

  test('sửa hồ sơ demo: upload avatar (201) rồi PUT /users/me', () async {
    final profileApi = ProfileApiImpl(client);
    final uploaded =
        await profileApi.uploadAvatar(Uint8List.fromList(<int>[0xFF, 0xD8]));
    expect(uploaded.url, contains(uploaded.key));

    final user =
        await profileApi.updateMe(fullName: 'Tên mới', avatarUrl: uploaded.url);
    expect(user.fullName, 'Tên mới');
    expect(user.avatarUrl, uploaded.url);

    final onlyName = await profileApi.updateMe(fullName: 'Tên khác');
    expect(onlyName.avatarUrl, uploaded.url, reason: 'key vắng = giữ nguyên');
  });

  test('gia đình demo: DELETE thành viên (204) → roster không còn người đó',
      () async {
    final familyApi = FamilyApiImpl(client);
    final before = await familyApi.getMyHousehold();
    final target = before.members
        .firstWhere((m) => m.userId != before.members.first.userId);

    await familyApi.removeMember(target.userId);

    final after = await familyApi.getMyHousehold();
    expect(after.members.map((m) => m.userId), isNot(contains(target.userId)));
    expect(after.memberCount, before.memberCount - 1);
    final invite = await familyApi.createInvite();
    expect(invite.code, isNotEmpty);
  });

  test('kho demo lưu được create và update trong cùng phiên', () async {
    final before = await inventoryApi.list();
    final created = await inventoryApi.create(<String, dynamic>{
      'name': 'Rau cải',
      'category': 'Rau củ',
      'quantity': 2.0,
      'unit': 'BÓ',
      'lowStockThreshold': 1.0,
      'expiryDate': '2026-09-25',
      'note': 'Dùng cho bữa tối',
    });
    final updated = await inventoryApi.update(
      created.id,
      version: created.version,
      payload: <String, dynamic>{
        'name': 'Rau cải ngọt',
        'category': 'Rau củ',
        'quantity': 3.0,
        'unit': 'BÓ',
        'lowStockThreshold': 1.0,
        'expiryDate': '2026-09-26',
        'note': null,
      },
    );

    expect(updated.name, 'Rau cải ngọt');
    expect(updated.version, created.version + 1);
    expect((await inventoryApi.list()).totalElements, before.totalElements + 1);
  });

  test('plan → suggestions → direct selection keeps demo state', () async {
    final plan = await mealPlanApi.getCurrent();
    final slot = plan.slots.firstWhere((s) => s.mealTime == 'LUNCH');
    final dish = await mealPlanApi.addDish(plan.id, slot.id);
    final rows = await suggestionApi.generate(plan.id, slot.id, dish.id);
    expect(rows, hasLength(3));
    final assigned =
        await suggestionApi.select(plan.id, slot.id, dish.id, rows.first.id!);
    expect(assigned.recipe?.source, 'AI');
    final fetched = await suggestionApi.list(plan.id, slot.id, dish.id);
    expect(fetched.first.id, rows.first.id);
  });

  test('công thức và phiên nấu demo chạy được đến hoàn tất', () async {
    const recipeId = 'demo-recipe-ca-kho';
    final steps = await recipeApi.getSteps(recipeId);
    expect(steps, isNotEmpty);

    final started = await cookingApi.start(recipeId);
    final completed = await cookingApi.complete(started.id);

    expect(completed.session.recipeId, recipeId);
    expect(completed.deductions, isNotEmpty);
  });

  test('phiên nấu demo thiếu kho → 409 kèm chi tiết, xác nhận thì hoàn tất',
      () async {
    final started = await cookingApi.start('demo-recipe-canh-chua');

    await expectLater(
      cookingApi.complete(started.id),
      throwsA(isA<BusinessException>()
          .having((e) => e.code, 'code', 'ERR_INSUFFICIENT_STOCK_FOR_RECIPE')
          .having(
              (e) => mapMissingIngredients(e.details), 'missing', isNotEmpty)),
    );

    final completed =
        await cookingApi.complete(started.id, allowShortfall: true);
    expect(completed.deductions.any((d) => d.hasShortfall), isTrue);
  });

  test('tổng kết tuần và chuỗi demo parse chuẩn model production', () async {
    final recap = await recapApi.getWeeklyRecap();
    expect(recap.mealsLoggedCount, greaterThan(0));
    expect(recap.householdSummary, isNotEmpty);
    expect(recap.memberInsights, isNotEmpty);

    final streak =
        await recapApi.getHouseholdStreak(memberId: 'user-primary-1');
    expect(streak.currentStreak, greaterThanOrEqualTo(0));
    expect(streak.bestStreak, greaterThanOrEqualTo(0));
  });

  test('tổng kết tháng demo parse chuẩn model production', () async {
    final now = DateTime.now();
    final current = await monthlyRecapApi.getMonthlyRecap();
    expect(current.month, DateTime(now.year, now.month));
    expect(current.memberInsights.first.weeks, isNotEmpty);
    expect(current.hasPrevious, isTrue);

    final oldest = await monthlyRecapApi.getMonthlyRecap(
        month: DateTime(now.year, now.month - 3));
    expect(oldest.hasPrevious, isFalse);

    await expectLater(
      monthlyRecapApi.getMonthlyRecap(month: DateTime(now.year, now.month + 1)),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'ERR_RECAP_MONTH_INVALID')),
    );
  });

  test('nhật ký bữa ăn demo đọc và ghi được', () async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);

    final logs = await mealLogApi.listLogs(from: from, to: to);
    expect(logs, isNotEmpty);

    final newLog = await mealLogApi.logMeal(description: 'Cơm tấm sườn bì chả');
    expect(newLog.description, contains('Cơm tấm sườn bì chả'));
  });
}
