/// Stat phụ "7 ngày gần nhất" từ `GET /cooking/nutrition/weekly` —
/// CỬA SỔ TRƯỢT `[today-6, tomorrow)` (nutrition-trend-history.md §5.2).
///
/// KHÁC khái niệm "tuần lịch" (Monday) ở `WeeklyAdherencePoint` — không trộn
/// 2 khái niệm "tuần" này trong cùng 1 phép tính.
class WeekQuickStat {
  const WeekQuickStat({this.avgCaloriesKcal, this.loggedCount});

  /// `null` nếu self chưa log gì trong 7 ngày qua (mảng BE bỏ hẳn member đó).
  final double? avgCaloriesKcal;
  final int? loggedCount;
}