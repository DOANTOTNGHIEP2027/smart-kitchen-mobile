/// Buổi trong ngày để chọn câu chào ở trang chủ.
enum GreetingPeriod { morning, noon, afternoon, evening }

/// Hàm thuần: giờ (0–23) → buổi. Sáng 5–10, trưa 11–12, chiều 13–17,
/// còn lại là tối (kể cả 0–4 giờ khuya).
GreetingPeriod greetingFor(int hour) {
  if (hour >= 5 && hour <= 10) return GreetingPeriod.morning;
  if (hour >= 11 && hour <= 12) return GreetingPeriod.noon;
  if (hour >= 13 && hour <= 17) return GreetingPeriod.afternoon;
  return GreetingPeriod.evening;
}
