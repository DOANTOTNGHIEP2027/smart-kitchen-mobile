import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../widgets/states/view_state.dart';
import '../../auth/stores/store_error.dart';
import '../../mealplan/data/meal_plan_api.dart';
import '../../mealplan/domain/meal_plan_slot.dart';
import '../../mealplan/stores/meal_plan_store.dart';
import '../../profile/api/health_api.dart';
import '../../recipe/data/recipe_catalog_api.dart';
import '../../recipe/domain/recipe.dart';
import '../domain/compliance.dart';
import '../domain/nutrition_models.dart';
import '../domain/weekly_nutrition_calculator.dart';

/// Tổng hợp dinh dưỡng tuần kế hoạch — FE tự tính (nutrition-summary-widget.md
/// §7, D15).
///
/// [state] là computed trên cache: đổi món mà recipe đã có trong cache thì số
/// đổi ngay trong cùng frame (AC "cập nhật ngay khi slots đổi"); recipe mới
/// hoặc tuần mới đi qua Loading — không bao giờ hiện số của tuần cũ.
class NutritionStore extends GetLifeCycle {
  NutritionStore({
    required RecipeCatalogApi recipeApi,
    required HealthApi healthApi,
    MealPlanApi? mealPlanApi,
  })  : _recipeApi = recipeApi,
        _healthApi = healthApi,
        _mealPlanApi = mealPlanApi;

  static const String mealPlanTag = 'nutrition-meal-plan';
  static const String recipeNotFoundCode = 'ERR_RECIPE_NOT_FOUND';
  static const String profileTag = 'nutrition-profile';

  final RecipeCatalogApi _recipeApi;
  final HealthApi _healthApi;
  final MealPlanApi? _mealPlanApi;

  /// `null` = recipe không có dữ liệu dinh dưỡng (hoặc BE trả 4xx).
  final ObservableMap<String, RecipeNutrition?> nutritionCache = ObservableMap();
  final Set<String> _inFlight = <String>{};

  final Observable<MealPlanStore?> _mealPlan = Observable(null);
  final Observable<MealPlanDto?> _plan = Observable(null);
  final Observable<bool> _planLoading = Observable(false);
  final Observable<bool> _noPlan = Observable(false);
  final Observable<int?> _target = Observable(null);
  final Observable<bool> _targetLoaded = Observable(false);
  /// Lỗi plan/target (không gắn với recipe nào).
  final Observable<ApiException?> _error = Observable(null);

  /// Lỗi theo từng recipe — chỉ làm widget lỗi khi recipe đó thuộc tuần đang
  /// xem (review v3.1 NEW-M4), không dính sang tuần khác.
  final ObservableMap<String, ApiException> _recipeErrors = ObservableMap();
  ReactionDisposer? _fetchDisposer;
  ReactionDisposer? _targetDisposer;

  int? get targetDailyCalories => _target.value;
  ApiException? get error => _error.value ?? _currentRecipeError.value;

  late final Computed<ApiException?> _currentRecipeError = Computed(() {
    final source = _source.value;
    if (source == null || _recipeErrors.isEmpty) return null;
    for (final id in confirmedRecipeIds(source.slots, source.weekStart)) {
      final error = _recipeErrors[id];
      if (error != null) return error;
    }
    return null;
  });

  /// Tuần + slots hiện tại; `null` khi nguồn chưa sẵn sàng.
  late final Computed<({DateTime weekStart, List<MealPlanSlot> slots})?>
      _source = Computed(() {
    final mealPlan = _mealPlan.value;
    if (mealPlan != null) {
      if (mealPlan.status != MealPlanLoadStatus.ready) return null;
      return (
        weekStart: mealPlan.currentWeekStart,
        slots: mealPlan.slots.values.toList(),
      );
    }
    final plan = _plan.value;
    // Giữ plan cũ trong lúc tải lại để không nháy skeleton mỗi lần vào tab
    // (review v3.1 NEW-L2).
    if (plan == null) return null;
    return (weekStart: plan.weekStart, slots: plan.slots);
  });

  /// Recipe confirmed của tuần chưa có trong cache. Dùng `containsKey` — giá
  /// trị `null` nghĩa là "đã tải, không có dữ liệu". Recipe đang lỗi không
  /// tính là pending (chờ `retry`), tránh vòng gọi lại vô hạn.
  late final Computed<Set<String>> _pending = Computed(() {
    final source = _source.value;
    if (source == null) return const <String>{};
    return confirmedRecipeIds(source.slots, source.weekStart)
        .where((id) =>
            !nutritionCache.containsKey(id) && !_recipeErrors.containsKey(id))
        .toSet();
  }, equals: (a, b) => setEquals(a, b));

  Set<String> get pendingRecipeIds => _pending.value;

  late final Computed<ViewState<NutritionWeekSummary>> _state = Computed(() {
    final error = this.error;
    if (error != null) return ErrorState(error);
    if (_noPlan.value && _mealPlan.value == null) return const EmptyState();
    if (_planLoading.value && _plan.value == null && _mealPlan.value == null) {
      return const LoadingState();
    }
    final source = _source.value;
    if (source == null || !_targetLoaded.value || _pending.value.isNotEmpty) {
      return const LoadingState();
    }
    final summary = computeWeeklyNutrition(
      weekStart: source.weekStart,
      slots: source.slots,
      nutritionByRecipe: nutritionCache,
      targetDailyCalories: _target.value,
    );
    return summary.plannedDishCount == 0
        ? const EmptyState()
        : SuccessState(summary);
  });

