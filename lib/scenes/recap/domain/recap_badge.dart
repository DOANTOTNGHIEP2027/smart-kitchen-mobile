/// 5 mức badge per-member do AI sinh (weekly-insight-chain.md #85 §2.3).
///
/// `unknown` khi `raw == null` HOẶC là 1 string lạ không khớp 4 giá trị BE đã
/// biết — không throw, không coi 1 giá trị lạ là 1 trong 4 mức đã biết
/// (weekly-recap-screen.md Implementation Guard #6).
enum RecapBadge { onTrack, under, over, greatWeek, unknown }

extension RecapBadgeParsing on RecapBadge {
  static RecapBadge fromApi(String? raw) => switch (raw) {
        'on_track' => RecapBadge.onTrack,
        'under' => RecapBadge.under,
        'over' => RecapBadge.over,
        'great_week' => RecapBadge.greatWeek,
        _ => RecapBadge.unknown,
      };
}