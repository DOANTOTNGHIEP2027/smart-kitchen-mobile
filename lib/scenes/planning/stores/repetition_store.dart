import 'package:mobx/mobx.dart';

import '../../../widgets/states/view_state.dart';
import '../../profile/stores/store_error.dart';
import '../data/repetition_api.dart';
import '../domain/repetition_summary.dart';

/// State cho `RepetitionSummaryScene` (flexible-meal-planning-screens.md §7.4).
class RepetitionStore {
  RepetitionStore(this._api);

  /// Enum BE — không gửi giá trị khác.
  static const List<int> allowedWindows = <int>[7, 14];

  final RepetitionApi _api;

  final Observable<ViewState<RepetitionSummary>> _summaryState =
      Observable<ViewState<RepetitionSummary>>(
          const LoadingState<RepetitionSummary>());
  final Observable<int> _windowDays = Observable<int>(14);
  int _loadSeq = 0;

  ViewState<RepetitionSummary> get summaryState => _summaryState.value;
  int get windowDays => _windowDays.value;

  /// `repeatedDishes = []` vẫn là SuccessState — UI hiện empty-state tích cực,
  /// không coi là lỗi.
  Future<void> load() async {
    final seq = ++_loadSeq;
    runInAction(
        () => _summaryState.value = const LoadingState<RepetitionSummary>());
    try {
      final summary = await _api.get(windowDays: _windowDays.value);
      if (seq != _loadSeq) return;
      runInAction(
          () => _summaryState.value = SuccessState<RepetitionSummary>(summary));
    } catch (e) {
      if (seq != _loadSeq) return;
      runInAction(() => _summaryState.value =
          ErrorState<RepetitionSummary>(storeApiException(e)));
    }
  }

  Future<void> setWindowDays(int days) async {
    if (!allowedWindows.contains(days) || days == _windowDays.value) return;
    runInAction(() => _windowDays.value = days);
    await load();
  }
}