  ViewState<NutritionWeekSummary> get state => _state.value;

  NutritionWeekSummary? get summary => switch (state) {
        SuccessState<NutritionWeekSummary>(:final data) => data,
        _ => null,
      };
  double? get avgDailyCalories => summary?.avgDailyCalories;
  MacroRatios? get macroRatios => summary?.macroRatios;
  int? get complianceScore => summary?.complianceScore;
  ComplianceLevel get complianceLevel =>
      summary?.level ?? ComplianceLevel.unknown;

  /// WeeklyMealPlanScreen: theo tuần đang xem của [mealPlan]. Gọi lần 2 bỏ qua.
  void attach(MealPlanStore mealPlan) {
    if (_mealPlan.value != null) return;
    runInAction(() => _mealPlan.value = mealPlan);
    _startFetching();
    unawaited(refreshTarget());
  }

  /// Profile: tự tải kế hoạch tuần hiện tại + target (§8.2).
  Future<void> loadCurrentWeek() async {
    final api = _mealPlanApi;
    if (api == null || _planLoading.value) return;
    runInAction(() {
      _planLoading.value = true;
      _error.value = null;
    });
    _startFetching();
    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        _loadPlan(api),
        refreshTarget(),
      ]);
      final plan = results.first as MealPlanDto?;
      runInAction(() {
        _plan.value = plan;
        _noPlan.value = plan == null;
      });
    } catch (raw) {
      runInAction(() => _error.value = storeApiException(raw));
    } finally {
      runInAction(() => _planLoading.value = false);
    }
  }

  Future<MealPlanDto?> _loadPlan(MealPlanApi api) async {
    try {
      return await api.getCurrent();
    } catch (raw) {
      final error = storeApiException(raw);
      // Đầu tuần chưa có plan → Empty, không phải lỗi (review v3 HIGH-1).
      if (error is BusinessException && error.code == 'ERR_PLAN_NOT_FOUND') {
        return null;
      }
      rethrow;
    }
  }

  /// Theo dõi target từ một nguồn đã có sẵn (vd. `ProfileStore.
  /// healthProfileState`): mỗi lần nguồn có giá trị mới thì cập nhật target
  /// ngay — người dùng đổi mục tiêu ở bất kỳ màn nào cũng thấy (review v3.1
  /// NEW-M2). Gọi lần 2 bỏ qua.
  void followTarget(int? Function()? Function() read) {
    _targetDisposer ??= reaction<int? Function()?>(
      (_) => read(),
      (value) {
        if (value == null) return;
        runInAction(() {
          _target.value = value();
          _targetLoaded.value = true;
        });
      },
      fireImmediately: true,
    );
  }

  /// Lấy lại target — gọi sau khi người dùng đặt mục tiêu (review v3 HIGH-3).
  Future<void> refreshTarget() async {
    try {
      final profile = await _healthApi.getMyHealthProfile();
      runInAction(() {
        _target.value = profile.targetDailyCalories;
        _targetLoaded.value = true;
      });
    } catch (raw) {
      // HealthApi ném DioException thô — chuẩn hoá (review v3 HIGH-2).
      runInAction(() => _error.value = storeApiException(raw));
    }
  }

  Future<void> retry() async {
    runInAction(() {
      _error.value = null;
      _recipeErrors.clear();
    });
    if (_mealPlan.value == null && _mealPlanApi != null) {
      await loadCurrentWeek();
      return;
    }
    if (!_targetLoaded.value) await refreshTarget();
    await _fetchMissing(_pending.value);
  }

  void _startFetching() {
    _fetchDisposer ??= reaction<Set<String>>(
      (_) => _pending.value,
      (ids) => unawaited(_fetchMissing(ids)),
      fireImmediately: true,
    );
  }

  Future<void> _fetchMissing(Set<String> ids) async {
    final todo = ids.where((id) => _inFlight.add(id)).toList();
    if (todo.isEmpty) return;
    await Future.wait(todo.map(_fetchOne));
  }

  Future<void> _fetchOne(String recipeId) async {
    try {
      final recipe = await _recipeApi.getById(recipeId);
      runInAction(() {
        nutritionCache[recipeId] = recipe.nutrition;
        _recipeErrors.remove(recipeId);
      });
    } catch (raw) {
      final error = storeApiException(raw);
      runInAction(() {
        if (error.code == recipeNotFoundCode) {
          // Recipe đã bị xoá → món thiếu dữ liệu (cache null), không lỗi.
          nutritionCache[recipeId] = null;
        } else {
          // 429/403/mạng/5xx… → lỗi thử lại được, KHÔNG cache (review v3.1
          // NEW-M1: cache null sẽ làm điểm sai mà không báo).
          _recipeErrors[recipeId] = error;
        }
      });
    } finally {
      _inFlight.remove(recipeId);
    }
  }

  @override
  void onClose() {
    _fetchDisposer?.call();
    _fetchDisposer = null;
    _targetDisposer?.call();
    _targetDisposer = null;
    super.onClose();
  }
}
