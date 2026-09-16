import 'meal_suggestion.dart';

/// 1 tally item (số phiếu của 1 recipe) trong 1 vote session (FE-7 §5.2).
class VoteTallyItem {
  const VoteTallyItem({
    required this.recipeId,
    required this.recipeName,
    required this.count,
  });

  final String recipeId;
  final String recipeName;
  final int count;
}

enum VoteSessionUiStatus { open, closed }

/// Summary 1 vote session (FE-7 §5.2).
///
/// **Quan trọng CRITICAL-4 (review-report):** `mergeVoteResult`/`withTally`
/// chỉ đổi `tally`/`totalMembers`/`myVote`, GIỮ NGUYÊN `suggestions` gốc.
/// Caller không bao giờ được dùng `fromResultResponse` để merge vào session đã
/// có sẵn suggestions đầy đủ — sẽ tái tạo lại bug CRITICAL-4 do FE gây ra.
class VoteSessionSummary {
  const VoteSessionSummary({
    required this.sessionId,
    required this.slotId,
    required this.dishId,
    required this.status,
    this.deadlineAt,
    required this.suggestions,
    required this.tally,
    this.totalMembers = 0,
    this.myVote,
    this.winnerRecipeId,
    this.suggestionsSourceDegraded = false,
  });

  final String sessionId;
  final String slotId;
  final String dishId;
  final VoteSessionUiStatus status;
  final DateTime? deadlineAt;
  final List<MealSuggestion> suggestions;
  final List<VoteTallyItem> tally;
  final int totalMembers;
  final String? myVote;
  final String? winnerRecipeId;

  /// `true` CHỈ khi `suggestions` dựng lại từ `votes[]` (nhánh
  /// [fromResultResponse], degraded join fallback) — nghĩa là suggestion nào
  /// chưa có phiếu sẽ KHÔNG có mặt. UI PHẢI phân biệt với "session mở nhưng
  /// thật sự không có suggestion nào".
  final bool suggestionsSourceDegraded;

  /// Sentinel cho `sessionId` khi `GET vote/result` không trả về field này
  /// (BE #43 thiếu `session_id` ở response). Không phải 1 sessionId thật —
  /// sau amendment #44 lookup đều qua `dishId` thật nên sentinel không chặn
  /// WS member_voted nữa.
  static const String unknownSessionId = '__unknown__';

  /// Dựng từ `POST vote/open` 201 HOẶC WS `session_opened` — nguồn ĐẦY ĐỦ NHẤT
  /// hiện có (suggestions giàu field sau B1). `slotId`/`dishId` truyền từ
  /// ngoài vì REST 201 không có field đó (chỉ WS `session_opened` có).
  factory VoteSessionSummary.fromOpenResponse(
    String slotId,
    String dishId,
    Map<String, dynamic> json,
  ) {
    final suggestionsJson = json['suggestions'] as List<dynamic>? ??
        const <dynamic>[];
    return VoteSessionSummary(
      sessionId: json['sessionId'] as String,
      slotId: slotId,
      dishId: dishId,
      status: VoteSessionUiStatus.open,
      deadlineAt: json['deadlineAt'] == null
          ? null
          : DateTime.parse(json['deadlineAt'] as String),
      suggestions: suggestionsJson
          .map((Object? s) =>
              MealSuggestion.fromVoteOpen(s as Map<String, dynamic>))
          .toList(growable: false),
      tally: const <VoteTallyItem>[],
    );
  }

  /// Dựng từ `GET vote/result` — degraded, chỉ dùng khi JOIN 1 session đã có
  /// (fallback 409 của [VoteApi.open]). `sessionId` từ ngoài vì response không
  /// có field đó (sentinel nếu không biết). `dishId` luôn có từ tham số path.
  /// `suggestions[]` dựng lại từ `votes[]` (degraded — suggestion nào chưa có
  /// phiếu sẽ KHÔNG có mặt).
  factory VoteSessionSummary.fromResultResponse(
    String sessionId,
    String slotId,
    String dishId,
    Map<String, dynamic> json,
  ) {
    final votesJson =
        json['votes'] as List<dynamic>? ?? const <dynamic>[];
    return VoteSessionSummary(
      sessionId: sessionId,
      slotId: slotId,
      dishId: dishId,
      status: VoteSessionUiStatus.open,
      suggestions: votesJson
          .map((Object? v) => MealSuggestion.fromResultVote(
                recipeId: (v as Map<String, dynamic>)['recipeId'] as String,
                mealName: (v)['recipeName'] as String,
              ))
          .toList(growable: false),
      tally: votesJson
          .map((Object? v) => VoteTallyItem(
                recipeId: (v as Map<String, dynamic>)['recipeId'] as String,
                recipeName: (v)['recipeName'] as String,
                count: (v)['count'] as int,
              ))
          .toList(growable: false),
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      myVote: json['myVote'] as String?,
      suggestionsSourceDegraded: true,
    );
  }

  /// Merge `{votes, total_members, my_vote}` mới vào session ĐÃ CÓ — dùng bởi
  /// `MealPlanStore.applyVoteResultRaw` (sau `cast()`/`refreshTally()`).
  /// GIỮ NGUYÊN `suggestions`/`sessionId`/`dishId`/`deadlineAt`/
  /// `winnerRecipeId`/`suggestionsSourceDegraded`.
  VoteSessionSummary mergeVoteResult(Map<String, dynamic> json) {
    final votesJson =
        json['votes'] as List<dynamic>? ?? const <dynamic>[];
    return VoteSessionSummary(
      sessionId: sessionId,
      slotId: slotId,
      dishId: dishId,
      status: status,
      deadlineAt: deadlineAt,
      suggestions: suggestions,
      tally: votesJson
          .map((Object? v) => VoteTallyItem(
                recipeId: (v as Map<String, dynamic>)['recipeId'] as String,
                recipeName: (v)['recipeName'] as String,
                count: (v)['count'] as int,
              ))
          .toList(growable: false),
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      myVote: json['myVote'] as String?,
      winnerRecipeId: winnerRecipeId,
      suggestionsSourceDegraded: suggestionsSourceDegraded,
    );
  }

  /// Merge tally realtime từ WS `member_voted`. Shape KHÁC `mergeVoteResult`
  /// (key `tally` thay `votes`, không có `my_vote`) — GIỮ `myVote` hiện tại.
  VoteSessionSummary withTally(Map<String, dynamic> raw) {
    final tallyJson =
        raw['tally'] as List<dynamic>? ?? const <dynamic>[];
    return VoteSessionSummary(
      sessionId: sessionId,
      slotId: slotId,
      dishId: dishId,
      status: status,
      deadlineAt: deadlineAt,
      suggestions: suggestions,
      tally: tallyJson
          .map((Object? t) => VoteTallyItem(
                recipeId: (t as Map<String, dynamic>)['recipeId'] as String,
                recipeName: (t)['recipeName'] as String,
                count: (t)['count'] as int,
              ))
          .toList(growable: false),
      totalMembers: (raw['totalMembers'] as num?)?.toInt() ?? totalMembers,
      myVote: myVote,
      winnerRecipeId: winnerRecipeId,
      suggestionsSourceDegraded: suggestionsSourceDegraded,
    );
  }
}
