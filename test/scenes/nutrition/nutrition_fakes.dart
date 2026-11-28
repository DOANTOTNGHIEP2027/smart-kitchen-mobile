import 'dart:async';

import 'package:smart_kitchen_mobile/scenes/cooking/data/meal_log_api.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_nutrition_macros.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';

const String selfId = 'u1';

/// Fake nhật ký: trả [logs], ghi lại tham số của lần gọi cuối; có thể treo
/// (Completer) hoặc ném lỗi.
class NutritionMealLogApi implements MealLogApi {
  NutritionMealLogApi([List<MealLogEntry>? logs]) : logs = logs ?? <MealLogEntry>[];

  List<MealLogEntry> logs;
  Object? error;
  Completer<void>? hold;
  int calls = 0;
  DateTime? lastFrom;
  DateTime? lastTo;
  String? lastMemberId;
  int? lastSize;

  @override
  Future<List<MealLogEntry>> listLogs({
    required DateTime from,
    required DateTime to,
    String? memberId,
    int size = 50,
  }) async {
    calls++;
    lastFrom = from;
    lastTo = to;
    lastMemberId = memberId;
    lastSize = size;
    final pending = hold;
    if (pending != null) await pending.future;
    if (error != null) throw error!;
    return List<MealLogEntry>.of(logs);
  }

  @override
  Future<MealLogEntry> logMeal({required String description, String? imageBase64}) =>
      throw UnimplementedError();
  @override
  Future<MealLogEntry> confirm({required String id, double? caloriesKcal}) =>
      throw UnimplementedError();
}

int _seq = 0;

/// 1 log đã lưu ở BE. [at] là giờ máy; mặc định bữa trưa.
MealLogEntry logAt(
  DateTime at, {
  double? kcal = 500,
  double p = 20,
  double c = 50,
  double f = 10,
  MealType meal = MealType.lunch,
  String text = 'Phở',
  String memberId = selfId,
  bool requiresConfirmation = false,
  bool confirmedByUser = false,
  MealEntryStatus status = MealEntryStatus.saved,
}) =>
    MealLogEntry(
      id: 'log-${_seq++}',
      householdId: 'h1',
      memberId: memberId,
      loggedBy: memberId,
      description: meal.composeDescription(text),
      caloriesKcal: kcal,
      nutrition: MealNutritionMacros(proteinG: p, carbsG: c, fatG: f),
      requiresConfirmation: requiresConfirmation,
      confirmedByUser: confirmedByUser,
      loggedAt: at,
      status: status,
    );

class NutritionHealthApi implements HealthApi {
  NutritionHealthApi({this.target});

  int? target;
  Object? error;
  int calls = 0;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    calls++;
    if (error != null) throw error!;
    return HealthProfile(userId: selfId, targetDailyCalories: target, allergens: const <Allergen>[]);
  }

  @override
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload) => throw UnimplementedError();
  @override
  Future<List<Allergen>> getAllergenCatalog() => throw UnimplementedError();
  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) => throw UnimplementedError();
  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) => throw UnimplementedError();
}
