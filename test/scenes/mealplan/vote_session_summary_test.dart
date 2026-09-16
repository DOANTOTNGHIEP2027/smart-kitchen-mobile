import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/vote_session_summary.dart';

/// Test `VoteSessionSummary.mergeVoteResult`/`withTally` — CRITICAL-4:
/// PHẢI GIỮ NGUYÊN `suggestions` đã có sau khi merge tally mới. Dùng
/// `fromResultResponse` để merge sẽ tái tạo bug CRITICAL-4 do FE gây ra.
void main() {
  group('CRITICAL-4 — mergeVoteResult/withTally giữ suggestions gốc', () {
    test('mergeVoteResult KHÔNG rớt suggestions đã có', () {
      final session = VoteSessionSummary.fromOpenResponse(
        's1',
        'd1',
        <String, dynamic>{
          'sessionId': 'real-session-id',
          'deadlineAt': '2026-09-17T10:00:00Z',
          'suggestions': <Map<String, dynamic>>[
            <String, dynamic>{
              'recipeId': 'r1',
              'recipeName': 'Canh chua',
              'confidence': 0.8,
              'source': 'KB',
              'rankReason': 'Cá lóc còn',
              'missingIngredients': <dynamic>[],
              'allergenTags': <String>[],
              'allergenDerivation': 'INGREDIENT_RULE',
            },
            <String, dynamic>{
              'recipeId': 'r2',
              'recipeName': 'Bún bò',
              'confidence': 0.7,
              'source': 'KB',
              'rankReason': 'Bò mềm',
              'missingIngredients': <dynamic>[],
              'allergenTags': <String>[],
              'allergenDerivation': 'INGREDIENT_RULE',
            },
          ],
        },
      );

      expect(session.suggestions.length, 2);

      // Cast vote → server trả về raw {votes, totalMembers, myVote}
      // (KHÔNG có suggestions)
      final merged = session.mergeVoteResult(<String, dynamic>{
        'votes': <Map<String, dynamic>>[
          <String, dynamic>{
            'recipeId': 'r1',
            'recipeName': 'Canh chua',
            'count': 2,
          },
        ],
        'totalMembers': 4,
        'myVote': 'r1',
      });

      // CRITICAL-4: suggestions phải VẪN còn 2 phần tử
      expect(merged.suggestions.length, 2,
          reason: 'mergeVoteResult phải GIỮ NGUYÊN suggestions gốc — '
              'rớt về 0/1 là bug tái tạo CRITICAL-4 do FE gây ra.');
      expect(merged.suggestions.first.recipeId, 'r1');
      expect(merged.suggestions.last.recipeId, 'r2');
      expect(merged.tally.length, 1);
      expect(merged.tally.first.count, 2);
      expect(merged.myVote, 'r1');
      expect(merged.totalMembers, 4);
      // Identity KHÔNG đổi — sessionId luôn đáng tin sau khi đã có
      expect(merged.sessionId, 'real-session-id');
      expect(merged.dishId, 'd1');
      expect(merged.suggestionsSourceDegraded, isFalse);
    });

    test('withTally (WS member_voted) giữ myVote hiện tại', () {
      final session = VoteSessionSummary(
        sessionId: 's-real',
        slotId: 's1',
        dishId: 'd1',
        status: VoteSessionUiStatus.open,
        suggestions: const <MealSuggestion>[
          MealSuggestion(recipeId: 'r1', mealName: 'M'),
        ],
        tally: const <VoteTallyItem>[],
        totalMembers: 4,
        myVote: 'r1', // caller đã vote
      );

      // WS member_voted tới — payload {tally, totalMembers} (KHÔNG myVote)
      final afterEvent = session.withTally(<String, dynamic>{
        'tally': <Map<String, dynamic>>[
          <String, dynamic>{
            'recipeId': 'r1',
            'recipeName': 'M',
            'count': 1,
          },
        ],
        'totalMembers': 4,
      });

      // CRITICAL: WS event của member khác → giữ myVote của caller
      expect(afterEvent.myVote, 'r1',
          reason: 'member_voted phản ánh vote member khác, không phải '
              'thiết bị này — myVote hiện tại phải giữ nguyên');
      expect(afterEvent.tally.length, 1);
      expect(afterEvent.totalMembers, 4);
      expect(afterEvent.suggestions.length, 1);
    });
  });

  group('fromResultResponse — degraded join', () {
    test('suggestionsSourceDegraded = true khi dựng từ result', () {
      final session = VoteSessionSummary.fromResultResponse(
        VoteSessionSummary.unknownSessionId,
        'slot-1',
        'dish-1',
        <String, dynamic>{
          'votes': <Map<String, dynamic>>[
            <String, dynamic>{
              'recipeId': 'r1',
              'recipeName': 'A',
              'count': 1,
            },
          ],
          'totalMembers': 3,
          'myVote': null,
        },
      );

      expect(session.suggestionsSourceDegraded, isTrue);
      expect(session.sessionId, VoteSessionSummary.unknownSessionId);
      expect(session.dishId, 'dish-1');
      expect(session.suggestions.length, 1, // chỉ có phiếu = 1 món
          reason: 'degraded: chỉ món đã có vote mới vào suggestions');
    });
  });
}
