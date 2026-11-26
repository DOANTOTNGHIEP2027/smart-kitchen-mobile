/// Tuổi tròn tại [now] — trừ 1 nếu năm nay chưa tới sinh nhật.
///
/// Chuyển nguyên trạng từ `dependent_list_screen.dart` (#125 §16.1). Kết quả
/// âm = ngày sinh ở tương lai (dữ liệu BE sai) — UI không hiện tuổi âm (OD-18).
int ageOn(DateTime birth, DateTime now) {
  final hadBirthday = now.month > birth.month ||
      (now.month == birth.month && now.day >= birth.day);
  return now.year - birth.year - (hadBirthday ? 0 : 1);
}
