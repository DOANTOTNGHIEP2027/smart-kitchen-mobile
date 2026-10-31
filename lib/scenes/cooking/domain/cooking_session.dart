/// Trạng thái cooking session (FE-6 §5, #76).
///
/// Wire format ghép với BE:
/// - `IN_PROGRESS` — session đang mở, tiến độ bước được lưu trên thiết bị.
/// - `COMPLETED` — complete() đã chạy, inventory đã trừ.
/// - `ABANDONED` — abandon() đã chạy, inventory KHÔNG bị đụng.
enum CookingSessionStatusWire { inProgress, completed, abandoned }

extension CookingSessionStatusWireX on CookingSessionStatusWire {
  String get wire {
    switch (this) {
      case CookingSessionStatusWire.inProgress:
        return 'IN_PROGRESS';
      case CookingSessionStatusWire.completed:
        return 'COMPLETED';
      case CookingSessionStatusWire.abandoned:
        return 'ABANDONED';
    }
  }

  static CookingSessionStatusWire fromWire(String raw) {
    switch (raw) {
      case 'IN_PROGRESS':
        return CookingSessionStatusWire.inProgress;
      case 'COMPLETED':
        return CookingSessionStatusWire.completed;
      case 'ABANDONED':
        return CookingSessionStatusWire.abandoned;
      default:
        return CookingSessionStatusWire.inProgress;
    }
  }
}

/// Một session #76.
///
/// Không expose `ingredientsSnapshot` (JSONB rời) — màn hình nấu ăn chỉ cần
/// `recipeName` (đã snapshot lúc start, không re-fetch) và `totalSteps`.
/// `ingredientsSnapshot` chỉ cần khi hiển thị pre-flight check trước nấu,
/// ngoài phạm vi issue #81.
class CookingSession {
  const CookingSession({
    required this.id,
    required this.householdId,
    required this.recipeId,
    required this.recipeName,
    required this.startedBy,
    required this.status,
    required this.totalSteps,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String householdId;
  final String recipeId;
  final String recipeName;
  final String startedBy;
  final CookingSessionStatusWire status;
  final int totalSteps;
  final DateTime startedAt;
  final DateTime? endedAt;

  CookingSession copyWith({
    CookingSessionStatusWire? status,
    DateTime? endedAt,
  }) =>
      CookingSession(
        id: id,
        householdId: householdId,
        recipeId: recipeId,
        recipeName: recipeName,
        startedBy: startedBy,
        status: status ?? this.status,
        totalSteps: totalSteps,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
      );
}
