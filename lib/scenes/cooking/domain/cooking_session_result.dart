import 'cooking_session.dart';
import 'ingredient_deduction.dart';

/// Shape dùng chung của response `POST /complete` và `GET /{id}` (FE-6 §5 —
/// `CompleteSessionData` của OAS cooking-session.yaml v1.0.0).
///
/// `deductions` luôn khác `null` — rỗng khi session chưa COMPLETED.
class CookingSessionResult {
  const CookingSessionResult({
    required this.session,
    required this.deductions,
  });

  final CookingSession session;
  final List<IngredientDeduction> deductions;
}
