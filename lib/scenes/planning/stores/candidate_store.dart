import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../widgets/states/view_state.dart';
import '../../mealplan/domain/vote_session_summary.dart';
import '../../profile/stores/form_status.dart';
import '../../profile/stores/store_error.dart';
import '../data/candidate_api.dart';
import '../domain/meal_plan_candidate.dart';

/// Mở vote session cho đúng 1 món = sinh gợi ý AI (`POST .../vote/open`).
typedef OpenCandidateSession = Future<VoteSessionSummary> Function();

/// State cho `CandidateInsightScene` (flexible-meal-planning-screens.md §7.3,
/// chỉnh theo BE thật — OD-08). MobX thủ công.
///
/// BE trả ứng viên của CẢ TUẦN, gắn theo `sessionId`. Có [sessionId] (mở từ
/// thẻ món, session đã biết id thật) → chỉ hiện nhóm đó; không có → hiện mọi
/// nhóm của tuần.
class CandidateStore {
  CandidateStore(
    this._api,
    this.mealPlanId, {
    String? sessionId,
    OpenCandidateSession? openSession,
    bool dishHasNoSession = false,
  })  : _openSession = openSession,
        _sessionId = Observable<String?>(_realSessionId(sessionId)),
        _dishHasNoSession = dishHasNoSession;

  final CandidateApi _api;
  final String mealPlanId;
  final OpenCandidateSession? _openSession;

  final Observable<String?> _sessionId;

  /// Món chưa từng mở phiên → chắc chắn chưa có ứng viên; KHÔNG hiện ứng viên
  /// của món khác trong tuần.
  bool _dishHasNoSession;
  final Observable<ViewState<List<CandidateGroup>>> _groupsState =
      Observable<ViewState<List<CandidateGroup>>>(
          const LoadingState<List<CandidateGroup>>());
  final Observable<FormStatus> _generateStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _generateError =
      Observable<ApiException?>(null);
  int _loadSeq = 0;

  ViewState<List<CandidateGroup>> get groupsState => _groupsState.value;
  String? get sessionId => _sessionId.value;
  FormStatus get generateStatus => _generateStatus.value;
  ApiException? get generateError => _generateError.value;
  bool get isGenerating => _generateStatus.value == FormStatus.submitting;

  /// Chỉ sinh được khi màn mở từ 1 món cụ thể.
  bool get canGenerate => _openSession != null;

  Future<void> load() async {
    final seq = ++_loadSeq;
    if (_dishHasNoSession && _sessionId.value == null) {
      runInAction(() =>
          _groupsState.value = const EmptyState<List<CandidateGroup>>());
      return;
    }
    runInAction(() =>
        _groupsState.value = const LoadingState<List<CandidateGroup>>());
    try {
      final all = await _api.list(mealPlanId);
      if (seq != _loadSeq) return;
      final groups = _group(all, _sessionId.value);
      runInAction(() => _groupsState.value = groups.isEmpty
          ? const EmptyState<List<CandidateGroup>>()
          : SuccessState<List<CandidateGroup>>(groups));
    } catch (e) {
      if (seq != _loadSeq) return;
      runInAction(() => _groupsState.value =
          ErrorState<List<CandidateGroup>>(storeApiException(e)));
    }
  }

  /// Sinh gợi ý cho món đang xem rồi tải lại danh sách. 409 `ERR_PLAN_002`
  /// (đã có phiên mở) được `MealPlanStore.openVoteSession` xử lý sẵn.
  ///
  /// Đã biết phiên thật → không sinh: `vote/open` trả 409 rồi join về sentinel,
  /// làm mất bộ lọc phiên và lẫn ứng viên của món khác.
  Future<bool> generate() async {
    final open = _openSession;
    if (open == null || isGenerating || _sessionId.value != null) return false;
    runInAction(() {
      _generateStatus.value = FormStatus.submitting;
      _generateError.value = null;
    });
    try {
      final session = await open();
      _dishHasNoSession = false;
      runInAction(() {
        _sessionId.value = _realSessionId(session.sessionId);
        _generateStatus.value = FormStatus.success;
      });
      await load();
      return true;
    } catch (e) {
      runInAction(() {
        _generateError.value = storeApiException(e);
        _generateStatus.value = FormStatus.failure;
      });
      return false;
    }
  }

  void clearGenerateError() => runInAction(() {
        if (isGenerating) return;
        _generateStatus.value = FormStatus.idle;
        _generateError.value = null;
      });

  /// Nhóm theo `sessionId`, phiên mới đánh giá gần nhất lên trước; trong
  /// nhóm sắp theo §8.3.
  static List<CandidateGroup> _group(
      List<MealPlanCandidate> all, String? sessionId) {
    final bySession = <String, List<MealPlanCandidate>>{};
    for (final c in all) {
      if (sessionId != null && c.sessionId != sessionId) continue;
      bySession.putIfAbsent(c.sessionId, () => <MealPlanCandidate>[]).add(c);
    }
    final groups = <CandidateGroup>[
      for (final entry in bySession.entries)
        CandidateGroup(
          sessionId: entry.key,
          candidates: CandidateGroup.sortForDisplay(entry.value),
        ),
    ];
    groups.sort((a, b) {
      final ta = a.evaluatedAt, tb = b.evaluatedAt;
      if (ta == null && tb == null) return 0;
      if (ta == null || tb == null) return ta == null ? 1 : -1;
      return tb.compareTo(ta);
    });
    return groups;
  }

  /// Sentinel `__unknown__` (session join qua `GET vote/result`) không phải id
  /// thật — không lọc theo nó.
  static String? _realSessionId(String? id) =>
      id == null || id == VoteSessionSummary.unknownSessionId ? null : id;
}
