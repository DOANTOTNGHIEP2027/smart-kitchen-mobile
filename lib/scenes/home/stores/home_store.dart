import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../widgets/states/view_state.dart';
import '../../mealplan/data/meal_plan_api.dart';
import '../../mealplan/domain/meal_plan_slot.dart';
import '../domain/upcoming_meal.dart';

part 'home_store.g.dart';

/// State tab Trang chủ: bữa sắp tới gần nhất trong thực đơn.
// ignore: library_private_types_in_public_api — mixin application chuẩn của MobX
class HomeStore = _HomeStore with _$HomeStore;

abstract class _HomeStore with Store {
  _HomeStore({
    required MealPlanApi mealPlanApi,
    DateTime Function()? clock,
  })  : _mealPlanApi = mealPlanApi,
        _clock = clock ?? DateTime.now;

  final MealPlanApi _mealPlanApi;
  final DateTime Function() _clock;

  int _loadSequence = 0;

  @observable
  ViewState<UpcomingMeal> upcoming = const LoadingState<UpcomingMeal>();

  @action
  Future<void> load() async {
    final sequence = ++_loadSequence;
    if (upcoming is! SuccessState<UpcomingMeal>) {
      upcoming = const LoadingState<UpcomingMeal>();
    }
    try {
      final meal = await _findUpcoming(_clock());
      if (sequence != _loadSequence) return;
      runInAction(() {
        upcoming = meal == null
            ? const EmptyState<UpcomingMeal>()
            : SuccessState<UpcomingMeal>(meal);
      });
    } on ApiException catch (e) {
      if (sequence != _loadSequence) return;
      runInAction(() => upcoming = ErrorState<UpcomingMeal>(e));
    }
  }

  /// Tuần hiện tại hết bữa (vd tối Chủ nhật) → thử tuần kế tiếp.
  Future<UpcomingMeal?> _findUpcoming(DateTime now) async {
    final current = await _readPlan(_mealPlanApi.getCurrent);
    final fromCurrent =
        current == null ? null : selectUpcomingMeal(current, now);
    if (fromCurrent != null) return fromCurrent;
    final today = DateTime(now.year, now.month, now.day);
    final nextMonday =
        today.add(Duration(days: DateTime.daysPerWeek - (today.weekday - 1)));
    final next = await _readPlan(() => _mealPlanApi.getWeek(nextMonday));
    return next == null ? null : selectUpcomingMeal(next, now);
  }

  Future<MealPlanDto?> _readPlan(Future<MealPlanDto> Function() read) async {
    try {
      return await read();
    } on BusinessException catch (e) {
      if (e.code == 'ERR_PLAN_NOT_FOUND') return null;
      rethrow;
    }
  }
}
