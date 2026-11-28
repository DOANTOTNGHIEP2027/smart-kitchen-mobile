import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../widgets/states/view_state.dart';
import '../../auth/stores/store_error.dart';
import '../../cooking/data/meal_log_api.dart';
import '../../cooking/domain/meal_log_entry.dart';
import '../../profile/api/health_api.dart';
import '../domain/compliance.dart';
import '../domain/nutrition_models.dart';
import '../domain/weekly_nutrition_calculator.dart';

/// Dinh dưỡng tuần này của CHÍNH người dùng, tính từ nhật ký bữa ăn
/// (`GET /cooking/logs?memberId=<me>`), so với mục tiêu calo của họ.
///
/// Trước đây cộng 1 khẩu phần mỗi món trong kế hoạch của cả nhà rồi so với
/// mục tiêu 1 người — số "dự kiến cả nhà" bị so với "mục tiêu 1 người" nên
/// gần như luôn vượt (báo cáo `reports/nutrition-data-sources.md`).
class NutritionStore extends GetLifeCycle {
  NutritionStore({
    required MealLogApi mealLogApi,
    required HealthApi healthApi,
    required String? Function() selfId,
    DateTime Function()? now,
  })  : _mealLogApi = mealLogApi,
        _healthApi = healthApi,
        _selfId = selfId,
        _now = now ?? DateTime.now;

  static const String profileTag = 'nutrition-profile';

  /// Max `size` của GET /cooking/logs — đủ cho 1 người trong 1 tuần.
  static const int weekPageSize = 100;

  final MealLogApi _mealLogApi;
  final HealthApi _healthApi;
  final String? Function() _selfId;
  final DateTime Function() _now;

  final Observable<List<MealLogEntry>?> _logs = Observable(null);
  final Observable<DateTime?> _weekStart = Observable(null);
  final Observable<String?> _memberId = Observable(null);
  final Observable<bool> _loading = Observable(false);
  final Observable<int?> _target = Observable(null);
  final Observable<bool> _targetLoaded = Observable(false);
  final Observable<ApiException?> _error = Observable(null);
  ReactionDisposer? _targetDisposer;

  int? get targetDailyCalories => _target.value;
  ApiException? get error => _error.value;

  late final Computed<ViewState<NutritionWeekSummary>> _state = Computed(() {
    final error = _error.value;
    if (error != null) return ErrorState(error);
    final logs = _logs.value;
    final weekStart = _weekStart.value;
    final memberId = _memberId.value;
    // Giữ số cũ trong lúc tải lại để không nháy skeleton mỗi lần vào tab.
    if (logs == null || weekStart == null || memberId == null) {
      return _loading.value || !_targetLoaded.value
          ? const LoadingState()
          : const EmptyState();
    }
    if (!_targetLoaded.value) return const LoadingState();
    final summary = computeWeeklyNutritionFromLogs(
      weekStart: weekStart,
      logs: logs,
      memberId: memberId,
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

  /// Profile: tải nhật ký tuần hiện tại của mình + target (§8.2).
  Future<void> loadCurrentWeek() async {
    if (_loading.value) return;
    final memberId = _selfId();
    if (memberId == null || memberId.isEmpty) return;
    final weekStart = mondayOf(_now());
    runInAction(() {
      _loading.value = true;
      _error.value = null;
    });
    try {
      final results = await Future.wait<Object?>(<Future<Object?>>[
        _mealLogApi.listLogs(
          from: weekStart,
          to: weekStart.add(const Duration(days: 6)),
          memberId: memberId,
          size: weekPageSize,
        ),
        refreshTarget(),
      ]);
      runInAction(() {
        _logs.value = results.first! as List<MealLogEntry>;
        _weekStart.value = weekStart;
        _memberId.value = memberId;
      });
    } catch (raw) {
      runInAction(() => _error.value = storeApiException(raw));
    } finally {
      runInAction(() => _loading.value = false);
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
    runInAction(() => _error.value = null);
    await loadCurrentWeek();
  }

  @override
  void onClose() {
    _targetDisposer?.call();
    _targetDisposer = null;
    super.onClose();
  }
}
